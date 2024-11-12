#[test_only]
#[allow(unused)]
module sui_sign::sui_sign_tests{
    use sui::test_scenario::{Self as test, Scenario, next_tx, ctx};
    use sui::test_scenario;
    use sui::sui::SUI;
    use sui::coin::{mint_for_testing as mint};

    use sui_sign::sui_sign;

    const ENotImplemented: u64 = 0;
    
    const GAS_REQUIRED_AMT: u64 = 100_000;

    const SENDER: address = @0xA;
    const RECEIPIENT: address = @0xB;

    #[test]
    fun test_wallet_address() {
        let mut scenario = test::begin(SENDER);
        let s = &mut scenario;

        next_tx(s, SENDER);{
            let gas = mint<SUI>(GAS_REQUIRED_AMT, ctx(s));
            let mut doc = sui_sign::init_requested_signature(gas, ctx(s));
            doc.add_wallet_address_validation(RECEIPIENT);

            transfer::public_transfer(doc, RECEIPIENT);
        };

        scenario.end();
    }

}
