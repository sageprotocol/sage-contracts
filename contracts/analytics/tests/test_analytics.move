#[test_only]
module sage_analytics::test_analytics {
    use std::{
        string::{utf8}
    };

    use sui::{
        test_scenario::{Self as ts},
        test_utils::{destroy}
    };

    use sage_analytics::{
        analytics::{Self}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    // --------------- Test Functions ---------------

    #[test]
    fun test_create() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let analytics = analytics::create(
                ts::ctx(scenario)
            );

            destroy(analytics);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_add_and_remove() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mut analytics = analytics::create(
                ts::ctx(scenario)
            );

            let key = utf8(b"analytics");
            let value = 5;

            let retrieved_value = analytics::get_field(
                &analytics,
                key
            );

            assert!(retrieved_value == 0);

            analytics::add_field(
                &mut analytics,
                key,
                value
            );

            let does_exist = analytics::field_exists(
                &analytics,
                key
            );

            assert!(does_exist);

            let retrieved_value = analytics::get_field(
                &analytics,
                key
            );

            assert!(retrieved_value == value);

            analytics::remove_field(
                &mut analytics,
                key
            );

            let does_exist = analytics::field_exists(
                &analytics,
                key
            );

            assert!(!does_exist);

            destroy(analytics);
        };

        ts::end(scenario_val);
    }
}
