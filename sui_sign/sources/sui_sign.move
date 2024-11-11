module sui_sign::sui_sign{
    use std::string::{Self, String};

    use sui::vec_set::{Self, VecSet};
    use sui::vec_map::{Self, VecMap};
    use sui::sui::SUI;
    use sui::coin::Coin;
    use sui::bag::{Self, Bag};

    // - walrus
    use walrus::blob::Blob;
    // - suins
    use suins::suins_registration::{Self, SuinsRegistration};

    // keys
    const SUI_NS_KEY:vector<u8> = b"suins";

    // error-code
    const ERR_NON_EXIST_VERIFICATION: u64 = 101;
    const ERR_FAILED_VALIDATION: u64 = 102;

    public struct Admin has key{
        id: UID,
        supported_verifications: VecSet<String>
    }

    public struct AdminKey has key, store{ id: UID }

    public struct Document has key {
        id: UID,
        requester: address,
        verifications: VecMap<String, bool>,
        expected_proofs: Bag,
        gas: Coin<SUI>
    }

    fun init(ctx: &mut TxContext){
        transfer::transfer(
            AdminKey{ id: object::new(ctx) },
            ctx.sender()
        );
    }

    public fun init_requested_signature(
        recipient: address,
        gas: Coin<SUI>,
        ctx: &mut TxContext
    ):Document {
        Document{
            id: object::new(ctx),
            requester: ctx.sender(),
            verifications: vec_map::empty(),
            expected_proofs: bag::new(ctx),
            gas
        }
    }

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
        let mut key = string::utf8(SUI_NS_KEY);
        assert!(doc.verifications.contains(&key), ERR_NON_EXIST_VERIFICATION);

        let claimer_name = name_service.domain_name();
        let expected_name:String = doc.expected_proofs.remove(key);

        assert!(claimer_name == expected_name, ERR_FAILED_VALIDATION);

        *&mut doc.verifications[&mut key] = true;
    }
}
