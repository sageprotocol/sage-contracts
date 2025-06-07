module sage_reward::reward_registry {
    use sui::{
        table::{Self, Table}
    };

    use sage_reward::{
        reward::{RewardCostWeights}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    public struct RewardCostWeightsRegistry has key {
        id: UID,
        current: u64,
        reward_cost_weights_registry: Table<u64, RewardCostWeights>
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    fun init(
        ctx: &mut TxContext
    ) {
        let reward_cost_weights_registry = RewardCostWeightsRegistry {
            id: object::new(ctx),
            current: 0,
            reward_cost_weights_registry: table::new(ctx)
        };

        transfer::share_object(reward_cost_weights_registry);
    }

    // --------------- Public Functions ---------------

    public fun borrow(
        reward_cost_weights_registry: &RewardCostWeightsRegistry,
        timestamp: u64
    ): &RewardCostWeights {
        &reward_cost_weights_registry.reward_cost_weights_registry[timestamp]
    }

    public fun borrow_current(
        reward_cost_weights_registry: &RewardCostWeightsRegistry
    ): &RewardCostWeights {
        &reward_cost_weights_registry.reward_cost_weights_registry[reward_cost_weights_registry.current]
    }

    public fun get_current(
        reward_cost_weights_registry: &RewardCostWeightsRegistry
    ): u64 {
        reward_cost_weights_registry.current
    }

    public fun get_length(
        reward_cost_weights_registry: &RewardCostWeightsRegistry
    ): u64 {
        reward_cost_weights_registry.reward_cost_weights_registry.length()
    }

    // --------------- Friend Functions ---------------

    public(package) fun add(
        reward_cost_weights_registry: &mut RewardCostWeightsRegistry,
        reward_cost_weights: RewardCostWeights,
        timestamp: u64
    ) {
        reward_cost_weights_registry.current = timestamp;

        reward_cost_weights_registry.reward_cost_weights_registry.add(
            timestamp,
            reward_cost_weights
        );
    }

    public(package) fun borrow_mut(
        reward_cost_weights_registry: &mut RewardCostWeightsRegistry,
        timestamp: u64
    ): &mut RewardCostWeights {
        &mut reward_cost_weights_registry.reward_cost_weights_registry[timestamp]
    }

    public(package) fun borrow_current_mut(
        reward_cost_weights_registry: &mut RewardCostWeightsRegistry
    ): &mut RewardCostWeights {
        &mut reward_cost_weights_registry.reward_cost_weights_registry[reward_cost_weights_registry.current]
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}
