module sui_sign::reclaim {
    use std::string;
    use sui::table::{Self, Table};
    use sui::hash;
    use sui_sign::ecdsa;
    use sui::bcs;


    // Represents a witness in the system
    // public struct Witness has store, copy, drop {
    //     // addr: vector<u8>, // Address of the witness
    //     host: string::String, // Host information of the witness
    // }

    // Represents an epoch in the system
    public struct Epoch has store, drop{
        epoch_number: u8, // Epoch number
        timestamp_start: u64, // Start timestamp of the epoch
        timestamp_end: u64, // End timestamp of the epoch
        witnesses: vector<vector<u8>>, // List of witnesses in the epoch
        minimum_witnesses_for_claim_creation: u128, // Minimum number of witnesses required for claim creation
    }

    // Represents the claim information
    public struct ClaimInfo has store, copy, drop {
        provider: string::String, // Claim provider information
        parameters: string::String, // Claim parameters
        context: string::String, // Claim context
    }

    // Represents a signed claim
    public struct SignedClaim has store, copy, drop {
        claim: CompleteClaimData, // Claim object
        signatures: vector<vector<u8>>, // Signatures for the claim
    }

    // Represents a claim
    public struct CompleteClaimData has store, copy, drop {
        identifier: string::String, // Claim identifier
        owner: string::String, // Claim owner
        epoch: string::String, // Epoch number of the claim
        timestamp_s: string::String, // Claim timestamp
    }

    // Represents a proof
    public struct Proof has store, drop{
        claim_info: ClaimInfo, // Claim information
        signed_claim: SignedClaim, // Signed claim
    }

    // Represents the Reclaim Manager
    public struct ReclaimManager has key, store{
        id: UID, // Unique identifier for the Reclaim Manager
        owner: address, // Address of the Reclaim Manager owner
        epoch_duration_s: u32, // Duration of each epoch in seconds
        current_epoch: u8, // Current epoch number
        epochs: vector<Epoch>, // List of epochs
        // created_groups: Table<vector<u8>, bool>, // Table to store created groups
        // merkelized_user_params: Table<vector<u8>, bool>, // Table to store merkelized user parameters
        // dapp_id_to_external_nullifier: Table<vector<u8>, vector<u8>>, // Table to map dapp IDs to external nullifiers
    }

    public fun drop_reclaim_manager(manager: ReclaimManager){
        let ReclaimManager{
            id,
            owner: _,
            epoch_duration_s: _,
            current_epoch: _,
            epochs: _
        } = manager;

        object::delete(id);
    }

    // Creates a new claim info
    public fun create_claim_info(provider: string::String, parameters: string::String, context: string::String): ClaimInfo {
        ClaimInfo {
            provider,
            parameters,
            context,
        }
    }

    // Creates a new complete claim data
    public fun create_claim_data(identifier: string::String, owner: string::String, epoch: string::String, timestamp_s: string::String): CompleteClaimData {
        CompleteClaimData {
            identifier,
            owner,
            epoch,
            timestamp_s
        }
    }

    // Creates a new signed claim
    public fun create_signed_claim(claim: CompleteClaimData, signatures: vector<vector<u8>>): SignedClaim {
        SignedClaim {
            claim,
            signatures,
        }
    }

    // Creates a new proof
    public fun create_proof(
        claim_info: ClaimInfo,
        signed_claim: SignedClaim
    ):Proof {
        // Create a new proof object with the provided claim information and signed claim
        Proof {
            claim_info,
            signed_claim,
        }
    }

    // Creates a new epoch
    public fun create_epoch(
        epoch_number: u8,
        timestamp_start: u64,
        timestamp_end: u64,
        witnesses: vector<vector<u8>>, // List of witnesses
        minimum_witnesses_for_claim_creation: u128,
    ): Epoch {
        // Create a new epoch object with the provided epoch details
        Epoch {
            epoch_number,
            timestamp_start,
            timestamp_end,
            witnesses,
            minimum_witnesses_for_claim_creation,
        }
    }

    // Creates a new Reclaim Manager
    public fun create_reclaim_manager(
        epoch_duration_s: u32,
        ctx: &mut TxContext,
    ):ReclaimManager {
        // Create a new Reclaim Manager object with the provided details
        ReclaimManager {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            epoch_duration_s,
            current_epoch: 0,
            epochs: vector::empty(),
            // created_groups: table::new(ctx),
            // merkelized_user_params: table::new(ctx),
            // dapp_id_to_external_nullifier: table::new(ctx),
        }
    }

