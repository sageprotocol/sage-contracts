#[test_only]
module sage_shared::test_posts {
    use sui::{
        test_scenario::{Self as ts},
        test_utils::{destroy}
    };

    use sage_shared::{
        posts::{Self}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    const EPostsLengthMismatch: u64 = 0;
    const ENoPostsRecord: u64 = 1;

    // --------------- Test Functions ---------------

    #[test]
    fun test_posts_create() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let posts = posts::create(
                ts::ctx(scenario)
            );

            destroy(posts);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_posts_add() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mut posts = posts::create(
                ts::ctx(scenario)
            );

            let timestamp: u64 = 0;

            posts::add(
                &mut posts,
                timestamp,
                ADMIN
            );

            let has_record = posts::has_record(
                &posts,
                timestamp
            );

            assert!(has_record, ENoPostsRecord);

            let length = posts::get_length(&posts);

            assert!(length == 1, EPostsLengthMismatch);

            destroy(posts);
        };

        ts::end(scenario_val);
    }
}
