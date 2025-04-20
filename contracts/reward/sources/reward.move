module sage_reward::reward {
    
    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    public struct RewardWeights has store {
        end: u64,
        start: u64
    }

    public struct RewardWitness has drop {}

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun get_end(
        reward_weights: &RewardWeights
    ): u64 {
        reward_weights.end
    }

    public fun get_start(
        reward_weights: &RewardWeights
    ): u64 {
        reward_weights.start
    }

    public fun is_current(
        reward_weights: &RewardWeights,
        timestamp: u64
    ): bool {
        timestamp <= reward_weights.end &&
        timestamp >= reward_weights.start
    }

    // --------------- Friend Functions ---------------

    public(package) fun complete_weights(
        reward_weights: &mut RewardWeights,
        end: u64
    ) {
        reward_weights.end = end;
    }

    public(package) fun create_weights(
        end: u64,
        start: u64
    ): RewardWeights {
        RewardWeights {
            end,
            start
        }
    }

    // --------------- Internal Functions ---------------

    fun create_witness(): RewardWitness {
        RewardWitness {}
    }

    // --------------- Test Functions ---------------

    #[test_only]
    public fun create_witness_for_testing(): RewardWitness {
        create_witness()
    }
}
