module sui_sign::sui_sign{
    use std::string::{Self, String};

    use sui::table::{Self, Table};
    use sui::vec_map::{Self, VecMap};
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::balance::Balance;
    use sui::bag::{Self, Bag};

    // - walrus
    use walrus::blob::Blob;
    // - suins
    use suins::suins_registration::SuinsRegistration;
    // - reclaim
    use sui_sign::reclaim::{Self, ReclaimManager, Proof};
    use sui_sign::client;

    // keys
    const ADDRESS_KEY:vector<u8> = b"address";
    const SUI_NS_KEY:vector<u8> = b"suins";
    const RECLAIM_KEY:vector<u8> = b"relciam";

    // error-code
    const ERR_NON_EXIST_VERIFICATION: u64 = 101;
    const ERR_FAILED_VALIDATION: u64 = 102;
    const ERR_NOT_FULLY_VERIFIED: u64 = 103;

    public struct DocumentInfo has store{
        requester: address,
        signers: VecMap<address, vector<u8>>,
    }
    public fun requester(info: &DocumentInfo): address{
        info.requester
    }
    public fun signers(info: &DocumentInfo): VecMap<address, vector<u8>>{
        info.signers
    }

    /// Shared object to store all signed documents
    public struct ProofOfSignature has key{
        id: UID,
        // Blob id to info
        signatures: Table<u256, DocumentInfo>
    }

    public fun signature_of_cid(
        self: &ProofOfSignature,
        cid: u256
    ):&DocumentInfo{
        &self.signatures[cid]
    }

    public struct SignatureRequest has key{
        id: UID,
        blob: Blob
    }

    public struct Document has key, store{
        id: UID,
        requester: address,
        blob_id: u256,
        verifications: VecMap<String, bool>,
        expected_proofs: Bag,
        gas: Balance<SUI>
    }

