module sage_reward::reward {
    use std::{
        string::{String}
    };

    use sui::{
        dynamic_field::{Self as df}
    };
    
    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    public struct RewardWeight has copy, drop, store {
        metric: String
    }

    public struct RewardWeights has key, store {
        id: UID,
        end: u64,
        start: u64
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun field_exists(
        reward_weights: &RewardWeights,
        metric: String
    ): bool {
        let reward_weight = RewardWeight {
            metric
        };

        df::exists_with_type<RewardWeight, u64>(
            &reward_weights.id,
            reward_weight
        )
    }

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

    public fun get_weight(
        reward_weights: &RewardWeights,
        metric: String
    ): u64 {
        let does_exist = field_exists(
            reward_weights,
            metric
        );

        if (does_exist) {
            let reward_weight = RewardWeight {
                metric
            };

            *df::borrow<RewardWeight, u64>(
                &reward_weights.id,
                reward_weight
            )
        } else {
            0
        }
    }

    public fun is_current(
        reward_weights: &RewardWeights,
        timestamp: u64
    ): bool {
        timestamp <= reward_weights.end &&
        timestamp >= reward_weights.start
    }

    // --------------- Friend Functions ---------------

    public(package) fun add_weight(
        reward_weights: &mut RewardWeights,
        metric: String,
        value: u64
    ) {
        let reward_weight = RewardWeight {
            metric
        };

        df::add(
            &mut reward_weights.id,
            reward_weight,
            value
        );
    }

    public(package) fun complete_weights(
        reward_weights: &mut RewardWeights,
        end: u64
    ) {
        reward_weights.end = end;
    }

    public(package) fun create_weights(
        end: u64,
        start: u64,
        ctx: &mut TxContext
    ): RewardWeights {
        RewardWeights {
            id: object::new(ctx),
            end,
            start
        }
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
