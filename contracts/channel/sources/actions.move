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
        channel_membership::{
            Self,
            ChannelMembership,
            ChannelMembershipRegistry
        },
        channel_moderation::{
            Self,
            ChannelModeration,
            ChannelModerationRegistry
        },
        channel_registry::{Self, ChannelRegistry}
    };

    use sage_user::{
        user_registry::{Self, UserRegistry}
    };

    use sage_utils::{
        string_helpers::{Self}
    };

    // --------------- Constants ---------------

    const MIN_NUM_MODERATORS: u64 = 1;

    const CHANNEL_JOIN: u8 = 10;
    const CHANNEL_LEAVE: u8 = 11;

    const MODERATOR_ADD: u8 = 10;
    const MODERATOR_REMOVE: u8 = 11;

    // --------------- Errors ---------------

    const EAlreadyChannelModerator: u64 = 370;
    const EChannelMembershipMismatch: u64 = 371;
    const EChannelModeratorLength: u64 = 372;
    const EChannelModerationMismatch: u64 = 373;
    const EChannelNameMismatch: u64 = 374;
    const ENotChannelOwner: u64 = 375;
    const EUserDoesNotExist: u64 = 376;

    // --------------- Name Tag ---------------

    // --------------- Events ---------------

    public struct ChannelCreated has copy, drop {
        channel_address: address,
        channel_membership_address: address,
        channel_moderation_address: address,
        avatar_hash: String,
        banner_hash: String,
        channel_name: String,
        created_at: u64,
        created_by: address,
        description: String
    }

    public struct ChannelUpdated has copy, drop {
        avatar_hash: String,
        banner_hash: String,
        channel_key: String,
        channel_name: String,
        description: String,
        updated_at: u64
    }

    public struct ChannelMembershipUpdate has copy, drop {
        channel_key: String,
        message: u8,
        user: address
    }

    public struct ChannelModerationUpdate has copy, drop {
        channel_key: String,
        message: u8,
        user: address
    }

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun add_moderator_as_admin (
        _: &AdminCap,
        channel_moderation: &mut ChannelModeration,
        user_registry: &UserRegistry,
        user_key: String
    ) {
        let user_address = user_registry::get_owner_address_from_key(
            user_registry,
            user_key
        );

        let is_moderator = channel_moderation::is_moderator(
            channel_moderation,
            user_address
        );

        assert!(!is_moderator, EAlreadyChannelModerator);

        channel_moderation.add(user_address);

        // let channel_key = 

        // event::emit(ChannelModerationUpdate {
        //     channel_key,
        //     message: MODERATOR_ADD,
        //     user: user_address
        // });
    }

    public fun add_moderator_as_owner<CoinType> (
        channel_moderation_registry: &ChannelModerationRegistry,
        user_registry: &UserRegistry,
        channel: &Channel,
        channel_moderation: &mut ChannelModeration,
        channel_fees: &ChannelFees,
        user_key: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let created_by = channel::get_created_by(channel);
        let self = tx_context::sender(ctx);

        assert!(self == created_by, ENotChannelOwner);

        let (
            custom_payment,
            sui_payment
        ) = channel_fees::assert_add_moderator_owner_payment<CoinType>(
            channel_fees,
            custom_payment,
            sui_payment
        );

        let channel_name = channel::get_name(channel);
        let channel_key = string_helpers::to_lowercase(
            &channel_name
        );

        let moderation_address = channel_moderation::get_address(channel_moderation);
        let expected_moderation_address = channel_moderation::borrow_moderation_address(
            channel_moderation_registry,
            channel_key
        );

        assert!(moderation_address == expected_moderation_address, EChannelModerationMismatch);

        let user_address = user_registry::get_owner_address_from_key(
            user_registry,
            user_key
        );

        let is_moderator = channel_moderation::is_moderator(
            channel_moderation,
            user_address
        );

        assert!(!is_moderator, EAlreadyChannelModerator);

        channel_moderation.add(user_address);

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );

        event::emit(ChannelModerationUpdate {
            channel_key,
            message: MODERATOR_ADD,
            user: user_address
        });
    }

    public fun create<CoinType> (
        clock: &Clock,
        channel_registry: &mut ChannelRegistry,
        channel_membership_registry: &mut ChannelMembershipRegistry,
        channel_moderation_registry: &mut ChannelModerationRegistry,
        user_registry: &UserRegistry,
        channel_fees: &ChannelFees,
        channel_name: String,
        avatar_hash: String,
        banner_hash: String,
        description: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext,
    ): address {
        let self = tx_context::sender(ctx);

        let user_exists = user_registry::has_address_record(
            user_registry,
            self
        );

        assert!(user_exists, EUserDoesNotExist);

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
            &channel_name
        );

        let channel_address = channel::create(
            channel_name,
            avatar_hash,
            banner_hash,
            description,
            created_at,
            created_by,
            ctx
        );

        let channel_membership_address = channel_membership::create(
            channel_membership_registry,
            channel_key,
            ctx
        );

        let channel_moderation_address = channel_moderation::create(
            channel_moderation_registry,
            channel_key,
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
            channel_address,
            channel_membership_address,
            channel_moderation_address,
            avatar_hash,
            banner_hash,
            channel_name,
            created_at,
            created_by,
            description
        });

        event::emit(ChannelMembershipUpdate {
            channel_key,
            message: CHANNEL_JOIN,
            user: self
        });

        event::emit(ChannelModerationUpdate {
            channel_key,
            message: MODERATOR_ADD,
            user: self
        });

        channel_address
    }

    public fun join<CoinType> (
        channel_membership_registry: &ChannelMembershipRegistry,
        user_registry: &UserRegistry,
        channel: &Channel,
        channel_membership: &mut ChannelMembership,
        channel_fees: &ChannelFees,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let self = tx_context::sender(ctx);

        let user_exists = user_registry::has_address_record(
            user_registry,
            self
        );

        assert!(user_exists, EUserDoesNotExist);

        let (
            custom_payment,
            sui_payment
        ) = channel_fees::assert_join_channel_payment<CoinType>(
            channel_fees,
            custom_payment,
            sui_payment
        );

        let channel_name = channel::get_name(channel);
        let channel_key = string_helpers::to_lowercase(
            &channel_name
        );

        let membership_address = channel_membership::get_address(
            channel_membership
        );
        let expected_membership_address = channel_membership::borrow_membership_address(
            channel_membership_registry,
            channel_key
        );

        assert!(membership_address == expected_membership_address, EChannelMembershipMismatch);

        channel_membership::join(
            channel_membership,
            self
        );

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );

        event::emit(ChannelMembershipUpdate {
            channel_key,
            message: CHANNEL_JOIN,
            user: self
        });
    }

    public fun leave<CoinType> (
        channel_membership_registry: &ChannelMembershipRegistry,
        channel: &Channel,
        channel_membership: &mut ChannelMembership,
        channel_fees: &ChannelFees,
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

        let channel_name = channel::get_name(channel);
        let channel_key = string_helpers::to_lowercase(
            &channel_name
        );

        let membership_address = channel_membership::get_address(
            channel_membership
        );
        let expected_membership_address = channel_membership::borrow_membership_address(
            channel_membership_registry,
            channel_key
        );

        assert!(membership_address == expected_membership_address, EChannelMembershipMismatch);

        let self = tx_context::sender(ctx);

        channel_membership::leave(
            channel_membership,
            self
        );

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );

        event::emit(ChannelMembershipUpdate {
            channel_key,
            message: CHANNEL_LEAVE,
            user: self
        });
    }

    public fun remove_moderator_as_admin (
        _: &AdminCap,
        channel_moderation: &mut ChannelModeration,
        user_registry: &UserRegistry,
        user_key: String
    ) {
        let length = channel_moderation.get_moderator_length();

        assert!(length - 1 >= MIN_NUM_MODERATORS, EChannelModeratorLength);

        let user_address = user_registry::get_owner_address_from_key(
            user_registry,
            user_key
        );

        channel_moderation.remove(user_address);

        // event::emit(ChannelModerationUpdate {
        //     channel_key,
        //     message: MODERATOR_REMOVE,
        //     user: user_address
        // });
    }

    public fun remove_moderator_as_owner<CoinType> (
        channel_moderation_registry: &ChannelModerationRegistry,
        user_registry: &UserRegistry,
        channel: &Channel,
        channel_moderation: &mut ChannelModeration,
        channel_fees: &ChannelFees,
        user_key: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let created_by = channel::get_created_by(channel);
        let self = tx_context::sender(ctx);

        assert!(self == created_by, ENotChannelOwner);

        let length = channel_moderation.get_moderator_length();

        assert!(length - 1 >= MIN_NUM_MODERATORS, EChannelModeratorLength);

        let (
            custom_payment,
            sui_payment
        ) = channel_fees::assert_remove_moderator_owner_payment<CoinType>(
            channel_fees,
            custom_payment,
            sui_payment
        );

        let channel_name = channel::get_name(channel);
        let channel_key = string_helpers::to_lowercase(
            &channel_name
        );

        let moderation_address = channel_moderation::get_address(channel_moderation);
        let expected_moderation_address = channel_moderation::borrow_moderation_address(
            channel_moderation_registry,
            channel_key
        );

        assert!(moderation_address == expected_moderation_address, EChannelModerationMismatch);

        let user_address = user_registry::get_owner_address_from_key(
            user_registry,
            user_key
        );

        channel_moderation.remove(user_address);

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );

        event::emit(ChannelModerationUpdate {
            channel_key,
            message: MODERATOR_REMOVE,
            user: user_address
        });
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
        let channel_key = string_helpers::to_lowercase(
            &name
        );

        let existing_name = channel::get_name(
            channel
        );
        let expected_channel_key = string_helpers::to_lowercase(
            &existing_name
        );

        assert!(channel_key == expected_channel_key, EChannelNameMismatch);
        
        let updated_at = clock.timestamp_ms();

        channel::update(
            channel,
            name,
            avatar_hash,
            banner_hash,
            description,
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
        let created_by = channel::get_created_by(channel);
        let self = tx_context::sender(ctx);

        assert!(self == created_by, ENotChannelOwner);

        let (
            custom_payment,
            sui_payment
        ) = channel_fees::assert_update_channel_payment<CoinType>(
            channel_fees,
            custom_payment,
            sui_payment
        );

        let channel_key = string_helpers::to_lowercase(
            &name
        );

        let existing_name = channel::get_name(
            channel
        );
        let expected_channel_key = string_helpers::to_lowercase(
            &existing_name
        );

        assert!(channel_key == expected_channel_key, EChannelNameMismatch);

        let updated_at = clock.timestamp_ms();

        channel::update(
            channel,
            name,
            avatar_hash,
            banner_hash,
            description,
            updated_at
        );

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
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

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
    
}
