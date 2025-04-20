#[test_only]
module sage_reward::test_reward_actions {
    use sui::{
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy}
    };

    use sage_admin::{admin::{Self}};

    use sage_reward::{
        reward::{Self, RewardWeights},
        reward_actions::{Self},
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
        let reward_registry = {
            let reward_registry = scenario.take_shared<RewardWeightsRegistry>();

            reward_registry
        };

        (scenario_val, reward_registry)
    }
}
