#[test_only]
module sage_post::test_comments {
    use std::string::{utf8};

    use sui::test_scenario::{Self as ts, Scenario};

    use sage_admin::{admin::{Self, AdminCap}};

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
        };

        ts::next_tx(scenario, ADMIN);
        let post_comments_registry = {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            let post_comments_registry = post_comments::create_post_comments_registry(
                &admin_cap,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, admin_cap);

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
            post_comments::destroy_for_testing(post_comments_registry_val);
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

            let (post, post_id) = post::create(
                user,
                utf8(b"data"),
                utf8(b"description"),
                utf8(b"title"),
                timestamp,
                ts::ctx(scenario)
            );

            let post_comments_registry = &mut post_comments_registry_val;

            post_comments::create(
                post_comments_registry,
                post_id,
                ts::ctx(scenario)
            );

            let has_record = post_comments::has_record(
                post_comments_registry,
                post_id
            );

            assert!(has_record, EPostCommentsNotCreated);

            let post_comments = post_comments::get_post_comments(
                post_comments_registry,
                post_id
            );

            post_comments::add(
                post_comments,
                post_id,
                post
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            post_comments::destroy_for_testing(post_comments_registry_val);
        };

        ts::end(scenario_val);
    }
}
