module sage_analytics::analytics_actions {
    use std::{
        string::{String}
    };

    use sage_admin::{
        access::{
            Self,
            ChannelWitnessConfig,
            GroupWitnessConfig,
            UserWitnessConfig
        },
        apps::{App}
    };

    use sage_analytics::{
        analytics::{Self, Analytics}
    };

    use sage_trust::{
        access::{
            Self as trust_access,
            RewardWitnessConfig
        }
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun claim_analytics_for_reward<RewardWitness: drop>(
        analytics: &mut Analytics,
        app: &App,
        reward_witness: &RewardWitness,
        reward_witness_config: &RewardWitnessConfig
    ): u64 {
        trust_access::assert_reward_witness<RewardWitness>(
            reward_witness,
            reward_witness_config
        );

        analytics::remove_claim(
            analytics,
            object::id_address(app)
        )
    }

    public fun create_analytics_for_channel<ChannelWitness: drop>(
        channel_witness: &ChannelWitness,
        channel_witness_config: &ChannelWitnessConfig,
        ctx: &mut TxContext
    ): Analytics {
        access::assert_channel_witness<ChannelWitness>(
            channel_witness_config,
            channel_witness
        );

        analytics::create(ctx)
    }

    public fun create_analytics_for_group<GroupWitness: drop>(
        group_witness: &GroupWitness,
        group_witness_config: &GroupWitnessConfig,
        ctx: &mut TxContext
    ): Analytics {
        access::assert_group_witness<GroupWitness>(
            group_witness_config,
            group_witness
        );

        analytics::create(ctx)
    }

    public fun create_analytics_for_user<UserWitness: drop>(
        user_witness: &UserWitness,
        user_witness_config: &UserWitnessConfig,
        ctx: &mut TxContext
    ): Analytics {
        access::assert_user_witness<UserWitness>(
            user_witness_config,
            user_witness
        );

        analytics::create(ctx)
    }

    public fun increment_analytics_for_channel<ChannelWitness: drop>(
        analytics: &mut Analytics,
        app: &App,
        channel_witness: &ChannelWitness,
        channel_witness_config: &ChannelWitnessConfig,
        claim: u64,
        key: String
    ) {
        access::assert_channel_witness<ChannelWitness>(
            channel_witness_config,
            channel_witness
        );

        increment_analytics(
            analytics,
            key
        );

        if (claim > 0) {
            analytics.add_to_claim(
                object::id_address(app),
                claim
            );
        };
    }

    public fun increment_analytics_for_group<GroupWitness: drop>(
        analytics: &mut Analytics,
        app: &App,
        group_witness: &GroupWitness,
        group_witness_config: &GroupWitnessConfig,
        claim: u64,
        key: String
    ) {
        access::assert_group_witness<GroupWitness>(
            group_witness_config,
            group_witness
        );

        increment_analytics(
            analytics,
            key
        );

        if (claim > 0) {
            analytics.add_to_claim(
                object::id_address(app),
                claim
            );
        };
    }

    public fun increment_analytics_for_user<UserWitness: drop>(
        analytics: &mut Analytics,
        app: &App,
        user_witness: &UserWitness,
        user_witness_config: &UserWitnessConfig,
        claim: u64,
        key: String
    ) {
        access::assert_user_witness<UserWitness>(
            user_witness_config,
            user_witness
        );

        increment_analytics(
            analytics,
            key
        );

        if (claim > 0) {
            analytics.add_to_claim(
                object::id_address(app),
                claim
            );
        };
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    fun increment_analytics(
        analytics: &mut Analytics,
        key: String
    ) {
        let does_exist = analytics::field_exists(
            analytics,
            key
        );

        if (does_exist) {
            let current = analytics::remove_field(
                analytics,
                key
            );

            let next = current + 1;

            analytics::add_field(
                analytics,
                key,
                next
            );
        } else {
            analytics::add_field(
                analytics,
                key,
                1
            );
        };
    }

    // --------------- Test Functions ---------------

    #[test_only]
    public fun increment_analytics_for_testing(
        analytics: &mut Analytics,
        app_address: address,
        claim: u64,
        key: String
    ) {
        increment_analytics(analytics, key);

        if (claim > 0) {
            analytics.add_to_claim(
                app_address,
                claim
            );
        };
    }
}
