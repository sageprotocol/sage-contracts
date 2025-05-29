module sage_channel::channel_actions {
    use std::string::{String, utf8};

    use sui::{
        clock::Clock,
        coin::{Coin},
        event,
        sui::{SUI}
    };

    use sage_admin::{
        admin_access::{ChannelWitnessConfig, UserWitnessConfig},
        admin::{AdminCap},
        apps::{Self, App},
        fees::{Self}
    };

    use sage_analytics::{
        analytics_actions::{Self}
    };

    use sage_channel::{
        channel::{Self, Channel},
        channel_fees::{Self, ChannelFees},
        channel_registry::{
            Self,
            AppChannelRegistry,
            ChannelRegistry
        },
        channel_witness::{Self, ChannelWitness}
    };

    use sage_post::{
        post_actions::{Self}
    };

    use sage_reward::{
        // reward_actions::{Self},
        reward_registry::{Self, RewardWeightsRegistry}
    };

    use sage_shared::{
        membership::{Self},
        moderation::{Self}
    };

    use sage_user::{
        user_owned::{Self, UserOwned},
        user_registry::{Self, UserRegistry},
        user_shared::{Self, UserShared}
    };

    use sage_utils::{
        string_helpers::{Self}
    };

    // --------------- Constants ---------------

    const METRIC_CHANNEL_CREATED: vector<u8> = b"channel-created";
    const METRIC_CHANNEL_FOLLOWED: vector<u8> = b"channel-followed";
    const METRIC_CHANNEL_TEXT_POST: vector<u8> = b"channel-text-posts";
    const METRIC_FOLLOWED_CHANNEL: vector<u8> = b"followed-channel";

    // --------------- Errors ---------------

    const EChannelNameMismatch: u64 = 370;

    // --------------- Name Tag ---------------

    // --------------- Events ---------------

    public struct ChannelCreated has copy, drop {
        id: address,
        app: address,
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
        app: address,
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
        app: &App,
        channel_fees: &ChannelFees,
        channel_registry: &mut ChannelRegistry,
        channel_witness_config: &ChannelWitnessConfig,
        clock: &Clock,
        reward_weights_registry: &RewardWeightsRegistry,
        owned_user: &mut UserOwned,
        user_witness_config: &UserWitnessConfig,
        avatar: String,
        banner: String,
        description: String,
        name: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext,
    ): address {
        let app_address = object::id_address(app);

        channel_registry::assert_app_channel_registry_match(
            channel_registry,
            app_address
        );

        let (
            custom_payment,
            sui_payment
        ) = channel_fees::assert_create_channel_payment<CoinType>(
            channel_fees,
            custom_payment,
            sui_payment
        );

        let timestamp = clock.timestamp_ms();
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
            membership_type,
            _membership_count
        ) = membership::wallet_join(
            &mut follows,
            self,
            timestamp
        );

        let channel_address = channel::create(
            app_address,
            avatar,
            banner,
            description,
            timestamp,
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

        let has_rewards_enabled = apps::has_rewards_enabled(
            app
        );

        if (has_rewards_enabled) {
            let channel_witness = channel_witness::create_witness();
            let current_epoch = reward_registry::get_current(
                reward_weights_registry
            );

            let analytics = user_owned::borrow_analytics_mut_for_channel<ChannelWitness>(
                &channel_witness,
                channel_witness_config,
                owned_user,
                user_witness_config,
                app_address,
                current_epoch,
                ctx
            );

            let reward_weights = reward_weights_registry.borrow_current();

            let metric = utf8(METRIC_CHANNEL_CREATED);
            let claim = reward_weights.get_weight(metric);

            analytics_actions::increment_analytics_for_channel<ChannelWitness>(
                analytics,
                app,
                &channel_witness,
                channel_witness_config,
                claim,
                metric
            );
        };

        event::emit(ChannelCreated {
            id: channel_address,
            app: app_address,
            avatar,
            banner,
            channel_key,
            channel_name: name,
            created_at: timestamp,
            created_by: self,
            description
        });

        event::emit(ChannelFollowsUpdate {
            account_type: membership_type,
            channel_key,
            message: membership_message,
            updated_at: timestamp,
            user: self
        });

        event::emit(ChannelModerationUpdate {
            channel_key,
            message: moderation_message,
            moderator_type: moderation_type,
            updated_at: timestamp,
            user: self
        });

        channel_address
    }

    public fun create_registry (
        app_channel_registry: &mut AppChannelRegistry,
        app: &App,
        ctx: &mut TxContext
    ) {
        let app_address = object::id_address(app);

        let channel_registry = channel_registry::create(
            app_address,
            ctx
        );

        let channel_registry_address = object::id_address(&channel_registry);

        channel_registry::add_registry(
            app_channel_registry,
            app_address,
            channel_registry_address
        );

        channel_registry::share_registry(channel_registry);
    }

    // test app and channel match
    public fun follow<CoinType> (
        app: &App,
        channel: &mut Channel,
        channel_fees: &ChannelFees,
        channel_witness_config: &ChannelWitnessConfig,
        clock: &Clock,
        reward_weights_registry: &RewardWeightsRegistry,
        owned_user: &mut UserOwned,
        user_witness_config: &UserWitnessConfig,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let app_address = object::id_address(app);

        channel::assert_app_channel_match(
            channel,
            app_address
        );

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
        let self = tx_context::sender(ctx);
        let timestamp = clock.timestamp_ms();

        let (
            message,
            account_type,
            count
        ) = membership::wallet_join(
            membership,
            self,
            timestamp
        );

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );

        let has_rewards_enabled = apps::has_rewards_enabled(
            app
        );

        if (has_rewards_enabled && count == 1) {
            let channel_witness = channel_witness::create_witness();
            let current_epoch = reward_registry::get_current(
                reward_weights_registry
            );

            let reward_weights = reward_weights_registry.borrow_current();

            let metric_channel = utf8(METRIC_CHANNEL_FOLLOWED);
            let metric_user = utf8(METRIC_FOLLOWED_CHANNEL);

            let claim_channel = reward_weights.get_weight(metric_channel);
            let claim_user = reward_weights.get_weight(metric_user);

            let analytics_channel = channel::borrow_analytics_mut(
                channel,
                channel_witness_config,
                app_address,
                current_epoch,
                ctx
            );

            analytics_actions::increment_analytics_for_channel<ChannelWitness>(
                analytics_channel,
                app,
                &channel_witness,
                channel_witness_config,
                claim_channel,
                metric_channel
            );

            let analytics_user = user_owned::borrow_analytics_mut_for_channel<ChannelWitness>(
                &channel_witness,
                channel_witness_config,
                owned_user,
                user_witness_config,
                app_address,
                current_epoch,
                ctx
            );

            analytics_actions::increment_analytics_for_channel<ChannelWitness>(
                analytics_user,
                app,
                &channel_witness,
                channel_witness_config,
                claim_user,
                metric_user
            );
        };
        
        let channel_key = channel::get_key(channel);

        event::emit(ChannelFollowsUpdate {
            account_type,
            channel_key,
            message,
            updated_at: timestamp,
            user: self
        });
    }

    public fun post<CoinType> (
        app: &App,
        channel: &mut Channel,
        channel_fees: &ChannelFees,
        channel_witness_config: &ChannelWitnessConfig,
        clock: &Clock,
        reward_weights_registry: &RewardWeightsRegistry,
        owned_user: &mut UserOwned,
        user_witness_config: &UserWitnessConfig,
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

        let app_address = object::id_address(app);
        let channel_witness = channel_witness::create_witness();

        let mut posts = channel::take_posts(
            channel,
            app_address,
            ctx
        );

        let (
            post_address,
            _self,
            timestamp
        ) = post_actions::create_for_channel<ChannelWitness>(
            app,
            &channel_witness,
            channel_witness_config,
            clock,
            &mut posts,
            data,
            description,
            title,
            ctx
        );

        channel::return_posts(
            channel,
            app_address,
            posts
        );

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );

        let has_rewards_enabled = apps::has_rewards_enabled(
            app
        );

        if (has_rewards_enabled) {
            let app_address = object::id_address(app);
            let channel_witness = channel_witness::create_witness();
            let current_epoch = reward_registry::get_current(
                reward_weights_registry
            );

            let reward_weights = reward_weights_registry.borrow_current();

            let metric = utf8(METRIC_CHANNEL_TEXT_POST);
            let claim = reward_weights.get_weight(metric);

            let analytics = user_owned::borrow_analytics_mut_for_channel<ChannelWitness>(
                &channel_witness,
                channel_witness_config,
                owned_user,
                user_witness_config,
                app_address,
                current_epoch,
                ctx
            );

            analytics_actions::increment_analytics_for_channel<ChannelWitness>(
                analytics,
                app,
                &channel_witness,
                channel_witness_config,
                claim,
                metric
            );
        };

        let channel_key = channel::get_key(channel);

        event::emit(ChannelPostCreated {
            id: post_address,
            app: app_address,
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
        let timestamp = clock.timestamp_ms();

        let (
            message,
            account_type,
            _count
        ) = membership::wallet_leave(
            membership,
            self,
            timestamp
        );

        let channel_key = channel::get_key(channel);

        event::emit(ChannelFollowsUpdate {
            account_type,
            channel_key,
            message,
            updated_at: timestamp,
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
