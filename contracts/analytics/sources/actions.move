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
        }
    };

    use sage_analytics::{
        analytics::{Self, Analytics}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

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

    public fun decrement_analytics_for_channel<ChannelWitness: drop>(
        analytics: &mut Analytics,
        channel_witness: &ChannelWitness,
        channel_witness_config: &ChannelWitnessConfig,
        key: String
    ) {
        access::assert_channel_witness<ChannelWitness>(
            channel_witness_config,
            channel_witness
        );

        decrement_analytics(
            analytics,
            key
        );
    }

    public fun decrement_analytics_for_group<GroupWitness: drop>(
        analytics: &mut Analytics,
        group_witness: &GroupWitness,
        group_witness_config: &GroupWitnessConfig,
        key: String
    ) {
        access::assert_group_witness<GroupWitness>(
            group_witness_config,
            group_witness
        );

        decrement_analytics(
            analytics,
            key
        );
    }

    public fun decrement_analytics_for_user<UserWitness: drop>(
        analytics: &mut Analytics,
        user_witness: &UserWitness,
        user_witness_config: &UserWitnessConfig,
        key: String
    ) {
        access::assert_user_witness<UserWitness>(
            user_witness_config,
            user_witness
        );

        decrement_analytics(
            analytics,
            key
        );
    }

    public fun increment_analytics_for_channel<ChannelWitness: drop>(
        analytics: &mut Analytics,
        channel_witness: &ChannelWitness,
        channel_witness_config: &ChannelWitnessConfig,
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
    }

    public fun increment_analytics_for_group<GroupWitness: drop>(
        analytics: &mut Analytics,
        group_witness: &GroupWitness,
        group_witness_config: &GroupWitnessConfig,
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
    }

    public fun increment_analytics_for_user<UserWitness: drop>(
        analytics: &mut Analytics,
        user_witness: &UserWitness,
        user_witness_config: &UserWitnessConfig,
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
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    fun decrement_analytics(
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

            let next = current - 1;

            analytics::add_field(
                analytics,
                key,
                next
            );
        };
    }

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
    public fun decrement_analytics_for_testing(
        analytics: &mut Analytics,
        key: String
    ) {
        decrement_analytics(analytics, key);
    }

    #[test_only]
    public fun increment_analytics_for_testing(
        analytics: &mut Analytics,
        key: String
    ) {
        increment_analytics(analytics, key);
    }
}
