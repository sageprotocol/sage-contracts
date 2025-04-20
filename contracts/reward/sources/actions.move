module sage_reward::reward_actions {
    use std::{
        string::{String}
    };

    use sui::{
        clock::Clock,
        dynamic_field::{Self as df}
    };

    use sage_admin::{
        access::{
            Self as admin_access,
            ChannelWitnessConfig,
            GroupWitnessConfig,
            UserWitnessConfig
        },
        admin::{RewardCap}
    };

    // use sage_analytics::{};

    use sage_reward::{
        reward::{Self},
        reward_registry::{Self, RewardWeightsRegistry},
    };

    use sage_trust::{
        access::{Self as trust_access, TrustConfig},
        trust::{TRUST}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const ERewardsAlreadyStarted: u64 = 370;

    // --------------- Name Tag ---------------

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun claim_for_user() {}

    public fun complete_epoch(
        _: &RewardCap,
        clock: &Clock,
        reward_registry: &mut RewardWeightsRegistry
    ) {
        let timestamp = clock.timestamp_ms();

        let old_weights = reward_registry.borrow_current_mut();

        reward::complete_weights(
            old_weights,
            timestamp
        );

        let reward_weights = reward::create_weights(
            0,
            timestamp
        );

        reward_registry.add(
            reward_weights,
            timestamp
        );
    }

    public fun start_epochs(
        _: &RewardCap,
        clock: &Clock,
        reward_registry: &mut RewardWeightsRegistry
    ) {
        let length = reward_registry.get_length();

        assert!(length == 0, ERewardsAlreadyStarted);

        let timestamp = clock.timestamp_ms();

        let reward_weights = reward::create_weights(
            0,
            timestamp
        );

        reward_registry.add(
            reward_weights,
            timestamp
        );
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
