#[test_only]
module sage_post::test_like {
    use std::string::{utf8};

    use sui::test_scenario::{Self as ts, Scenario};

    use sage_admin::{admin::{Self, AdminCap}};

    use sage_post::{
        post::{Self},
        post_likes::{Self, PostLikesRegistry, UserPostLikesRegistry}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    const EPostLikesMismatch: u64 = 0;

    // --------------- Test Functions ---------------

    #[test_only]
    fun setup_for_testing(): (Scenario, PostLikesRegistry, UserPostLikesRegistry) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let (post_likes_registry, user_post_likes_registry) = {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            let post_likes_registry = post_likes::create_post_likes_registry(
                &admin_cap,
                ts::ctx(scenario)
            );

            let user_post_likes_registry = post_likes::create_user_post_likes_registry(
                &admin_cap,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, admin_cap);

            (post_likes_registry, user_post_likes_registry)
        };

        (scenario_val, post_likes_registry, user_post_likes_registry)
    }

    #[test]
    fun test_post_likes_init() {
        let (
            mut scenario_val,
            post_likes_registry_val,
            user_post_likes_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            post_likes::destroy_for_testing(
                post_likes_registry_val,
                user_post_likes_registry_val
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_post_like() {
        let (
            mut scenario_val,
            mut post_likes_registry_val,
            mut user_post_likes_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let timestamp: u64 = 999;
            let user: address = @0xaaa;

            let (_post, post_id) = post::create(
                user,
                utf8(b"data"),
                utf8(b"description"),
                utf8(b"title"),
                timestamp,
                ts::ctx(scenario)
            );

            let post_likes_registry = &mut post_likes_registry_val;
            let user_post_likes_registry = &mut user_post_likes_registry_val;

            post_likes::add(
                post_likes_registry,
                user_post_likes_registry,
                post_id,
                user
            );

            let post_likes = post_likes::borrow_post_likes(
                post_likes_registry,
                post_id
            );

            let user_post_likes = post_likes::borrow_user_post_likes(
                user_post_likes_registry,
                user
            );

            let has_record = post_likes::has_post_likes(
                post_likes,
                user
            );

            assert!(has_record, EPostLikesMismatch);

            let likes_count = post_likes::get_post_likes_count(
                post_likes
            );

            assert!(likes_count == 1, EPostLikesMismatch);

            let has_record = post_likes::has_user_likes(
                user_post_likes,
                post_id
            );

            assert!(has_record, EPostLikesMismatch);

            let likes_count = post_likes::get_user_likes_count(
                user_post_likes
            );

            assert!(likes_count == 1, EPostLikesMismatch);
        };

        ts::next_tx(scenario, ADMIN);
        {
            post_likes::destroy_for_testing(
                post_likes_registry_val,
                user_post_likes_registry_val
            );
        };

        ts::end(scenario_val);
    }
}
