#[test_only]
module sage_shared::test_likes {
    use sui::{
        test_scenario::{Self as ts},
        test_utils::{destroy}
    };

    use sage_shared::{
        likes::{Self, EAlreadyLiked}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    const ELikesMismatch: u64 = 0;
    const ENoLikesRecord: u64 = 1;

    // --------------- Test Functions ---------------

    #[test]
    fun test_likes_create() {
        let mut scenario_val = ts::begin(ADMIN);

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let likes = likes::create(ts::ctx(scenario));

            destroy(likes);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_likes_add() {
        let mut scenario_val = ts::begin(ADMIN);

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mut likes = likes::create(ts::ctx(scenario));

            likes::add(
                &mut likes,
                ADMIN
            );

            let has_liked = likes::has_liked(
                &likes,
                ADMIN
            );

            assert!(has_liked, ENoLikesRecord);

            let length = likes::get_length(&likes);

            assert!(length == 1, ELikesMismatch);

            destroy(likes);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_likes_assert_pass() {
        let mut scenario_val = ts::begin(ADMIN);

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let likes = likes::create(ts::ctx(scenario));

            likes::assert_has_not_liked(
                &likes,
                ADMIN
            );

            destroy(likes);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EAlreadyLiked)]
    fun test_likes_assert_fail() {
        let mut scenario_val = ts::begin(ADMIN);

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mut likes = likes::create(ts::ctx(scenario));

            likes::add(
                &mut likes,
                ADMIN
            );

            likes::assert_has_not_liked(
                &likes,
                ADMIN
            );

            destroy(likes);
        };

        ts::end(scenario_val);
    }
}