module sage_reward::reward_actions {
    use std::{
        string::{String}
    };

    use sui::{
        clock::Clock,
        coin::{Coin}
    };

    use sage_admin::{
        access::{
            Self as admin_access,
            UserWitnessConfig
        },
        admin::{RewardCap},
        apps::{App}
    };

    use sage_analytics::{
        analytics::{Analytics},
        analytics_actions::{Self}
    };

    use sage_reward::{
        reward::{Self},
        reward_registry::{RewardWeightsRegistry},
        reward_witness::{Self, RewardWitness}
    };

    use sage_trust::{
        access::{
            RewardWitnessConfig
        },
        trust::{
            Self,
            MintConfig,
            ProtectedTreasury,
            TRUST
        }
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const ERewardsAlreadyStarted: u64 = 370;

    // --------------- Name Tag ---------------

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun add_weight(
        _: &RewardCap,
        reward_weights_registry: &mut RewardWeightsRegistry,
        metric: String,
        value: u64
    ) {
        let reward_weights = reward_weights_registry.borrow_current_mut();

        reward::add_weight(
            reward_weights,
            metric,
            value
        );
    }

    public fun claim_value_for_user<UserWitness: drop>(
        analytics: &mut Analytics,
        app: &App,
        mint_config: &MintConfig,
        reward_witness_config: &RewardWitnessConfig,
        treasury: &mut ProtectedTreasury,
        user_witness: &UserWitness,
        user_witness_config: &UserWitnessConfig,
        ctx: &mut TxContext
    ): (
        u64,
        Option<Coin<TRUST>>
    ) {
        admin_access::assert_user_witness<UserWitness>(
            user_witness_config,
            user_witness
        );

        claim_value(
            analytics,
            app,
            mint_config,
            reward_witness_config,
            treasury,
            ctx
        )
    }

    public fun complete_epoch(
        _: &RewardCap,
        clock: &Clock,
        reward_weights_registry: &mut RewardWeightsRegistry,
        ctx: &mut TxContext
    ) {
        let timestamp = clock.timestamp_ms();

        let old_weights = reward_weights_registry.borrow_current_mut();

        reward::complete_weights(
            old_weights,
            timestamp
        );

        let reward_weights = reward::create_weights(
            0,
            timestamp,
            ctx
        );

        reward_weights_registry.add(
            reward_weights,
            timestamp
        );
    }

    public fun start_epochs(
        _: &RewardCap,
        clock: &Clock,
        reward_weights_registry: &mut RewardWeightsRegistry,
        ctx: &mut TxContext
    ) {
        let length = reward_weights_registry.get_length();

        assert!(length == 0, ERewardsAlreadyStarted);

        let timestamp = clock.timestamp_ms();

        let reward_weights = reward::create_weights(
            0,
            timestamp,
            ctx
        );

        reward_weights_registry.add(
            reward_weights,
            timestamp
        );
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    fun claim_value(
        analytics: &mut Analytics,
        app: &App,
        mint_config: &MintConfig,
        reward_witness_config: &RewardWitnessConfig,
        treasury: &mut ProtectedTreasury,
        ctx: &mut TxContext
    ): (
        u64,
        Option<Coin<TRUST>>
    ) {
        let reward_witness = reward_witness::create_witness();

        let has_claim = analytics.claim_exists(
            object::id_address(app)
        );

        let (
            amount,
            coin_option
        ) = if (has_claim) {
            let amount = analytics_actions::claim_analytics_for_reward<RewardWitness>(
                analytics,
                app,
                &reward_witness,
                reward_witness_config
            );

            let coin = trust::mint<RewardWitness>(
                mint_config,
                &reward_witness,
                reward_witness_config,
                treasury,
                amount,
                ctx
            );

            (
                amount,
                option::some(coin)
            )
        } else {
            (
                0,
                option::none()
            )
        };

        (
            amount,
            coin_option
        )
    }

    // --------------- Test Functions ---------------

    #[test_only]
    public fun claim_value_for_testing(
        analytics: &mut Analytics,
        app: &App,
        mint_config: &MintConfig,
        reward_witness_config: &RewardWitnessConfig,
        treasury: &mut ProtectedTreasury,
        ctx: &mut TxContext
    ): (
        u64,
        Option<Coin<TRUST>>
    ) {
        claim_value(
            analytics,
            app,
            mint_config,
            reward_witness_config,
            treasury,
            ctx
        )
    }
}
