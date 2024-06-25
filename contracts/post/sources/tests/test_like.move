#[test_only]
module sage::test_like {
    use std::string::{utf8};

    use sui::test_scenario::{Self as ts, Scenario};

    use sui::{table::{ETableNotEmpty}};

    use sage::{
        admin::{Self, AdminCap},
        post::{Self},
        post_likes::{Self, PostLikesRegistry}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @0xde1;

    // --------------- Errors ---------------

    const EPostLikesMismatch: u64 = 0;

    // --------------- Test Functions ---------------

    #[test_only]
    fun setup_for_testing(): (Scenario, PostLikesRegistry) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let post_likes_registry = {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            let post_likes_registry = post_likes::create_post_likes_registry(
                &admin_cap,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, admin_cap);

            post_likes_registry
        };

        (scenario_val, post_likes_registry)
    }

    #[test]
    fun test_post_likes_init() {
        let (
            mut scenario_val,
            post_likes_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            post_likes::destroy_for_testing(post_likes_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ETableNotEmpty)]
    fun test_post_like() {
        let (
            mut scenario_val,
            mut post_likes_registry_val
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

            let post_likes_registry = &mut post_likes_registry_val;

            post_likes::create(
                post_likes_registry,
                post_id,
                ts::ctx(scenario)
            );

            let post_likes = post_likes::get(
                post_likes_registry,
                post_id
            );

            post_likes::add(
                post_likes,
                post_id,
                user
            );

            let has_record = post_likes::has_record(
                post_likes,
                user
            );

            assert!(has_record, EPostLikesMismatch);

            let (uid, _id) = post::get_id(post);

            object::delete(uid);
        };

        ts::next_tx(scenario, ADMIN);
        {
            post_likes::destroy_for_testing(post_likes_registry_val);
        };

        ts::end(scenario_val);
    }
}
