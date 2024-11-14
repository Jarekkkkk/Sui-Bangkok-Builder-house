#[test_only]
#[allow(unused)]
module sui_sign::sui_sign_tests{
    use sui::test_scenario::{Self as test, Scenario, next_tx, ctx};
    use sui::test_scenario;
    use sui::sui::SUI;
    use sui::coin::{mint_for_testing as mint, burn_for_testing as burn};
    use sui::vec_map;

    use sui_sign::sui_sign::{Self, Document, ProofOfSignature};

    use walrus::blob;

    const ENotImplemented: u64 = 0;
    
    const GAS_REQUIRED_AMT: u64 = 100_000;

    const SENDER: address = @0xA;
    const RECEIPIENT: address = @0xB;

    const MOCK_CID: u256 = 1;
    const EPOCH_DURATION_IN_SECOND: u32 = 1_000_000_u32;

    #[test]
    fun test_wallet_address() {
        let mut scenario = test::begin(SENDER);
        let s = &mut scenario;

        next_tx(s, SENDER);{
            sui_sign::init_for_testing(ctx(s));
        };

        // prepare sig request
        next_tx(s, SENDER);{
            let mut pos = test::take_shared<ProofOfSignature>(s);
            let gas = mint<SUI>(GAS_REQUIRED_AMT, ctx(s));

            let blob = blob::new_blob_for_testing(MOCK_CID, ctx(s));
            let mut doc = sui_sign::init_requested_signature(&mut pos, blob, gas, ctx(s));
            // add verification
            doc.add_wallet_address_validation(RECEIPIENT);

            transfer::public_transfer(doc, RECEIPIENT);

            test::return_shared(pos);
        };

        next_tx(s, RECEIPIENT);{
            let mut pos = test::take_shared<ProofOfSignature>(s);
            let mut doc = test::take_from_sender<Document>(s);
            
            let gas = doc.sponsored_gas(ctx(s));
            assert!(burn(gas) == GAS_REQUIRED_AMT, 404);

            doc.verify_wallet_address(ctx(s));
            let signature = b"BQNMMTk4MzAxMzg0NzY2ODMxNTI4MDQxODU5OTkyNTIzNzQwODE1NDM4Njg5MDc2ODA1ODg1NDg3Mjc1ODIxNzY3Njk1ODEyMTU3MTEzN00xMDU4ODY5NDA2Njc0NTczODQzOTQwNjg4NTUxMzY0MDIwMTA0ODU0NDk5OTIzMDYxMzk3MTYyMTMwNjQ4MTQ4MDMzNTAxNTIzNTk4MQExAwJNMTYxODEzMTUyODM4ODI4MTQ5NTY1NTU4NTk3OTk2NDMyNjc1Mzc2MTM0NzMxNDczMDQzNzMyMzM3MzMxNzUyMzYwODQ3MDI2MTg1OTFMNDAwMDY5MTUxMjEyNTg4MDQ3MjE2MTQzODg4NTczODQ1MjI1MjQyNDk4MjgxODMxNTIzOTUyMjAxNTUyMTg0NjkzMTE5OTM4MDA0MAJNMTQzMjY4NTMxMDE0NDAxMTA3MzM3NzU4NTQzMDQ1MzQ0ODE1NTI4Njc4OTM2MjI2ODAxNzIyMzY3MjkyNzE3NzI0NDc4MDk1NDQyNDVNMTQwOTI1NjI1ODc0MzY4OTAxNTk0ODUwMzM1MzYyODUyNDU3ODE2MzcyNzY5NDA2ODU0OTUyNjgzMDI2MTE4MzkwNzA4ODg1OTQ5MzcCATEBMANMNjY1Mjk2NTY3ODU5NzA5MzI1MTMwMTgyMzEwNDE3MjY5MTE3MjU2NTYyNzI1Nzg0MDI2NzIzODk3OTM3MDMxNjY5Mjc3NTgwOTIxMEw4ODEzMTc0NDc4NjQzMzY1MDk2NDI0NzM4OTM3ODgyNzk4NDk4NjgwNTY2Njc5ODUwMTA5NTM5MDcyMzMyOTY1NTM2MzY3MjY2MzY0ATExeUpwYzNNaU9pSm9kSFJ3Y3pvdkwyRmpZMjkxYm5SekxtZHZiMmRzWlM1amIyMGlMQwFmZXlKaGJHY2lPaUpTVXpJMU5pSXNJbXRwWkNJNklqRmtZekJtTVRjeVpUaGtObVZtTXpneVpEWmtNMkV5TXpGbU5tTXhPVGRrWkRZNFkyVTFaV1lpTENKMGVYQWlPaUpLVjFRaWZRTTIwOTUzNTg4NjQwNzAxNzE5ODYyMjA3MjM2NTUzOTgxMTk2MzU0MzY0Mjg1MDc5NDE1Njk1OTYxNTkwNzg5ODE5OTczOTg2NDQ3Njc3RgIAAAAAAABhAMYz6qmBfkLycfhzKVplT4pWAQlGamHlCILzRUBiFibQdnTDCPK6q4LC6o7tC/I+at63k5lMe19+rRqGmFlthQTr7teN2O5eCe21LpLTgQ4IpdmhxBbj2p18jaU+hSP46w==";
            pos.sign(doc, signature, ctx(s));
        
            let info = pos.signature_of_cid(MOCK_CID);
            assert!(info.requester() == SENDER, 404);

            let mut signers = vec_map::empty();
            signers.insert(RECEIPIENT, signature);
            assert!(info.signers() == signers, 404);

            test::return_shared(pos);
        };

        scenario.end();
    }