    fun init(ctx: &mut TxContext){
        transfer::share_object(
            ProofOfSignature{
                id: object::new(ctx),
                signatures: table::new(ctx)
            }
        );
    }
    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext){
        init(ctx);
    }

    public fun sponsored_gas(doc: &mut Document, ctx: &mut TxContext): Coin<SUI>{
        coin::from_balance(doc.gas.withdraw_all(), ctx)
    }

    public fun init_requested_signature(
        self: &mut ProofOfSignature,
        blob: Blob,
        gas: Coin<SUI>,
        ctx: &mut TxContext
    ):Document {
        let blob_id = blob.blob_id();
        let req = SignatureRequest{
            id: object::new(ctx),
            blob
        };
        transfer::transfer(req, ctx.sender());

        self.signatures.add(
            blob_id, 
            DocumentInfo{
                requester: ctx.sender(),
                signers: vec_map::empty()
            }
        );

        Document{
            id: object::new(ctx),
            requester: ctx.sender(),
            blob_id,
            verifications: vec_map::empty(),
            expected_proofs: bag::new(ctx),
            gas: gas.into_balance(),
        }
    }

    public fun remove_signature(
        self: &mut ProofOfSignature,
        request: SignatureRequest,
        ctx: &TxContext
    ){
        let SignatureRequest{
            id,
            blob
        } = request;

        object::delete(id);

        transfer::public_transfer(blob, ctx.sender());
    }

    public fun is_verified(doc: &Document):bool{
        let keys = doc.verifications.keys();
        let (mut i, len) = (0, keys.length());

        let mut verified = true;
        while(i < len){
            let key = keys[i];
            let valid = doc.verifications[&key];

            verified = valid && verified;

            i = i + 1;
        };

        verified
    }

    #[allow(lint(self_transfer))]
    public fun sign(
        self: &mut ProofOfSignature,
        doc: Document,
        signature: vector<u8>,
        ctx: &mut TxContext
    ){
        assert!(doc.is_verified(), ERR_NOT_FULLY_VERIFIED);

        let Document{
            id,
            requester: _,
            blob_id,
            verifications: _,
            expected_proofs,
            gas,
        } = doc;

        object::delete(id);
        expected_proofs.destroy_empty();

        let info = &mut self.signatures[blob_id];
        info.signers.insert(ctx.sender(), signature);

        transfer::public_transfer(coin::from_balance(gas, ctx), info.requester);
    }

    // ===== Verification =====

    // -SUI_NS
    public fun add_wallet_address_validation(
        doc: &mut Document,
        verified_address: address
    ){
        let key = string::utf8(ADDRESS_KEY);
        doc.verifications.insert(key, false);
        doc.expected_proofs.add(key, verified_address);
    }

    public fun verify_wallet_address(
        doc: &mut Document,
        ctx: &TxContext
    ){
        let key = string::utf8(ADDRESS_KEY);
        assert!(doc.verifications.contains(&key), ERR_NON_EXIST_VERIFICATION);

        let expected_address = doc.expected_proofs.remove(key);

        assert!(ctx.sender() == expected_address, ERR_FAILED_VALIDATION);

        *&mut doc.verifications[&key] = true;
    }

    // -SUI_NS
    public fun add_suins_validation(
        doc: &mut Document,
        verified_name: String
    ){
        let key = string::utf8(SUI_NS_KEY);
        doc.verifications.insert(key, false);
        doc.expected_proofs.add(key, verified_name);
    }

    public fun verify_suins(
        doc: &mut Document,
        name_service: &SuinsRegistration
    ){
        let key = string::utf8(SUI_NS_KEY);
        assert!(doc.verifications.contains(&key), ERR_NON_EXIST_VERIFICATION);

        let claimer_name = name_service.domain_name();
        let expected_name = doc.expected_proofs.remove(key);

        assert!(claimer_name == expected_name, ERR_FAILED_VALIDATION);

        *&mut doc.verifications[&key] = true;
    }

    // -Reclaim
    public fun add_reclaim_validation(
        doc: &mut Document,
        epoch_duration: u32,
        witnesses: vector<vector<u8>>,
        ctx: &mut TxContext
    ){
        let key = string::utf8(RECLAIM_KEY);
        doc.verifications.insert(key, false);

        let mut manager = reclaim::create_reclaim_manager(epoch_duration, ctx);
        let requisite_witnesses_for_claim_create = 1_u128;

        client::add_new_epoch(&mut manager, witnesses, requisite_witnesses_for_claim_create, ctx);

        doc.expected_proofs.add(key, manager);
    }

    public fun verify_reclaim(
        doc: &mut Document,
        parameters: String,
        context: String,
        identifier: String,
        owner: String,
        epoch: String,
        timestamp: String,
        signature: vector<u8>,
        ctx: &mut TxContext
    ){
        let key = string::utf8(RECLAIM_KEY);
        assert!(doc.verifications.contains(&key), ERR_NON_EXIST_VERIFICATION);
        
        let manager: ReclaimManager = doc.expected_proofs.remove(key);
        let proof = create_proof(parameters, context, identifier, owner, epoch, timestamp, signature);
        let _witness = client::verify_proof(&manager, &proof, ctx);

        manager.drop_reclaim_manager();

        *&mut doc.verifications[&key] = true;
    }

    fun create_proof(
        parameters: String,
        context: String,
        identifier: String,
        owner: String,
        epoch: String,
        timestamp: String,
        signature: vector<u8>,
    ):Proof {
        let claim_info = reclaim::create_claim_info(
            b"http".to_string(),
            parameters,
            context
        );
 
        let complete_claim_data = reclaim::create_claim_data(
            identifier,
            owner,
            epoch,
            timestamp,
        );
 
        let mut signatures = vector<vector<u8>>[];
        signatures.push_back(signature);
 
        let signed_claim = reclaim::create_signed_claim(
            complete_claim_data,
            signatures
        );
 
        reclaim::create_proof(claim_info, signed_claim)
    }
}
