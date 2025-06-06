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

    public struct RewardCostWeight has copy, drop, store {
        metric: String
    }

    public struct RewardCostWeights has key, store {
        id: UID,
        end: u64,
        start: u64
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun field_exists(
        reward_cost_weights: &RewardCostWeights,
        metric: String
    ): bool {
        let reward_cost_weight = RewardCostWeight {
            metric
        };

        df::exists_with_type<RewardCostWeight, u64>(
            &reward_cost_weights.id,
            reward_cost_weight
        )
    }

    public fun get_end(
        reward_cost_weights: &RewardCostWeights
    ): u64 {
        reward_cost_weights.end
    }

    public fun get_start(
        reward_cost_weights: &RewardCostWeights
    ): u64 {
        reward_cost_weights.start
    }

    public fun get_weight(
        reward_cost_weights: &RewardCostWeights,
        metric: String
    ): u64 {
        let does_exist = field_exists(
            reward_cost_weights,
            metric
        );

        if (does_exist) {
            let reward_cost_weight = RewardCostWeight {
                metric
            };

            *df::borrow<RewardCostWeight, u64>(
                &reward_cost_weights.id,
                reward_cost_weight
            )
        } else {
            0
        }
    }

    public fun is_current(
        reward_cost_weights: &RewardCostWeights,
        timestamp: u64
    ): bool {
        timestamp <= reward_cost_weights.end &&
        timestamp >= reward_cost_weights.start
    }

    // --------------- Friend Functions ---------------

    public(package) fun add_weight(
        reward_cost_weights: &mut RewardCostWeights,
        metric: String,
        value: u64
    ) {
        let reward_cost_weight = RewardCostWeight {
            metric
        };

        df::add(
            &mut reward_cost_weights.id,
            reward_cost_weight,
            value
        );
    }

    public(package) fun complete_weights(
        reward_cost_weights: &mut RewardCostWeights,
        end: u64
    ) {
        reward_cost_weights.end = end;
    }

    public(package) fun create_weights(
        end: u64,
        start: u64,
        ctx: &mut TxContext
    ): RewardCostWeights {
        RewardCostWeights {
            id: object::new(ctx),
            end,
            start
        }
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