    #[test]
    fun test_reclaim() {
        let mut scenario = test::begin(SENDER);
        let s = &mut scenario;

        next_tx(s, SENDER);{
            sui_sign::init_for_testing(ctx(s));
        };

        // prepare sig request
        next_tx(s, SENDER);{
            let mut pos = test::take_shared<ProofOfSignature>(s);
            let gas = mint<SUI>(GAS_REQUIRED_AMT, ctx(s));

            let blob = blob::new_blob_for_testing(MOCK_CID, ctx(s));
            let mut doc = sui_sign::init_requested_signature(&mut pos, blob, gas, ctx(s));
            // add verification
            let witnesses = vector[x"244897572368eadf65bfbc5aec98d8e5443a9072"];
            doc.add_reclaim_validation(EPOCH_DURATION_IN_SECOND, witnesses, ctx(s));

            transfer::public_transfer(doc, RECEIPIENT);

            test::return_shared(pos);
        };

        next_tx(s, RECEIPIENT);{
            let mut pos = test::take_shared<ProofOfSignature>(s);
            let mut doc = test::take_from_sender<Document>(s);
            
            let gas = doc.sponsored_gas(ctx(s));
            assert!(burn(gas) == GAS_REQUIRED_AMT, 404);

            let parameters = b"{\"additionalClientOptions\":{},\"body\":\"\",\"geoLocation\":\"\",\"headers\":{\"Referer\":\"https://developers.google.com/people\",\"Sec-Fetch-Mode\":\"same-origin\",\"User-Agent\":\"Mozilla/5.0 (iPhone; CPU iPhone OS 17_6_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Safari/604.1\",\"x-requested-with\":\"XMLHttpRequest\"},\"method\":\"POST\",\"paramValues\":{\"email\":\"\\\"jarekcoding@gmail.com\\\"\"},\"responseMatches\":[{\"invert\":false,\"type\":\"contains\",\"value\":\"{{email}}\"}],\"responseRedactions\":[{\"jsonPath\":\"$.2\",\"regex\":\"(.*)\",\"xPath\":\"\"}],\"url\":\"https://developers.google.com/_d/profile/user\"}".to_string();
            let context = b"{\"contextAddress\":\"0x0\",\"contextMessage\":\"sample context\",\"extractedParameters\":{\"email\":\"\\\"jarekcoding@gmail.com\\\"\"},\"providerHash\":\"0x5e7ab21723033c2208a71f7147b2273ac235e7d964dcf25cf576ceb581fcf430\"}".to_string();
            let identifier = b"0x0f5d525976c9aca005200f046de586e079428517c83a1bd8e01cb785b533807c".to_string();
            let owner = b"0x4204c6a6b784b36f85c5677bd409cd2a5c4c1e0a".to_string();
            let epoch = b"1".to_string();
            let timestamp = b"1731576081".to_string();
            let signature = x"7f1236fc007c35404160cb2c10b50e2b03678fae6f73f98b8595afb45d233b364d7ecee711641ea49ac4951ec0f0305de261207f7db454ec597bfdfd071dc8951c";
            doc.verify_reclaim(
                parameters,
                context,
                identifier,
                owner, 
                epoch,
                timestamp,
                signature,
                ctx(s)
            );
            let signature = b"BQNMMTk4MzAxMzg0NzY2ODMxNTI4MDQxODU5OTkyNTIzNzQwODE1NDM4Njg5MDc2ODA1ODg1NDg3Mjc1ODIxNzY3Njk1ODEyMTU3MTEzN00xMDU4ODY5NDA2Njc0NTczODQzOTQwNjg4NTUxMzY0MDIwMTA0ODU0NDk5OTIzMDYxMzk3MTYyMTMwNjQ4MTQ4MDMzNTAxNTIzNTk4MQExAwJNMTYxODEzMTUyODM4ODI4MTQ5NTY1NTU4NTk3OTk2NDMyNjc1Mzc2MTM0NzMxNDczMDQzNzMyMzM3MzMxNzUyMzYwODQ3MDI2MTg1OTFMNDAwMDY5MTUxMjEyNTg4MDQ3MjE2MTQzODg4NTczODQ1MjI1MjQyNDk4MjgxODMxNTIzOTUyMjAxNTUyMTg0NjkzMTE5OTM4MDA0MAJNMTQzMjY4NTMxMDE0NDAxMTA3MzM3NzU4NTQzMDQ1MzQ0ODE1NTI4Njc4OTM2MjI2ODAxNzIyMzY3MjkyNzE3NzI0NDc4MDk1NDQyNDVNMTQwOTI1NjI1ODc0MzY4OTAxNTk0ODUwMzM1MzYyODUyNDU3ODE2MzcyNzY5NDA2ODU0OTUyNjgzMDI2MTE4MzkwNzA4ODg1OTQ5MzcCATEBMANMNjY1Mjk2NTY3ODU5NzA5MzI1MTMwMTgyMzEwNDE3MjY5MTE3MjU2NTYyNzI1Nzg0MDI2NzIzODk3OTM3MDMxNjY5Mjc3NTgwOTIxMEw4ODEzMTc0NDc4NjQzMzY1MDk2NDI0NzM4OTM3ODgyNzk4NDk4NjgwNTY2Njc5ODUwMTA5NTM5MDcyMzMyOTY1NTM2MzY3MjY2MzY0ATExeUpwYzNNaU9pSm9kSFJ3Y3pvdkwyRmpZMjkxYm5SekxtZHZiMmRzWlM1amIyMGlMQwFmZXlKaGJHY2lPaUpTVXpJMU5pSXNJbXRwWkNJNklqRmtZekJtTVRjeVpUaGtObVZtTXpneVpEWmtNMkV5TXpGbU5tTXhPVGRrWkRZNFkyVTFaV1lpTENKMGVYQWlPaUpLVjFRaWZRTTIwOTUzNTg4NjQwNzAxNzE5ODYyMjA3MjM2NTUzOTgxMTk2MzU0MzY0Mjg1MDc5NDE1Njk1OTYxNTkwNzg5ODE5OTczOTg2NDQ3Njc3RgIAAAAAAABhAMYz6qmBfkLycfhzKVplT4pWAQlGamHlCILzRUBiFibQdnTDCPK6q4LC6o7tC/I+at63k5lMe19+rRqGmFlthQTr7teN2O5eCe21LpLTgQ4IpdmhxBbj2p18jaU+hSP46w==";
            pos.sign(doc, signature, ctx(s));
        
            let info = pos.signature_of_cid(MOCK_CID);
            assert!(info.requester() == SENDER, 404);

            let mut signers = vec_map::empty();
            signers.insert(RECEIPIENT, signature);
            assert!(info.signers() == signers, 404);

            test::return_shared(pos);
        };

        scenario.end();
    }
}
