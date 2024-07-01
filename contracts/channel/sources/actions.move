module sage_channel::channel_actions {
    use std::string::{String};

    use sui::clock::Clock;

    use sage_admin::{admin::{UpdateCap}};

    use sage_channel::{
        channel::{Self, Channel},
        channel_membership::{Self, ChannelMembershipRegistry},
        channel_registry::{Self, ChannelRegistry}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun create(
        clock: &Clock,
        channel_registry: &mut ChannelRegistry,
        channel_membership_registry: &mut ChannelMembershipRegistry,
        channel_name: String,
        avatar_hash: String,
        banner_hash: String,
        description: String,
        ctx: &mut TxContext,
    ): Channel {
        let created_at = clock.timestamp_ms();
        let created_by = tx_context::sender(ctx);

        let channel = channel::create(
            channel_name,
            avatar_hash,
            banner_hash,
            description,
            created_at,
            created_by
        );

        channel_registry::add(
            channel_registry,
            channel_name,
            channel
        );

        channel_membership::create(
            channel_membership_registry,
            channel,
            ctx
        );

        channel
    }

    public fun update_avatar_admin (
        _: &UpdateCap,
        channel_name: String,
        channel: &mut Channel,
        hash: String
    ) {
        channel::update_avatar(
            channel_name,
            channel,
            hash
        );
    }

    public fun update_banner_admin (
        _: &UpdateCap,
        channel_name: String,
        channel: &mut Channel,
        hash: String
    ) {
        channel::update_banner(
            channel_name,
            channel,
            hash
        );
    }

    public fun update_description_admin (
        _: &UpdateCap,
        channel_name: String,
        channel: &mut Channel,
        description: String
    ) {
        channel::update_description(
            channel_name,
            channel,
            description
        );
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
    
}