    // Adds a new epoch to the Reclaim Manager
    public fun add_new_epoch(
        manager: &mut ReclaimManager,
        witnesses: vector<vector<u8>>,
        requisite_witnesses_for_claim_create: u128,
        ctx: &mut TxContext,
    ) {
        assert!(manager.owner == tx_context::sender(ctx), 0);
        let epoch_number = manager.current_epoch + 1;
        let timestamp_start = tx_context::epoch(ctx);
        let timestamp_end = timestamp_start + (manager.epoch_duration_s as u64);

        // let witness_ids: vector<UID> = vector::empty();
        // vector::for_each(witnesses, |witness| {
        //     vector::push_back(&mut witness_ids, witness.id);
        // });

        let new_epoch = create_epoch(
            epoch_number,
            timestamp_start,
            timestamp_end,
            witnesses,
            requisite_witnesses_for_claim_create,
        );
        vector::push_back(&mut manager.epochs, new_epoch);
        manager.current_epoch = epoch_number;
       //event::emit(EpochAdded { epoch: new_epoch });
    }

    // Creates a new Dapp
    // public fun create_dapp(manager: &mut ReclaimManager, id: vector<u8>, ctx: &mut TxContext) {
    //     let sender_address = tx_context::sender(ctx);
    //     let mut combined = vector::empty<u8>();
    //     
    //     // Append sender address bytes
    //     let sender_bytes = bcs::to_bytes(&sender_address);
    //     let mut i = 0;
    //     while (i < vector::length(&sender_bytes)) {
    //         vector::push_back(&mut combined, *vector::borrow(&sender_bytes, i));
    //         i = i + 1;
    //     };
    //     
    //     // Append id bytes
    //     i = 0;
    //     while (i < vector::length(&id)) {
    //         vector::push_back(&mut combined, *vector::borrow(&id, i));
    //         i = i + 1;
    //     };
    //
    //     // Generate the dapp_id using keccak256 hash
    //     let dapp_id = hash::keccak256(&combined);
    //     assert!(!table::contains(&manager.dapp_id_to_external_nullifier, dapp_id), 0);
    //     table::add(&mut manager.dapp_id_to_external_nullifier, dapp_id, id);
    //     // event::emit(DappCreated { dapp_id });
    // }


    // Gets the provider name from the proof
    public fun get_provider_from_proof(proof: &Proof): string::String {
        proof.claim_info.provider
    }

    // Checks if the merkellized user params exist
    // public fun has_merkellized_user_params(manager: &ReclaimManager, provider: string::String, params: string::String): bool {
    //     let user_params_hash = hash_user_params(provider, params);
    //     table::contains(&manager.merkelized_user_params, user_params_hash)
    // }

    // Extracts a field from the context
    // // @TODO: Test for providerHash utility
    // fun extract_field_from_context(data: string::String, target: string::String): string::String {
    // let data_bytes = string::bytes(&data);
    // let target_bytes = string::bytes(&target);
    // assert!(*vector::borrow(data_bytes, 0) == *vector::borrow(target_bytes, 0), 0); // target is longer than data

    // let start = 0;
    // let found_start = false;

    // // Find start of "contextMessage":"
    // let i = 0;
    // while (i <= vector::length(data_bytes) - vector::length(target_bytes)) {
    //     let is_match = true;
    //     let j = 0;
    //     while (j < vector::length(target_bytes) && is_match) {
    //         if (*vector::borrow(data_bytes, i + j) != *vector::borrow(target_bytes, j)) {
    //             is_match = false;
    //         };
    //         j = j + 1;
    //     };
    //     if (is_match) {
    //         start = i + vector::length(target_bytes); // Move start to the end of "contextMessage":"
    //         found_start = true;
    //         break;
    //     };
    //     i = i + 1;
    // };
    // if (!found_start) {
    //     string::utf8(vector::empty()) // Malformed
    // } else {
    //     // Find the end of the message, assuming it ends with a quote not preceded by a backslash
    //     let end = start;
    //     while (end < vector::length(&data_bytes) && !(*vector::borrow(&data_bytes, end) == b""" && *vector::borrow(&data_bytes, end - 1) != b"\\")) {
    //         end = end + 1;
    //     };

