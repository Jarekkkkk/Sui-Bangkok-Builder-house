#[test_only]
#[allow(unused)]
module sui_sign::sui_sign_tests{
    use sui::test_scenario::{Self as test, Scenario, next_tx, ctx};
    use sui::test_scenario;
    use sui::sui::SUI;
    use sui::coin::{mint_for_testing as mint, burn_for_testing as burn};

    use sui_sign::sui_sign::{Self, Document};

    use walrus::blob;

    const ENotImplemented: u64 = 0;
    
    const GAS_REQUIRED_AMT: u64 = 100_000;

    const SENDER: address = @0xA;
    const RECEIPIENT: address = @0xB;

    #[test]
    fun test_wallet_address() {
        let mut scenario = test::begin(SENDER);
        let s = &mut scenario;

        // prepare sig request
        next_tx(s, SENDER);{
            let gas = mint<SUI>(GAS_REQUIRED_AMT, ctx(s));

            let blob = blob::new_blob_for_testing(1, ctx(s));
            let mut doc = sui_sign::init_requested_signature(blob, gas, ctx(s));
            // add verification
            doc.add_wallet_address_validation(RECEIPIENT);

            transfer::public_transfer(doc, RECEIPIENT);
        };

        next_tx(s, RECEIPIENT);{
            let mut doc = test::take_from_sender<Document>(s);
            
            let gas = doc.sponsored_gas(ctx(s));
            assert!(burn(gas) == GAS_REQUIRED_AMT, 404);

            doc.verify_wallet_address(ctx(s));
            assert!(doc.is_verified(), 404);

            transfer::public_transfer(doc, SENDER);
        };

        scenario.end();
    }

}
