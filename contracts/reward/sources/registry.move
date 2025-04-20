module sage_reward::reward_registry {
    use sui::{
        table::{Self, Table}
    };

    use sage_reward::{
        reward::{RewardWeights}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    public struct RewardWeightsRegistry has key {
        id: UID,
        current: u64,
        reward_weights_registry: Table<u64, RewardWeights>
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    fun init(
        ctx: &mut TxContext
    ) {
        let reward_weights_registry = RewardWeightsRegistry {
            id: object::new(ctx),
            current: 0,
            reward_weights_registry: table::new(ctx)
        };

        transfer::share_object(reward_weights_registry);
    }

    // --------------- Public Functions ---------------

    public fun borrow(
        reward_weights_registry: &RewardWeightsRegistry,
        timestamp: u64
    ): &RewardWeights {
        &reward_weights_registry.reward_weights_registry[timestamp]
    }

    public fun borrow_current(
        reward_weights_registry: &RewardWeightsRegistry
    ): &RewardWeights {
        &reward_weights_registry.reward_weights_registry[reward_weights_registry.current]
    }

    public fun get_current(
        reward_weights_registry: &RewardWeightsRegistry
    ): u64 {
        reward_weights_registry.current
    }

    public fun get_length(
        reward_weights_registry: &RewardWeightsRegistry
    ): u64 {
        reward_weights_registry.reward_weights_registry.length()
    }

    // --------------- Friend Functions ---------------

    public(package) fun add(
        reward_weights_registry: &mut RewardWeightsRegistry,
        reward_weights: RewardWeights,
        timestamp: u64
    ) {
        reward_weights_registry.current = timestamp;

        reward_weights_registry.reward_weights_registry.add(
            timestamp,
            reward_weights
        );
    }

    public(package) fun borrow_mut(
        reward_weights_registry: &mut RewardWeightsRegistry,
        timestamp: u64
    ): &mut RewardWeights {
        &mut reward_weights_registry.reward_weights_registry[timestamp]
    }

    public(package) fun borrow_current_mut(
        reward_weights_registry: &mut RewardWeightsRegistry
    ): &mut RewardWeights {
        &mut reward_weights_registry.reward_weights_registry[reward_weights_registry.current]
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}