    //     if (end <= start) {
    //         string::utf8(vector::empty()) // Malformed or missing message
    //     } else {
    //         let context_message = vector::empty();
    //         vector::reserve(&mut context_message, end - start);
    //         while (start < end) {
    //             vector::push_back(&mut context_message, *vector::borrow(data_bytes, start));
    //             start = start + 1;
    //         };
    //         string::utf8(context_message)
    //         }
    //     }
    // }

    // Verifies a proof
    public fun verify_proof(
        manager: &ReclaimManager,
        proof: &Proof,
        ctx: &mut TxContext,
    ): vector<vector<u8>> {
        // Create signed claim using claimData and signature
        assert!(vector::length(&proof.signed_claim.signatures) > 0, 0); // No signatures

        let signed_claim = SignedClaim {
            claim: proof.signed_claim.claim,
            signatures: proof.signed_claim.signatures,
        };


        let identifier = string::substring(&proof.signed_claim.claim.identifier, 2, string::length(&proof.signed_claim.claim.identifier));
        let hashed = hash_claim_info(&proof.claim_info);
        assert!(hashed == identifier, 1);

        // Fetch witness list from fetchEpoch(_epoch).witnesses
       let expected_witnesses = fetch_witnesses_for_claim(
                    manager,
                    proof.signed_claim.claim.identifier,
        );

        let signed_witnesses = recover_signers_of_signed_claim(signed_claim);
        assert!(!contains_duplicates(&signed_witnesses, ctx), 0); // Contains duplicate signatures
        assert!(vector::length(&signed_witnesses) == vector::length(&expected_witnesses), 0); // Number of signatures not equal to number of witnesses

        // Create a table for expected witnesses for efficient lookup
        let mut expected_witnesses_table = table::new<vector<u8>, bool>(ctx);
        let mut i = 0;
        while (i < vector::length(&expected_witnesses)) {
            table::add(&mut expected_witnesses_table, *vector::borrow(&expected_witnesses, i), true);
            i = i + 1;
        };
        // Check if all signed witnesses are in the expected witnesses table
        i = 0;
       std::debug::print(&expected_witnesses); 
       std::debug::print(&signed_witnesses); 
        while (i < vector::length(&signed_witnesses)) {
            assert!(table::remove(&mut expected_witnesses_table, *vector::borrow(&signed_witnesses, i)), 0); // Signature not appropriate
            i = i + 1;
        };
        table::destroy_empty(expected_witnesses_table); // Destroy the table after use

        signed_witnesses
        // // @TODO: Check if the providerHash is in the list of providers
        // let proof_provider_hash = extract_field_from_context(proof.claim_info.context, string::utf8(b"\"providerHash\":\""));
        // let i = 0;
        // while (i < vector::length(providers_hashes)) {
        //     if (string::equal(&proof_provider_hash, &vector::borrow(providers_hashes, i))) {
        //         return true;
        //     };
        //     i = i + 1;
        // };
    }


    // Helper function to check for duplicates in a vector
    fun contains_duplicates(vec: &vector<vector<u8>>, ctx: &mut TxContext): bool {
        let mut seen = table::new<vector<u8>, bool>(ctx);
        let mut i = 0;
        let mut has_duplicate = false;

        while (i < vector::length(vec)) {
            let item = vector::borrow(vec, i);
            if (table::contains(&seen, *item)) {
                has_duplicate = true;
                break
            };
            table::add(&mut seen, *item, true);
            i = i + 1;
        };

        let mut j = 0;
        while (j < vector::length(vec)) {
            let entry = vector::borrow(vec, j);
            if (table::contains(&seen, *entry)) {
                table::remove(&mut seen, *entry);
            };
            j = j + 1;
        };

        table::destroy_empty(seen);
        has_duplicate
    }


