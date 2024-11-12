module sui_sign::sui_sign{
    use std::string::{Self, String};

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


    public struct Document has key, store{
        id: UID,
        requester: address,
        verifications: VecMap<String, bool>,
        expected_proofs: Bag,
        gas: Balance<SUI>,
        signer: Option<address>
    }

    public fun sponsored_gas(doc: &mut Document, ctx: &mut TxContext): Coin<SUI>{
        coin::from_balance(doc.gas.withdraw_all(), ctx)
    }

    public fun init_requested_signature(
        gas: Coin<SUI>,
        ctx: &mut TxContext
    ):Document {
        Document{
            id: object::new(ctx),
            requester: ctx.sender(),
            verifications: vec_map::empty(),
            expected_proofs: bag::new(ctx),
            gas: gas.into_balance(),
            signer: option::none()
        }
    }

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

        let expected_address = doc.expected_proofs[key];

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
        let expected_name = doc.expected_proofs[key];

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
        
        let manager: &ReclaimManager = &doc.expected_proofs[key];
        let proof = create_proof(parameters, context, identifier, owner, epoch, timestamp, signature);
        let _witness = client::verify_proof(manager, &proof, ctx);

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
