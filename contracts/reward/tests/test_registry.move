#[test_only]
module sage_reward::test_reward_weights_registry {
    use sui::{
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy}
    };

    use sage_admin::{admin::{Self}};

    use sage_reward::{
        reward::{Self, RewardWeights},
        reward_registry::{Self, RewardWeightsRegistry}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    fun create_reward_weights(): RewardWeights {
        let reward_weights = reward::create_weights(
            1,
            0
        );

        reward_weights
    }

    #[test_only]
    fun setup_for_testing(): (Scenario, RewardWeightsRegistry) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
            reward_registry::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let reward_weights_registry = {
            let reward_weights_registry = scenario.take_shared<RewardWeightsRegistry>();

            reward_weights_registry
        };

        (scenario_val, reward_weights_registry)
    }

    #[test]
    fun test_init() {
        let (
            mut scenario_val,
            reward_weights_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let current = reward_weights_registry.get_current();

            assert!(current == 0);

            let length = reward_weights_registry.get_length();

            assert!(length == 0);

            destroy(reward_weights_registry);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_add() {
        let (
            mut scenario_val,
            mut reward_weights_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let reward_weights = create_reward_weights();
            let timestamp = 1000;

            reward_weights_registry.add(
                reward_weights,
                timestamp
            );

            let current = reward_weights_registry.get_current();

            assert!(current == timestamp);

            let length = reward_weights_registry.get_length();

            assert!(length == 1);

            destroy(reward_weights_registry);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_borrow() {
        let (
            mut scenario_val,
            mut reward_weights_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let timestamp = 1000;

        ts::next_tx(scenario, ADMIN);
        {
            let reward_weights = create_reward_weights();

            reward_weights_registry.add(
                reward_weights,
                timestamp
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let _ = reward_weights_registry.borrow(timestamp);
            let _ = reward_weights_registry.borrow_current();

            let _ = reward_weights_registry.borrow_mut(timestamp);
            let _ = reward_weights_registry.borrow_current_mut();

            destroy(reward_weights_registry);
        };

        ts::end(scenario_val);
    }
}
