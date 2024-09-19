module sage_channel::channel_actions {
    use std::string::{String};

    use sui::clock::Clock;

    use sage_admin::{admin::{AdminCap}};

    use sage_channel::{
        channel::{Self, Channel},
        channel_membership::{Self, ChannelMembershipRegistry},
        channel_registry::{Self, ChannelRegistry}
    };

    use sage_user::{
        user_registry::{Self, UserRegistry}
    };

    use sage_utils::{
        string_helpers::{Self}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EChannelNameMismatch: u64 = 370;
    const ENotChannelOwner: u64 = 371;
    const EUserDoesNotExist: u64 = 372;

    // --------------- Name Tag ---------------

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun create(
        clock: &Clock,
        channel_registry: &mut ChannelRegistry,
        channel_membership_registry: &mut ChannelMembershipRegistry,
        user_registry: &mut UserRegistry,
        channel_name: String,
        avatar_hash: String,
        banner_hash: String,
        description: String,
        ctx: &mut TxContext,
    ): Channel {
        let self = tx_context::sender(ctx);

        let user_exists = user_registry::has_address_record(
            user_registry,
            self
        );

        assert!(user_exists, EUserDoesNotExist);

        let created_at = clock.timestamp_ms();
        let created_by = tx_context::sender(ctx);

        let channel_key = string_helpers::to_lowercase(
            &channel_name
        );

        let channel = channel::create(
            channel_key,
            channel_name,
            avatar_hash,
            banner_hash,
            description,
            created_at,
            created_by
        );

        channel_membership::create(
            channel_membership_registry,
            channel,
            ctx
        );

        channel_registry::add(
            channel_registry,
            channel_key,
            channel
        );

        channel
    }

    public fun join(
        channel_registry: &mut ChannelRegistry,
        channel_membership_registry: &mut ChannelMembershipRegistry,
        user_registry: &mut UserRegistry,
        channel_key: String,
        ctx: &mut TxContext
    ) {
        let self = tx_context::sender(ctx);

        let user_exists = user_registry::has_address_record(
            user_registry,
            self
        );

        assert!(user_exists, EUserDoesNotExist);

        let channel = channel_registry::borrow_channel(
            channel_registry,
            channel_key
        );

        let channel_membership = channel_membership::borrow_membership_mut(
            channel_membership_registry,
            channel
        );

        channel_membership::join(
            channel_membership,
            channel_key,
            ctx
        );
    }

    public fun leave(
        channel_registry: &mut ChannelRegistry,
        channel_membership_registry: &mut ChannelMembershipRegistry,
        user_registry: &mut UserRegistry,
        channel_key: String,
        ctx: &mut TxContext
    ) {
        let self = tx_context::sender(ctx);

        let user_exists = user_registry::has_address_record(
            user_registry,
            self
        );

        assert!(user_exists, EUserDoesNotExist);

        let channel = channel_registry::borrow_channel(
            channel_registry,
            channel_key
        );

        let channel_membership = channel_membership::borrow_membership_mut(
            channel_membership_registry,
            channel
        );

        channel_membership::leave(
            channel_membership,
            channel_key,
            ctx
        );
    }

    public fun update_avatar_admin (
        _: &AdminCap,
        clock: &Clock,
        channel_registry: &mut ChannelRegistry,
        channel_key: String,
        avatar_hash: String
    ) {
        let mut channel = channel_registry::borrow_channel(
            channel_registry,
            channel_key
        );
        
        let updated_at = clock.timestamp_ms();

        let channel = channel::update_avatar(
            channel_key,
            &mut channel,
            avatar_hash,
            updated_at
        );

        channel_registry::replace(
            channel_registry,
            channel_key,
            channel
        );
    }

    public fun update_banner_admin (
        _: &AdminCap,
        clock: &Clock,
        channel_registry: &mut ChannelRegistry,
        channel_key: String,
        banner_hash: String
    ) {
        let mut channel = channel_registry::borrow_channel(
            channel_registry,
            channel_key
        );

        let updated_at = clock.timestamp_ms();

        let channel = channel::update_banner(
            channel_key,
            &mut channel,
            banner_hash,
            updated_at
        );

        channel_registry::replace(
            channel_registry,
            channel_key,
            channel
        );
    }

    public fun update_description_admin (
        _: &AdminCap,
        clock: &Clock,
        channel_registry: &mut ChannelRegistry,
        channel_key: String,
        description: String
    ) {
        let mut channel = channel_registry::borrow_channel(
            channel_registry,
            channel_key
        );

        let updated_at = clock.timestamp_ms();

        let channel = channel::update_description(
            channel_key,
            &mut channel,
            description,
            updated_at
        );

        channel_registry::replace(
            channel_registry,
            channel_key,
            channel
        );
    }

    public fun update_name_admin (
        _: &AdminCap,
        clock: &Clock,
        channel_registry: &mut ChannelRegistry,
        channel_key: String,
        channel_name: String
    ) {
        let mut channel = channel_registry::borrow_channel(
            channel_registry,
            channel_key
        );

        let lowercase_channel_name = string_helpers::to_lowercase(
            &channel_name
        );

        assert!(lowercase_channel_name == channel_key, EChannelNameMismatch);

        let updated_at = clock.timestamp_ms();

        let channel = channel::update_name(
            channel_key,
            &mut channel,
            channel_name,
            updated_at
        );

        channel_registry::replace(
            channel_registry,
            channel_key,
            channel
        );
    }

    public fun update_avatar_owner (
        clock: &Clock,
        channel_registry: &mut ChannelRegistry,
        channel_key: String,
        avatar_hash: String,
        ctx: &mut TxContext
    ) {
        let mut channel = channel_registry::borrow_channel(
            channel_registry,
            channel_key
        );

        let created_by = channel::get_created_by(channel);
        let self = tx_context::sender(ctx);

        assert!(self == created_by, ENotChannelOwner);

        let updated_at = clock.timestamp_ms();

        let channel = channel::update_avatar(
            channel_key,
            &mut channel,
            avatar_hash,
            updated_at
        );

        channel_registry::replace(
            channel_registry,
            channel_key,
            channel
        );
    }

    public fun update_banner_owner (
        clock: &Clock,
        channel_registry: &mut ChannelRegistry,
        channel_key: String,
        banner_hash: String,
        ctx: &mut TxContext
    ) {
        let mut channel = channel_registry::borrow_channel(
            channel_registry,
            channel_key
        );

        let created_by = channel::get_created_by(channel);
        let self = tx_context::sender(ctx);

        assert!(self == created_by, ENotChannelOwner);

        let updated_at = clock.timestamp_ms();

        let channel = channel::update_banner(
            channel_key,
            &mut channel,
            banner_hash,
            updated_at
        );

        channel_registry::replace(
            channel_registry,
            channel_key,
            channel
        );
    }

    public fun update_description_owner (
        clock: &Clock,
        channel_registry: &mut ChannelRegistry,
        channel_key: String,
        description: String,
        ctx: &mut TxContext
    ) {
        let mut channel = channel_registry::borrow_channel(
            channel_registry,
            channel_key
        );

        let created_by = channel::get_created_by(channel);
        let self = tx_context::sender(ctx);

        assert!(self == created_by, ENotChannelOwner);

        let updated_at = clock.timestamp_ms();

        let channel = channel::update_description(
            channel_key,
            &mut channel,
            description,
            updated_at
        );

        channel_registry::replace(
            channel_registry,
            channel_key,
            channel
        );
    }

    public fun update_name_owner (
        clock: &Clock,
        channel_registry: &mut ChannelRegistry,
        channel_key: String,
        channel_name: String,
        ctx: &mut TxContext
    ) {
        let mut channel = channel_registry::borrow_channel(
            channel_registry,
            channel_key
        );

        let created_by = channel::get_created_by(channel);
        let self = tx_context::sender(ctx);

        assert!(self == created_by, ENotChannelOwner);

        let lowercase_channel_name = string_helpers::to_lowercase(
            &channel_name
        );

        assert!(lowercase_channel_name == channel_key, EChannelNameMismatch);

        let updated_at = clock.timestamp_ms();

        let channel = channel::update_name(
            channel_key,
            &mut channel,
            channel_name,
            updated_at
        );

        channel_registry::replace(
            channel_registry,
            channel_key,
            channel
        );
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
    
}
