#[test_only]
module sui_sign::sui_sign_tests;
// uncomment this line to import the module
// use sui_sign::sui_sign;

const ENotImplemented: u64 = 0;

#[test]
fun test_sui_sign() {
    // pass
}

#[test, expected_failure(abort_code = ::sui_sign::sui_sign_tests::ENotImplemented)]
fun test_sui_sign_fail() {
    abort ENotImplemented
}
