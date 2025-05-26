#[test_only]
module sage_reward::test_reward {
    use std::{
        string::{utf8}
    };

    use sui::{
        test_scenario::{Self as ts},
        test_utils::{destroy}
    };

    use sage_reward::{
        reward::{Self}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    // --------------- Test Functions ---------------

    #[test]
    fun test_create_and_complete() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mut reward_weights = reward::create_weights(
                0,
                0,
                ts::ctx(scenario)
            );

            let end = reward_weights.get_end();
            let start = reward_weights.get_start();

            assert!(end == 0);
            assert!(start == 0);

            reward_weights.complete_weights(1000);

            let end = reward_weights.get_end();
            let start = reward_weights.get_start();

            assert!(end == 1000);
            assert!(start == 0);

            destroy(reward_weights);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_is_current() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mut reward_weights = reward::create_weights(
                0,
                0,
                ts::ctx(scenario)
            );

            let is_current = reward_weights.is_current(0);

            assert!(is_current);

            let is_current = reward_weights.is_current(1000);

            assert!(!is_current);

            reward_weights.complete_weights(1000);

            let is_current = reward_weights.is_current(0);

            assert!(is_current);

            let is_current = reward_weights.is_current(1000);

            assert!(is_current);

            let is_current = reward_weights.is_current(1001);

            assert!(!is_current);

            destroy(reward_weights);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_weights() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mut reward_weights = reward::create_weights(
                0,
                0,
                ts::ctx(scenario)
            );

            let metric = utf8(b"test");
            let weight = 8;

            let does_exist = reward::field_exists(
                &reward_weights,
                metric
            );

            assert!(!does_exist);

            let retrieved_weight = reward::get_weight(
                &reward_weights,
                metric
            );

            assert!(retrieved_weight == 0);

            reward::add_weight(
                &mut reward_weights,
                metric,
                weight
            );

            let does_exist = reward::field_exists(
                &reward_weights,
                metric
            );

            assert!(does_exist);

            let retrieved_weight = reward::get_weight(
                &reward_weights,
                metric
            );

            assert!(retrieved_weight == weight);

            destroy(reward_weights);
        };

        ts::end(scenario_val);
    }
}
