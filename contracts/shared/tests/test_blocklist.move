#[test_only]
module sage_shared::test_blocklist {
    use sui::{
        test_scenario::{Self as ts},
        test_utils::{destroy}
    };

    use sage_shared::{
        blocklist::{Self, EIsBlocked}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    // --------------- Test Functions ---------------

    #[test]
    fun test_blocklist_create() {
        let mut scenario_val = ts::begin(ADMIN);

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let blocklist = blocklist::create(ts::ctx(scenario));

            destroy(blocklist);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_blocklist_add_permanent() {
        let mut scenario_val = ts::begin(ADMIN);

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mut blocklist = blocklist::create(ts::ctx(scenario));

            let is_blocked = blocklist::is_blocked(
                &mut blocklist,
                ADMIN,
                20
            );

            assert!(!is_blocked);

            let start = 10;

            blocklist::block(
                &mut blocklist,
                option::none(),
                start,
                ADMIN
            );

            let is_blocked = blocklist::is_blocked(
                &mut blocklist,
                ADMIN,
                20
            );

            assert!(is_blocked);

            destroy(blocklist);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_blocklist_add_temporary() {
        let mut scenario_val = ts::begin(ADMIN);

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mut blocklist = blocklist::create(ts::ctx(scenario));

            let end = 100;
            let start = 10;

            blocklist::block(
                &mut blocklist,
                option::some(end),
                start,
                ADMIN
            );

            let is_blocked = blocklist::is_blocked(
                &mut blocklist,
                ADMIN,
                20
            );

            assert!(is_blocked);

            let is_blocked = blocklist::is_blocked(
                &mut blocklist,
                ADMIN,
                99
            );

            assert!(is_blocked);

            let is_blocked = blocklist::is_blocked(
                &mut blocklist,
                ADMIN,
                100
            );

            assert!(!is_blocked);

            let is_blocked = blocklist::is_blocked(
                &mut blocklist,
                ADMIN,
                101
            );

            assert!(!is_blocked);

            destroy(blocklist);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_blocklist_remove() {
        let mut scenario_val = ts::begin(ADMIN);

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mut blocklist = blocklist::create(ts::ctx(scenario));

            let start = 10;

            blocklist::block(
                &mut blocklist,
                option::none(),
                start,
                ADMIN
            );

            blocklist::unblock(
                &mut blocklist,
                ADMIN
            );

            let is_blocked = blocklist::is_blocked(
                &mut blocklist,
                ADMIN,
                20
            );

            assert!(!is_blocked);

            destroy(blocklist);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_blocklist_assert_permanent_pass() {
        let mut scenario_val = ts::begin(ADMIN);

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mut blocklist = blocklist::create(ts::ctx(scenario));

            blocklist::assert_is_not_blocked(
                &mut blocklist,
                ADMIN,
                20
            );

            destroy(blocklist);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_blocklist_assert_temporary_pass() {
        let mut scenario_val = ts::begin(ADMIN);

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mut blocklist = blocklist::create(ts::ctx(scenario));

            let end = 100;
            let start = 10;

            blocklist::block(
                &mut blocklist,
                option::some(end),
                start,
                ADMIN
            );

            blocklist::assert_is_not_blocked(
                &mut blocklist,
                ADMIN,
                100
            );

            destroy(blocklist);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIsBlocked)]
    fun test_blocklist_assert_permanent_fail() {
        let mut scenario_val = ts::begin(ADMIN);

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mut blocklist = blocklist::create(ts::ctx(scenario));

            let start = 10;

            blocklist::block(
                &mut blocklist,
                option::none(),
                start,
                ADMIN
            );

            blocklist::assert_is_not_blocked(
                &mut blocklist,
                ADMIN,
                10
            );

            destroy(blocklist);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIsBlocked)]
    fun test_blocklist_assert_temporary_fail() {
        let mut scenario_val = ts::begin(ADMIN);

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mut blocklist = blocklist::create(ts::ctx(scenario));

            let end = 100;
            let start = 10;

            blocklist::block(
                &mut blocklist,
                option::some(end),
                start,
                ADMIN
            );

            blocklist::assert_is_not_blocked(
                &mut blocklist,
                ADMIN,
                20
            );

            destroy(blocklist);
        };

        ts::end(scenario_val);
    }
}