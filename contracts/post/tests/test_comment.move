#[test_only]
module sage_post::test_comments {
    use std::string::{utf8};

    use sui::{
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy}
    };

    use sage_admin::{admin::{Self}};

    use sage_post::{
        post::{Self},
        post_comments::{Self, PostCommentsRegistry}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    const EPostCommentsNotCreated: u64 = 0;

    // --------------- Test Functions ---------------

    #[test_only]
    fun setup_for_testing(): (Scenario, PostCommentsRegistry) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
            post_comments::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let post_comments_registry = {
            let post_comments_registry = scenario.take_shared<PostCommentsRegistry>();

            post_comments_registry
        };

        (scenario_val, post_comments_registry)
    }

    #[test]
    fun test_post_comments_init() {
        let (
            mut scenario_val,
            post_comments_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy(post_comments_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_post_comments_create() {
        let (
            mut scenario_val,
            mut post_comments_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let timestamp: u64 = 999;
            let user: address = @0xaaa;

            let (_parent_post, parent_post_key) = post::create(
                user,
                utf8(b"data"),
                utf8(b"description"),
                utf8(b"title"),
                timestamp,
                ts::ctx(scenario)
            );

            let (_post, post_key) = post::create(
                user,
                utf8(b"data"),
                utf8(b"description"),
                utf8(b"title"),
                timestamp,
                ts::ctx(scenario)
            );

            let post_comments_registry = &mut post_comments_registry_val;

            post_comments::add(
                post_comments_registry,
                parent_post_key,
                post_key
            );

            let has_post = post_comments::has_post(
                post_comments_registry,
                parent_post_key,
                post_key
            );

            assert!(has_post, EPostCommentsNotCreated);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy(post_comments_registry_val);
        };

        ts::end(scenario_val);
    }
}
