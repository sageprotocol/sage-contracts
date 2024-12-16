module sage_channel::channel_actions {
    use std::string::{String};

    use sui::{
        clock::Clock,
        coin::{Coin},
        sui::{SUI}
    };

    use sage_admin::{
        admin::{AdminCap},
        fees::{Self}
    };

    use sage_channel::{
        channel::{Self, Channel},
        channel_fees::{Self, ChannelFees},
        channel_membership::{Self, ChannelMembershipRegistry},
        channel_moderation::{Self, ChannelModerationRegistry},
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

    // --------------- Errors ---------------

    const EAlreadyChannelModerator: u64 = 370;
    const EChannelModeratorLength: u64 = 371;
    const EChannelNameMismatch: u64 = 372;
    const ENotChannelModerator: u64 = 373;
    const ENotChannelOwner: u64 = 374;
    const EUserDoesNotExist: u64 = 375;

    // --------------- Name Tag ---------------

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun add_moderator_as_admin (
        _: &AdminCap,
        channel_moderation_registry: &mut ChannelModerationRegistry,
        user_registry: &UserRegistry,
        channel_key: String,
        user_key: String
    ) {
        let address = user_registry::get_owner_address_from_key(
            user_registry,
            user_key
        );

        let is_moderator = channel_moderation::is_moderator(
            channel_moderation_registry,
            channel_key,
            address
        );

        assert!(!is_moderator, EAlreadyChannelModerator);

        let channel_moderators = channel_moderation::borrow_moderators_mut(
            channel_moderation_registry,
            channel_key
        );

        channel_moderators.push_back(address);

        channel_moderation::replace(
            channel_moderation_registry,
            channel_key,
            *channel_moderators
        );
    }

    public fun add_moderator_as_owner<CoinType> (
        channel_registry: &mut ChannelRegistry,
        channel_moderation_registry: &mut ChannelModerationRegistry,
        user_registry: &UserRegistry,
        channel_fees: &ChannelFees,
        channel_key: String,
        user_key: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let (
            custom_payment,
            sui_payment
        ) = channel_fees::assert_add_moderator_owner_payment<CoinType>(
            channel_fees,
            custom_payment,
            sui_payment
        );

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );

        let channel = channel_registry::borrow_channel(
            channel_registry,
            channel_key
        );

        let created_by = channel::get_created_by(channel);
        let self = tx_context::sender(ctx);

        assert!(self == created_by, ENotChannelOwner);

        let address = user_registry::get_owner_address_from_key(
            user_registry,
            user_key
        );

        let is_moderator = channel_moderation::is_moderator(
            channel_moderation_registry,
            channel_key,
            address
        );

        assert!(!is_moderator, EAlreadyChannelModerator);

        let channel_moderators = channel_moderation::borrow_moderators_mut(
            channel_moderation_registry,
            channel_key
        );

        channel_moderators.push_back(address);

        channel_moderation::replace(
            channel_moderation_registry,
            channel_key,
            *channel_moderators
        );
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
    ): Channel {
        let (
            custom_payment,
            sui_payment
        ) = channel_fees::assert_create_channel_payment<CoinType>(
            channel_fees,
            custom_payment,
            sui_payment
        );

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );

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
            channel_key,
            ctx
        );

        channel_moderation::create(
            channel_moderation_registry,
            channel_key,
            ctx
        );

        channel_registry::add(
            channel_registry,
            channel_key,
            channel
        );

        channel
    }

    public fun join<CoinType> (
        channel_membership_registry: &mut ChannelMembershipRegistry,
        user_registry: &UserRegistry,
        channel_fees: &ChannelFees,
        channel_key: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let (
            custom_payment,
            sui_payment
        ) = channel_fees::assert_join_channel_payment<CoinType>(
            channel_fees,
            custom_payment,
            sui_payment
        );

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );

        let self = tx_context::sender(ctx);

        let user_exists = user_registry::has_address_record(
            user_registry,
            self
        );

        assert!(user_exists, EUserDoesNotExist);

        let channel_membership = channel_membership::borrow_membership_mut(
            channel_membership_registry,
            channel_key
        );

        channel_membership::join(
            channel_membership,
            channel_key,
            ctx
        );
    }

    public fun leave<CoinType> (
        channel_membership_registry: &mut ChannelMembershipRegistry,
        user_registry: &UserRegistry,
        channel_fees: &ChannelFees,
        channel_key: String,
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

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );

        let self = tx_context::sender(ctx);

        let user_exists = user_registry::has_address_record(
            user_registry,
            self
        );

        assert!(user_exists, EUserDoesNotExist);

        let channel_membership = channel_membership::borrow_membership_mut(
            channel_membership_registry,
            channel_key
        );

        channel_membership::leave(
            channel_membership,
            channel_key,
            ctx
        );
    }

    public fun remove_moderator_as_admin (
        _: &AdminCap,
        channel_moderation_registry: &mut ChannelModerationRegistry,
        user_registry: &UserRegistry,
        channel_key: String,
        user_key: String
    ) {
        let address = user_registry::get_owner_address_from_key(
            user_registry,
            user_key
        );

        let channel_moderators = channel_moderation::borrow_moderators_mut(
            channel_moderation_registry,
            channel_key
        );

        let (is_moderator, index) = channel_moderators.index_of(&address);

        assert!(is_moderator, ENotChannelModerator);

        let length = channel_moderators.length();

        assert!(length >= MIN_NUM_MODERATORS + 1, EChannelModeratorLength);

        channel_moderators.remove(index);

        channel_moderation::replace(
            channel_moderation_registry,
            channel_key,
            *channel_moderators
        );
    }

    public fun remove_moderator_as_owner<CoinType> (
        channel_registry: &mut ChannelRegistry,
        channel_moderation_registry: &mut ChannelModerationRegistry,
        user_registry: &UserRegistry,
        channel_fees: &ChannelFees,
        channel_key: String,
        user_key: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let (
            custom_payment,
            sui_payment
        ) = channel_fees::assert_remove_moderator_owner_payment<CoinType>(
            channel_fees,
            custom_payment,
            sui_payment
        );

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );

        let channel = channel_registry::borrow_channel(
            channel_registry,
            channel_key
        );

        let created_by = channel::get_created_by(channel);
        let self = tx_context::sender(ctx);

        assert!(self == created_by, ENotChannelOwner);

        let address = user_registry::get_owner_address_from_key(
            user_registry,
            user_key
        );

        let channel_moderators = channel_moderation::borrow_moderators_mut(
            channel_moderation_registry,
            channel_key
        );

        let (is_moderator, index) = channel_moderators.index_of(&address);

        assert!(is_moderator, ENotChannelModerator);

        let length = channel_moderators.length();

        assert!(length >= MIN_NUM_MODERATORS + 1, EChannelModeratorLength);

        channel_moderators.remove(index);

        channel_moderation::replace(
            channel_moderation_registry,
            channel_key,
            *channel_moderators
        );
    }

    public fun update_channel_as_admin (
        _: &AdminCap,
        clock: &Clock,
        channel_registry: &mut ChannelRegistry,
        channel_key: String,
        avatar_hash: String,
        banner_hash: String,
        description: String,
        name: String
    ) {
        let lowercase_channel_name = string_helpers::to_lowercase(
            &name
        );

        assert!(lowercase_channel_name == channel_key, EChannelNameMismatch);

        let mut channel = channel_registry::borrow_channel(
            channel_registry,
            channel_key
        );
        
        let updated_at = clock.timestamp_ms();

        let channel = channel::update(
            &mut channel,
            channel_key,
            name,
            avatar_hash,
            banner_hash,
            description,
            updated_at
        );

        channel_registry::replace(
            channel_registry,
            channel_key,
            channel
        );
    }

    public fun update_channel_as_owner<CoinType> (
        clock: &Clock,
        channel_registry: &mut ChannelRegistry,
        channel_fees: &ChannelFees,
        channel_key: String,
        avatar_hash: String,
        banner_hash: String,
        channel_name: String,
        description: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let (
            custom_payment,
            sui_payment
        ) = channel_fees::assert_update_channel_payment<CoinType>(
            channel_fees,
            custom_payment,
            sui_payment
        );

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );

        let mut channel = channel_registry::borrow_channel(
            channel_registry,
            channel_key
        );

        let created_by = channel::get_created_by(channel);
        let self = tx_context::sender(ctx);

        assert!(self == created_by, ENotChannelModerator);

        let lowercase_channel_name = string_helpers::to_lowercase(
            &channel_name
        );

        assert!(lowercase_channel_name == channel_key, EChannelNameMismatch);

        let updated_at = clock.timestamp_ms();

        let channel = channel::update(
            &mut channel,
            channel_key,
            channel_name,
            avatar_hash,
            banner_hash,
            description,
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