    // Helper functions
    fun fetch_witnesses_for_claim(
        manager: &ReclaimManager,
        identifier: string::String,
    ): vector<vector<u8>> {
        let epoch_data = fetch_epoch(manager);
        let complete_hash = hash::keccak256(string::as_bytes(&identifier));
        let mut witnesses_left_list = epoch_data.witnesses;
        let mut selected_witnesses = vector::empty();
        let minimum_witnesses = epoch_data.minimum_witnesses_for_claim_creation;

        let mut witnesses_left = vector::length(&witnesses_left_list);

        let mut byte_offset = 0;
        let mut i = 0;
        let complete_hash_len = vector::length(&complete_hash);
        while (i < minimum_witnesses) {
            // Extract four bytes at byte_offset from complete_hash
            let mut random_seed = 0;
            let mut j = 0;
            while (j < 4) {
                let byte_index = (byte_offset + j) % complete_hash_len;
                let byte_value = *vector::borrow(&complete_hash, byte_index) as u64;
                random_seed =  (byte_value << ((8 * j as u8)));
                j = j + 1;
            };

            let witness_index = random_seed % witnesses_left;
            let witness = *vector::borrow(&witnesses_left_list, witness_index);

            // Swap the last element with the one to be removed and then remove the last element
            let last_index = witnesses_left - 1;
            if (witness_index != last_index) {
                vector::swap(&mut witnesses_left_list, witness_index, last_index);
            };
            let _ = vector::pop_back(&mut witnesses_left_list);

            vector::push_back(&mut selected_witnesses, witness);

            byte_offset = (byte_offset + 4) % complete_hash_len;
            witnesses_left = witnesses_left - 1;
            i = i + 1;
        };

        selected_witnesses
    }

    fun hash_user_params(provider: string::String, params: string::String): vector<u8> {
        let mut user_params = b"".to_string();
        user_params.append(provider);
        user_params.append(b":".to_string());
        user_params.append(params);
        hash::keccak256(string::as_bytes(&user_params))
    }
    

    fun byte_to_hex_char(byte: u8): u8 {
        if (byte < 10) {
            
            byte + 48 // '0' is 48 in ASCII
        } else {
            byte + 87 // 'a' is 97 in ASCII, 97 - 10 = 87
        }
    }

     public fun bytes_to_hex(bytes: &vector<u8>): string::String {
        let mut hex_string = vector::empty<u8>();
        let mut i = 0;
        while (i < vector::length(bytes)) {
            let byte = *vector::borrow(bytes, i);
            let high_nibble = (byte >> 4) & 0x0F;
            let low_nibble = byte & 0x0F;
            vector::push_back(&mut hex_string, byte_to_hex_char(high_nibble));
            vector::push_back(&mut hex_string, byte_to_hex_char(low_nibble));
            i = i + 1;
        };
        string::utf8(hex_string)
    }


    fun hash_claim_info(claim_info: &ClaimInfo): string::String {
        let mut claim_info_data = claim_info.provider;
        claim_info_data.append(b"\n".to_string());
        claim_info_data.append(claim_info.parameters);
        claim_info_data.append(b"\n".to_string());
        claim_info_data.append(claim_info.context);

        let hash_bytes = hash::keccak256(string::as_bytes(&claim_info_data));
        bytes_to_hex(&hash_bytes)
    }

    fun recover_signers_of_signed_claim(signed_claim: SignedClaim): vector<vector<u8>> {
        let mut expected = vector<vector<u8>>[];
        let endl = b"\n".to_string();
        let mut message = b"".to_string();

        let mut complete_claim_data_padding = signed_claim.claim.timestamp_s;
        complete_claim_data_padding.append(endl);
        complete_claim_data_padding.append(signed_claim.claim.epoch);
        message.append(signed_claim.claim.identifier);
        message.append(endl);
        message.append(signed_claim.claim.owner);
        message.append(endl);
        message.append(complete_claim_data_padding);

        let mut eth_msg = b"\x19Ethereum Signed Message:\n".to_string();

        eth_msg.append(b"122".to_string());
        eth_msg.append(message);
        let msg = string::as_bytes(&eth_msg);
        
        let mut i = 0;
        while ( i < vector::length(&signed_claim.signatures)){
            let signature = signed_claim.signatures[i];
            let addr = ecdsa::ecrecover_to_eth_address(signature, *msg);
            vector::push_back(&mut expected, addr);
            i = i + 1
        };
        
        expected
    }

    public fun fetch_epoch(manager: &ReclaimManager): &Epoch {
        vector::borrow(&manager.epochs, (manager.current_epoch - 1) as u64)
    }

}

    
