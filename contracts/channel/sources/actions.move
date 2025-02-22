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
        fees::{Self}
    };

    use sage_channel::{
        channel::{Self, Channel},
        channel_fees::{Self, ChannelFees},
        channel_membership::{Self},
        channel_moderation::{Self},
        channel_registry::{Self, ChannelRegistry}
    };

    use sage_post::{
        post_actions::{Self},
        posts::{Self}
    };

    use sage_user::{
        user_registry::{Self, UserRegistry}
    };

    use sage_utils::{
        string_helpers::{Self}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EAlreadyChannelModerator: u64 = 370;
    const EChannelModeratorLength: u64 = 371;
    const EChannelNameMismatch: u64 = 372;
    const ENotChannelModerator: u64 = 373;
    const ENotChannelOwner: u64 = 374;
    const EUserDoesNotExist: u64 = 375;

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
        user: address
    }

    public struct ChannelModerationUpdate has copy, drop {
        channel_key: String,
        message: u8,
        moderator_type: u8,
        user: address
    }

    public struct ChannelPostCreated has copy, drop {
        id: address,
        channel_key: String,
        created_at: u64,
        created_by: address,
        data: String,
        description: String,
        title: String,
        updated_at: u64
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
        user_registry: &UserRegistry,
        user_key: String
    ) {
        let user_address = user_registry::get_owner_address_from_key(
            user_registry,
            user_key
        );

        let mut channel_moderation = channel::borrow_moderators_mut(
            channel
        );

        let (
            message,
            moderator_type
        ) = channel_moderation::make_moderator(
            channel_moderation,
            user_address
        );

        let channel_key = channel::get_key(channel);

        event::emit(ChannelModerationUpdate {
            channel_key,
            message,
            moderator_type,
            user: user_address
        });
    }

    public fun add_moderator_as_owner<CoinType> (
        channel: &mut Channel,
        channel_fees: &ChannelFees,
        user_registry: &UserRegistry,
        user_key: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let self = tx_context::sender(ctx);

        let mut channel_moderation = channel::borrow_moderators_mut(
            channel
        );

        channel_moderation::assert_is_owner(
            channel_moderation,
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

        let user_address = user_registry::get_owner_address_from_key(
            user_registry,
            user_key
        );

        let (
            message,
            moderator_type
        ) = channel_moderation::make_moderator(
            channel_moderation,
            user_address
        );

        let channel_key = channel::get_key(channel);

        event::emit(ChannelModerationUpdate {
            channel_key,
            message,
            moderator_type,
            user: user_address
        });

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );
    }

    public fun create<CoinType> (
        clock: &Clock,
        channel_fees: &ChannelFees,
        channel_registry: &mut ChannelRegistry,
        user_registry: &UserRegistry,
        avatar_hash: String,
        banner_hash: String,
        description: String,
        name: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext,
    ): address {
        let self = tx_context::sender(ctx);

        user_registry::assert_user_address_exists(
            user_registry,
            self
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
        let created_by = tx_context::sender(ctx);

        let channel_key = string_helpers::to_lowercase(
            &name
        );

        let (
            members,
            membership_message,
            membership_type
        ) = channel_membership::create(ctx);
        let (
            moderators,
            moderation_message,
            moderation_type
        ) = channel_moderation::create(ctx);
        let posts = posts::create(ctx);

        let channel_address = channel::create(
            avatar_hash,
            banner_hash,
            description,
            created_at,
            created_by,
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
            created_by,
            description
        });

        event::emit(ChannelMembershipUpdate {
            account_type: membership_type,
            channel_key,
            message: membership_message,
            user: self
        });

        event::emit(ChannelModerationUpdate {
            channel_key,
            message: moderation_message,
            moderator_type: moderation_type,
            user: self
        });

        channel_address
    }

    public fun join<CoinType> (
        channel: &mut Channel,
        channel_fees: &ChannelFees,
        user_registry: &UserRegistry,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let self = tx_context::sender(ctx);

        user_registry::assert_user_address_exists(
            user_registry,
            self
        );

        let (
            custom_payment,
            sui_payment
        ) = channel_fees::assert_join_channel_payment<CoinType>(
            channel_fees,
            custom_payment,
            sui_payment
        );

        let mut channel_membership = channel::borrow_members_mut(
            channel
        );

        let (
            message,
            account_type
        ) = channel_membership::join(
            channel_membership,
            self
        );

        let channel_key = channel::get_key(channel);

        event::emit(ChannelMembershipUpdate {
            account_type,
            channel_key,
            message,
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
        user_registry: &UserRegistry,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let self = tx_context::sender(ctx);

        user_registry::assert_user_address_exists(
            user_registry,
            self
        );

        let (
            custom_payment,
            sui_payment
        ) = channel_fees::assert_leave_channel_payment<CoinType>(
            channel_fees,
            custom_payment,
            sui_payment
        );

        let mut channel_membership = channel::borrow_members_mut(
            channel
        );

        let (
            message,
            account_type
        ) = channel_membership::leave(
            channel_membership,
            self
        );

        let channel_key = channel::get_key(channel);

        event::emit(ChannelMembershipUpdate {
            account_type,
            channel_key,
            message,
            user: self
        });

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );
    }

    public fun post<CoinType> (
        clock: &Clock,
        channel: &mut Channel,
        channel_fees: &ChannelFees,
        user_registry: &UserRegistry,
        data: String,
        description: String,
        title: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ): address {
        let self = tx_context::sender(ctx);

        user_registry::assert_user_address_exists(
            user_registry,
            self
        );

        let members = channel::borrow_members_mut(channel);

        channel_membership::assert_is_member(
            members,
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
            timestamp
        ) = post_actions::create(
            clock,
            posts,
            data,
            description,
            title,
            ctx
        );

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );

        let channel_key = channel::get_key(channel);

        event::emit(ChannelPostCreated {
            id: post_address,
            channel_key,
            created_at: timestamp,
            created_by: self,
            data,
            description,
            title,
            updated_at: timestamp
        });

        post_address
    }

    public fun remove_moderator_as_admin (
        _: &AdminCap,
        channel: &mut Channel,
        user_registry: &UserRegistry,
        user_key: String
    ) {
        let user_address = user_registry::get_owner_address_from_key(
            user_registry,
            user_key
        );

        let mut channel_moderation = channel::borrow_moderators_mut(
            channel
        );

        let (
            message,
            moderator_type
        ) = channel_moderation::remove_moderator(
            channel_moderation,
            user_address
        );

        let channel_key = channel::get_key(channel);

        event::emit(ChannelModerationUpdate {
            channel_key,
            message,
            moderator_type,
            user: user_address
        });
    }

    public fun remove_moderator_as_owner<CoinType> (
        channel: &mut Channel,
        channel_fees: &ChannelFees,
        user_registry: &UserRegistry,
        user_key: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let self = tx_context::sender(ctx);

        let mut channel_moderation = channel::borrow_moderators_mut(
            channel
        );

        channel_moderation::assert_is_owner(
            channel_moderation,
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

        let user_address = user_registry::get_owner_address_from_key(
            user_registry,
            user_key
        );

        let (
            message,
            moderator_type
        ) = channel_moderation::remove_moderator(
            channel_moderation,
            user_address
        );

        let channel_key = channel::get_key(channel);

        event::emit(ChannelModerationUpdate {
            channel_key,
            message,
            moderator_type,
            user: user_address
        });

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );
    }

    public fun update_channel_as_admin (
        _: &AdminCap,
        clock: &Clock,
        channel: &mut Channel,
        avatar_hash: String,
        banner_hash: String,
        description: String,
        name: String
    ) {
        let lowercase_channel_name = string_helpers::to_lowercase(
            &name
        );

        let channel_key = channel::get_key(channel);

        assert!(lowercase_channel_name == channel_key, EChannelNameMismatch);
        
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

    public fun update_channel_as_owner<CoinType> (
        clock: &Clock,
        channel: &mut Channel,
        channel_fees: &ChannelFees,
        avatar_hash: String,
        banner_hash: String,
        description: String,
        name: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let self = tx_context::sender(ctx);

        let moderators = channel::borrow_moderators_mut(channel);

        channel_moderation::assert_is_moderator(
            moderators,
            self
        );

        let lowercase_channel_name = string_helpers::to_lowercase(
            &name
        );

        let channel_key = channel::get_key(channel);

        assert!(lowercase_channel_name == channel_key, EChannelNameMismatch);

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

    // --------------- Test Functions ---------------
    
}
