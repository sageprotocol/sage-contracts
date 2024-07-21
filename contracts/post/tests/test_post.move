#[test_only]
module sage_post::test_post {
    use std::string::{utf8};

    use sui::test_scenario::{Self as ts};

    use sage_post::{
        post::{Self}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    const EPostMismatch: u64 = 0;

    // --------------- Test Functions ---------------

    #[test]
    fun test_post() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let timestamp: u64 = 999;
            let user: address = @0xaaa;

            let (_post, _created_id) = post::create(
                user,
                utf8(b"data"),
                utf8(b"description"),
                utf8(b"title"),
                timestamp,
                ts::ctx(scenario)
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_get_key() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let timestamp: u64 = 999;
            let user: address = @0xaaa;

            let (post, created_key) = post::create(
                user,
                utf8(b"data"),
                utf8(b"description"),
                utf8(b"title"),
                timestamp,
                ts::ctx(scenario)
            );

            let retrieved_key = post::get_key(post);

            assert!(created_key == retrieved_key, EPostMismatch);
        };

        ts::end(scenario_val);
    }
}
