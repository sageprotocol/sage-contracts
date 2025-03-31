#[test_only]
module sage_shared::test_favorites {
    use sui::{
        test_scenario::{Self as ts},
        test_utils::{destroy}
    };

    use sage_shared::{
        favorites::{Self, EAlreadyFavorited}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    const EFavoritesMismatch: u64 = 0;
    const EFavoritesRecord: u64 = 1;
    const ENoFavoritesRecord: u64 = 2;

    // --------------- Test Functions ---------------

    #[test]
    fun test_favorites_create() {
        let mut scenario_val = ts::begin(ADMIN);

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let favorites = favorites::create(ts::ctx(scenario));

            destroy(favorites);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_favorites_add() {
        let mut scenario_val = ts::begin(ADMIN);

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mut favorites = favorites::create(ts::ctx(scenario));

            favorites::add(
                &mut favorites,
                ADMIN
            );

            let has_favorited = favorites::has_favorited(
                &favorites,
                ADMIN
            );

            assert!(has_favorited, ENoFavoritesRecord);

            let length = favorites::get_length(&favorites);

            assert!(length == 1, EFavoritesMismatch);

            destroy(favorites);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_favorites_remove() {
        let mut scenario_val = ts::begin(ADMIN);

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mut favorites = favorites::create(ts::ctx(scenario));

            favorites::add(
                &mut favorites,
                ADMIN
            );

            favorites::remove(
                &mut favorites,
                ADMIN
            );

            let has_favorited = favorites::has_favorited(
                &favorites,
                ADMIN
            );

            assert!(!has_favorited, EFavoritesRecord);

            let length = favorites::get_length(&favorites);

            assert!(length == 0, EFavoritesMismatch);

            destroy(favorites);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_favorites_assert_pass() {
        let mut scenario_val = ts::begin(ADMIN);

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let favorites = favorites::create(ts::ctx(scenario));

            favorites::assert_has_not_favorited(
                &favorites,
                ADMIN
            );

            destroy(favorites);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EAlreadyFavorited)]
    fun test_favorites_assert_fail() {
        let mut scenario_val = ts::begin(ADMIN);

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mut favorites = favorites::create(ts::ctx(scenario));

            favorites::add(
                &mut favorites,
                ADMIN
            );

            favorites::assert_has_not_favorited(
                &favorites,
                ADMIN
            );

            destroy(favorites);
        };

        ts::end(scenario_val);
    }
}