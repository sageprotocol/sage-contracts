module sage_channel::channel_actions {
    use std::string::{String, utf8};

    use sui::{
        clock::Clock,
        coin::{Coin},
        event,
        sui::{SUI}
    };

    use sage_admin::{
        admin::{AdminCap},
        apps::{Self, App},
        fees::{Self},
        types::{UserOwnedConfig}
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
        moderation::{Self}
    };

    use sage_user::{
        user_owned::{UserOwned},
        user_registry::{Self, UserRegistry},
        user_shared::{Self, UserShared}
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
        avatar: String,
        banner: String,
        channel_key: String,
        channel_name: String,
        created_at: u64,
        created_by: address,
        description: String
    }

    public struct ChannelFollowsUpdate has copy, drop {
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
        avatar: String,
        banner: String,
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
        shared_user: &UserShared,
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

        let user_address = user_shared::get_owner(
            shared_user
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

    public fun create<CoinType> (
        channel_fees: &ChannelFees,
        channel_registry: &mut ChannelRegistry,
        clock: &Clock,
        _: &UserOwned,
        avatar: String,
        banner: String,
        description: String,
        name: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext,
    ): address {
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

        let mut follows = membership::create(ctx);
        let (
            moderators,
            moderation_message,
            moderation_type
        ) = moderation::create(ctx);

        let (
            membership_message,
            membership_type
        ) = membership::wallet_join(
            &mut follows,
            self
        );

        let channel_address = channel::create(
            avatar,
            banner,
            description,
            created_at,
            self,
            follows,
            channel_key,
            moderators,
            name,
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
            avatar,
            banner,
            channel_key,
            channel_name: name,
            created_at,
            created_by: self,
            description
        });

        event::emit(ChannelFollowsUpdate {
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

    public fun follow<CoinType> (
        channel: &mut Channel,
        channel_fees: &ChannelFees,
        clock: &Clock,
        _: &UserOwned,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let self = tx_context::sender(ctx);

        let (
            custom_payment,
            sui_payment
        ) = channel_fees::assert_join_channel_payment<CoinType>(
            channel_fees,
            custom_payment,
            sui_payment
        );

        let membership = channel::borrow_follows_mut(
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

        event::emit(ChannelFollowsUpdate {
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

    public fun post<CoinType> (
        app: &App,
        channel: &mut Channel,
        channel_fees: &ChannelFees,
        clock: &Clock,
        owned_user: &UserOwned,
        owned_user_config: &UserOwnedConfig,
        data: String,
        description: String,
        title: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ): (address, u64) {
        let self = tx_context::sender(ctx);

        let follows = channel::borrow_follows_mut(
            channel
        );

        membership::assert_is_member(
            follows,
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

        let (
            posts_key,
            app_name
        ) = apps::create_app_specific_string(
            app,
            utf8(b"posts")
        );

        let mut posts = channel::take_posts(
            channel,
            posts_key,
            ctx
        );

        let (
            post_address,
            _self,
            timestamp
        ) = post_actions::create<UserOwned>(
            clock,
            owned_user,
            owned_user_config,
            &mut posts,
            data,
            description,
            title,
            ctx
        );

        channel::return_posts(
            channel,
            posts,
            posts_key
        );

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );

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
        shared_user: &UserShared,
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

        let user_address = user_shared::get_owner(
            shared_user
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

    public fun unfollow<CoinType> (
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

        let membership = channel::borrow_follows_mut(
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

        event::emit(ChannelFollowsUpdate {
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

    public fun update_as_admin (
        _: &AdminCap,
        channel: &mut Channel,
        clock: &Clock,
        avatar: String,
        banner: String,
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
            avatar,
            banner,
            description,
            name,
            updated_at
        );

        event::emit(ChannelUpdated {
            avatar,
            banner,
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
        avatar: String,
        banner: String,
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
            avatar,
            banner,
            description,
            name,
            updated_at
        );

        event::emit(ChannelUpdated {
            avatar,
            banner,
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
