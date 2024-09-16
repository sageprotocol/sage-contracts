#[test_only]
module sage_post::test_user_posts {
    use std::string::{utf8};

    use sui::{
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy}
    };

    use sage_admin::{admin::{Self}};

    use sage_post::{
        post::{Self},
        user_posts::{Self, UserPostsRegistry}
    };

    use sage_user::{user::{Self}};

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    const EUserPostsExists: u64 = 0;
    const EUserPostsDoesNotExist: u64 = 1;
    const EUserPostMismatch: u64 = 2;

    // --------------- Test Functions ---------------

    #[test_only]
    fun setup_for_testing(): (Scenario, UserPostsRegistry) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let user_posts_registry = {
            let user_posts_registry = scenario.take_shared<UserPostsRegistry>();

            user_posts_registry
        };

        (scenario_val, user_posts_registry)
    }

    #[test]
    fun test_user_posts_init() {
        let (
            mut scenario_val,
            user_posts_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy(user_posts_registry_val);
        };

        ts::end(scenario_val);
    }

     #[test]
    fun test_user_posts_create() {
        let (
            mut scenario_val,
            mut user_posts_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let created_at: u64 = 999;

            let user = user::create_for_testing(
                ADMIN,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                created_at,
                utf8(b"description"),
                utf8(b"user-name")
            );

            let user_posts_registry = &mut user_posts_registry_val;

            let has_record = user_posts::has_record(
                user_posts_registry,
                user
            );

            assert!(!has_record, EUserPostsExists);

            user_posts::create_for_testing(
                user_posts_registry,
                user
            );

            let has_record = user_posts::has_record(
                user_posts_registry,
                user
            );

            assert!(has_record, EUserPostsDoesNotExist);

            destroy(user_posts_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_posts_add() {
        let (
            mut scenario_val,
            mut user_posts_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let created_at: u64 = 999;

            let user = user::create_for_testing(
                ADMIN,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                created_at,
                utf8(b"description"),
                utf8(b"user-name")
            );

            let user_posts_registry = &mut user_posts_registry_val;

            user_posts::create_for_testing(
                user_posts_registry,
                user
            );

            let timestamp: u64 = 999;
            let address: address = @0xaaa;

            let (_post, post_key) = post::create(
                address,
                utf8(b"data"),
                utf8(b"description"),
                utf8(b"title"),
                timestamp,
                ts::ctx(scenario)
            );

            user_posts::add(
                user_posts_registry,
                user,
                post_key
            );

            let has_post = user_posts::has_post(
                user_posts_registry,
                user,
                post_key
            );

            assert!(has_post, EUserPostMismatch);

            destroy(user_posts_registry_val);
        };

        ts::end(scenario_val);
    }
}
