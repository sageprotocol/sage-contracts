module sage_channel::channel_actions {
    use std::string::{String};

    use sui::{
        clock::Clock,
        coin::{Coin},
        event,
        sui::{SUI}
    };

    use sage_admin::{
        admin::{AdminCap},
        apps::{Self, App},
        authentication::{Self, AuthenticationConfig},
        fees::{Self}
    };

    use sage_channel::{
        channel::{Self, Channel},
        channel_fees::{Self, ChannelFees},
        channel_registry::{Self, ChannelRegistry}
    };

    use sage_post::{
        post_actions::{Self}
    };

    use sage_shared::{
        membership::{Self},
        moderation::{Self},
        posts::{Self}
    };

    use sage_user::{
        user::{Self, User},
        user_registry::{Self, UserRegistry}
    };

    use sage_utils::{
        string_helpers::{Self}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EChannelNameMismatch: u64 = 370;

    // --------------- Name Tag ---------------

    // --------------- Events ---------------

    public struct ChannelCreated has copy, drop {
        id: address,
        avatar_hash: String,
        banner_hash: String,
        channel_key: String,
        channel_name: String,
        created_at: u64,
        created_by: address,
        description: String
    }

    public struct ChannelMembershipUpdate has copy, drop {
        account_type: u8,
        channel_key: String,
        message: u8,
        updated_at: u64,
        user: address
    }

    public struct ChannelModerationUpdate has copy, drop {
        channel_key: String,
        message: u8,
        moderator_type: u8,
        updated_at: u64,
        user: address
    }

    public struct ChannelPostCreated has copy, drop {
        id: address,
        app: String,
        channel_key: String,
        created_at: u64,
        created_by: address,
        data: String,
        description: String,
        title: String
    }

    public struct ChannelUpdated has copy, drop {
        avatar_hash: String,
        banner_hash: String,
        channel_key: String,
        channel_name: String,
        description: String,
        updated_at: u64
    }

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun add_moderator_as_admin (
        _: &AdminCap,
        channel: &mut Channel,
        clock: &Clock,
        user_registry: &UserRegistry,
        user_key: String
    ) {
        let user_address = user_registry::get_owner_address_from_key(
            user_registry,
            user_key
        );

        let moderation = channel::borrow_moderators_mut(
            channel
        );

        let (
            message,
            moderator_type
        ) = moderation::make_moderator(
            moderation,
            user_address
        );

        let channel_key = channel::get_key(channel);
        let updated_at = clock.timestamp_ms();

        event::emit(ChannelModerationUpdate {
            channel_key,
            message,
            moderator_type,
            updated_at,
            user: user_address
        });
    }

    public fun add_moderator_as_owner<CoinType> (
        channel: &mut Channel,
        channel_fees: &ChannelFees,
        clock: &Clock,
        user: &User,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let self = tx_context::sender(ctx);

        let moderation = channel::borrow_moderators_mut(
            channel
        );

        moderation::assert_is_owner(
            moderation,
            self
        );

        let (
            custom_payment,
            sui_payment
        ) = channel_fees::assert_add_moderator_owner_payment<CoinType>(
            channel_fees,
            custom_payment,
            sui_payment
        );

        let user_address = user::get_owner(
            user
        );

        let (
            message,
            moderator_type
        ) = moderation::make_moderator(
            moderation,
            user_address
        );

        let channel_key = channel::get_key(channel);
        let updated_at = clock.timestamp_ms();

        event::emit(ChannelModerationUpdate {
            channel_key,
            message,
            moderator_type,
            updated_at,
            user: user_address
        });

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );
    }

    public fun create<CoinType, SoulType: key> (
        authentication_config: &AuthenticationConfig,
        channel_fees: &ChannelFees,
        channel_registry: &mut ChannelRegistry,
        clock: &Clock,
        soul: &SoulType,
        avatar_hash: String,
        banner_hash: String,
        description: String,
        name: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext,
    ): address {
        authentication::assert_authentication<SoulType>(
            authentication_config,
            soul
        );

        let (
            custom_payment,
            sui_payment
        ) = channel_fees::assert_create_channel_payment<CoinType>(
            channel_fees,
            custom_payment,
            sui_payment
        );

        let created_at = clock.timestamp_ms();
        let self = tx_context::sender(ctx);

        let channel_key = string_helpers::to_lowercase(
            &name
        );

        let mut members = membership::create(ctx);
        let (
            moderators,
            moderation_message,
            moderation_type
        ) = moderation::create(ctx);
        let posts = posts::create(ctx);

        let (
            membership_message,
            membership_type
        ) = membership::wallet_join(
            &mut members,
            self
        );

        let channel_address = channel::create(
            avatar_hash,
            banner_hash,
            description,
            created_at,
            self,
            channel_key,
            members,
            moderators,
            name,
            posts,
            ctx
        );

        channel_registry::add(
            channel_registry,
            channel_key,
            channel_address
        );

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );

        event::emit(ChannelCreated {
            id: channel_address,
            avatar_hash,
            banner_hash,
            channel_key,
            channel_name: name,
            created_at,
            created_by: self,
            description
        });

        event::emit(ChannelMembershipUpdate {
            account_type: membership_type,
            channel_key,
            message: membership_message,
            updated_at: created_at,
            user: self
        });

        event::emit(ChannelModerationUpdate {
            channel_key,
            message: moderation_message,
            moderator_type: moderation_type,
            updated_at: created_at,
            user: self
        });

        channel_address
    }

    public fun join<CoinType, SoulType: key> (
        authentication_config: &AuthenticationConfig,
        channel: &mut Channel,
        channel_fees: &ChannelFees,
        clock: &Clock,
        soul: &SoulType,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        authentication::assert_authentication<SoulType>(
            authentication_config,
            soul
        );

        let self = tx_context::sender(ctx);

        let (
            custom_payment,
            sui_payment
        ) = channel_fees::assert_join_channel_payment<CoinType>(
            channel_fees,
            custom_payment,
            sui_payment
        );

        let membership = channel::borrow_members_mut(
            channel
        );

        let (
            message,
            account_type
        ) = membership::wallet_join(
            membership,
            self
        );

        let channel_key = channel::get_key(channel);
        let updated_at = clock.timestamp_ms();

        event::emit(ChannelMembershipUpdate {
            account_type,
            channel_key,
            message,
            updated_at,
            user: self
        });

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );
    }

    public fun leave<CoinType> (
        channel: &mut Channel,
        channel_fees: &ChannelFees,
        clock: &Clock,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let (
            custom_payment,
            sui_payment
        ) = channel_fees::assert_leave_channel_payment<CoinType>(
            channel_fees,
            custom_payment,
            sui_payment
        );

        let self = tx_context::sender(ctx);

        let membership = channel::borrow_members_mut(
            channel
        );

        let (
            message,
            account_type
        ) = membership::wallet_leave(
            membership,
            self
        );

        let channel_key = channel::get_key(channel);
        let updated_at = clock.timestamp_ms();

        event::emit(ChannelMembershipUpdate {
            account_type,
            channel_key,
            message,
            updated_at,
            user: self
        });

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );
    }

    public fun post<CoinType, SoulType: key> (
        app: &App,
        authentication_config: &AuthenticationConfig,
        channel: &mut Channel,
        channel_fees: &ChannelFees,
        clock: &Clock,
        soul: &SoulType,
        data: String,
        description: String,
        title: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ): (address, u64) {
        let self = tx_context::sender(ctx);

        let membership = channel::borrow_members_mut(
            channel
        );

        membership::assert_is_member(
            membership,
            self
        );

        let (
            custom_payment,
            sui_payment
        ) = channel_fees::assert_post_to_channel_payment<CoinType>(
            channel_fees,
            custom_payment,
            sui_payment
        );

        let posts = channel::borrow_posts_mut(channel);

        let (
            post_address,
            _self,
            timestamp
        ) = post_actions::create<SoulType>(
            authentication_config,
            clock,
            posts,
            soul,
            data,
            description,
            title,
            ctx
        );

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );

        let app_name = apps::get_name(app);
        let channel_key = channel::get_key(channel);

        event::emit(ChannelPostCreated {
            id: post_address,
            app: app_name,
            channel_key,
            created_at: timestamp,
            created_by: self,
            data,
            description,
            title
        });

        (post_address, timestamp)
    }

    public fun remove_moderator_as_admin (
        _: &AdminCap,
        channel: &mut Channel,
        clock: &Clock,
        user_registry: &UserRegistry,
        user_key: String
    ) {
        let user_address = user_registry::get_owner_address_from_key(
            user_registry,
            user_key
        );

        let moderation = channel::borrow_moderators_mut(
            channel
        );

        let (
            message,
            moderator_type
        ) = moderation::remove_moderator(
            moderation,
            user_address
        );

        let channel_key = channel::get_key(channel);
        let updated_at = clock.timestamp_ms();

        event::emit(ChannelModerationUpdate {
            channel_key,
            message,
            moderator_type,
            updated_at,
            user: user_address
        });
    }

    public fun remove_moderator_as_owner<CoinType> (
        channel: &mut Channel,
        channel_fees: &ChannelFees,
        clock: &Clock,
        user: &User,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let self = tx_context::sender(ctx);

        let moderation = channel::borrow_moderators_mut(
            channel
        );

        moderation::assert_is_owner(
            moderation,
            self
        );

        let (
            custom_payment,
            sui_payment
        ) = channel_fees::assert_remove_moderator_owner_payment<CoinType>(
            channel_fees,
            custom_payment,
            sui_payment
        );

        let user_address = user::get_owner(
            user
        );

        let (
            message,
            moderator_type
        ) = moderation::remove_moderator(
            moderation,
            user_address
        );

        let channel_key = channel::get_key(channel);
        let updated_at = clock.timestamp_ms();

        event::emit(ChannelModerationUpdate {
            channel_key,
            message,
            moderator_type,
            updated_at,
            user: user_address
        });

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );
    }

    public fun update_as_admin (
        _: &AdminCap,
        channel: &mut Channel,
        clock: &Clock,
        avatar_hash: String,
        banner_hash: String,
        description: String,
        name: String
    ) {
        let channel_key = assert_name_sameness(
            channel,
            name
        );
        
        let updated_at = clock.timestamp_ms();

        channel::update(
            channel,
            avatar_hash,
            banner_hash,
            description,
            name,
            updated_at
        );

        event::emit(ChannelUpdated {
            avatar_hash,
            banner_hash,
            channel_key,
            channel_name: name,
            description,
            updated_at
        });
    }

    public fun update_as_owner<CoinType> (
        channel: &mut Channel,
        channel_fees: &ChannelFees,
        clock: &Clock,
        avatar_hash: String,
        banner_hash: String,
        description: String,
        name: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let self = tx_context::sender(ctx);

        let moderation = channel::borrow_moderators_mut(channel);

        moderation::assert_is_moderator(
            moderation,
            self
        );

        let channel_key = assert_name_sameness(
            channel,
            name
        );

        let (
            custom_payment,
            sui_payment
        ) = channel_fees::assert_update_channel_payment<CoinType>(
            channel_fees,
            custom_payment,
            sui_payment
        );        

        let updated_at = clock.timestamp_ms();

        channel::update(
            channel,
            avatar_hash,
            banner_hash,
            description,
            name,
            updated_at
        );

        event::emit(ChannelUpdated {
            avatar_hash,
            banner_hash,
            channel_key,
            channel_name: name,
            description,
            updated_at
        });

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    fun assert_name_sameness(
        channel: &Channel,
        new_name: String
    ): String {
        let lowercase_channel_name = string_helpers::to_lowercase(
            &new_name
        );

        let channel_key = channel::get_key(channel);

        assert!(lowercase_channel_name == channel_key, EChannelNameMismatch);

        channel_key
    }

    // --------------- Test Functions ---------------
    
}
