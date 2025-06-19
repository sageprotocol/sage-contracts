module sage_user::user_actions {
    use std::string::{
        String,
        utf8
    };

    use sui::{
        clock::Clock,
        coin::{Coin},
        event,
        sui::{SUI}
    };

    use sage_admin::{
        admin_access::{
            Self,
            ChannelConfig,
            UserWitnessConfig
        },
        admin::{InviteCap},
        apps::{Self, App},
        fees::{Self, Royalties}
    };

    use sage_analytics::{
        analytics_actions::{Self}
    };

    use sage_post::{
        post_actions::{Self},
        post_fees::{PostFees},
        post::{Post}
    };

    use sage_reward::{
        reward_actions::{Self},
        reward_registry::{Self, RewardCostWeightsRegistry}
    };

    use sage_shared::{
        membership::{Self}
    };

    use sage_trust::{
        trust_access::{RewardWitnessConfig},
        trust::{
            MintConfig,
            ProtectedTreasury,
            TRUST
        }
    };

    use sage_user::{
        user_fees::{Self, UserFees},
        user_invite::{
            Self,
            InviteConfig,
            UserInviteRegistry
        },
        user_owned::{Self, UserOwned},
        user_registry::{Self, UserRegistry},
        user_shared::{Self, UserShared},
        user_witness::{Self, UserWitness}
    };

    use sage_utils::{
        string_helpers::{Self}
    };

    // --------------- Constants ---------------

    const DESCRIPTION_MAX_LENGTH: u64 = 370;

    const METRIC_COMMENT_GIVEN: vector<u8> = b"comment-given";
    const METRIC_COMMENT_RECEIVED: vector<u8> = b"comment-received";
    const METRIC_FAVORITED_POST: vector<u8> = b"favorited-post";
    const METRIC_FOLLOWED_USER: vector<u8> = b"followed-user";
    const METRIC_LIKED_POST: vector<u8> = b"liked-post";
    const METRIC_POST_FAVORITED: vector<u8> = b"post-favorited";
    const METRIC_POST_LIKED: vector<u8> = b"post-liked";
    const METRIC_PROFILE_CREATED: vector<u8> = b"profile-created";
    const METRIC_USER_FOLLOWED: vector<u8> = b"user-followed";
    const METRIC_USER_FRIENDS: vector<u8> = b"user-friends";
    const METRIC_USER_TEXT_POST: vector<u8> = b"user-text-posts";

    const USERNAME_MIN_LENGTH: u64 = 3;
    const USERNAME_MAX_LENGTH: u64 = 20;

    // --------------- Errors ---------------

    const ECommentAppMismatch: u64 = 370;
    const EInvalidUserDescription: u64 = 371;
    const EInvalidUsername: u64 = 372;
    const EInviteRequired: u64 = 373;
    const ENoSelfJoin: u64 = 374;
    const ENotSelf: u64 = 375;
    const ESuppliedAuthorMismatch: u64 = 376;
    const EUserNameMismatch: u64 = 377;

    // --------------- Name Tag ---------------

    // --------------- Events ---------------

    public struct AppProfileCreated has copy, drop {
        app_id: address,
        avatar: u256,
        banner: u256,
        created_at: u64,
        description: String,
        name: String,
        user_id: address
    }

    public struct AppProfileUpdated has copy, drop {
        app_id: address,
        avatar: u256,
        banner: u256,
        description: String,
        name: String,
        updated_at: u64,
        user_id: address
    }

    public struct ChannelFavoritesUpdate has copy, drop {
        app_id: address,
        favorited_channel_id: address,
        message: u8,
        updated_at: u64,
        user_id: address
    }

    public struct InviteCreated has copy, drop {
        invite_code: String,
        invite_key: String,
        user_id: address
    }

    public struct PostFavoritesUpdate has copy, drop {
        app_id: address,
        favorited_post_id: address,
        message: u8,
        updated_at: u64,
        user_id: address
    }

    public struct UserCreated has copy, drop {
        avatar: u256,
        banner: u256,
        created_at: u64,
        description: String,
        invited_by: Option<address>,
        user_id: address,
        user_owned_id: address,
        user_shared_id: address,
        user_key: String,
        user_name: String
    }

    public struct UserFavoritesUpdate has copy, drop {
        app_id: address,
        favorited_user_id: address,
        message: u8,
        updated_at: u64,
        user_id: address
    }

    public struct UserFollowsUpdate has copy, drop {
        account_type: u8,
        app_id: address,
        followed_user_id: address,
        message: u8,
        updated_at: u64,
        user_id: address
    }

    public struct UserFriendUpdate has copy, drop {
        account_type: u8,
        app_id: address,
        friended_user_id: address,
        message: u8,
        updated_at: u64,
        user_id: address
    }

    public struct UserFriendRequestUpdate has copy, drop {
        account_type: u8,
        app_id: address,
        friended_user_id: address,
        message: u8,
        updated_at: u64,
        user_id: address
    }

    public struct UserPostCreated has copy, drop {
        app_id: address,
        created_at: u64,
        created_by: address,
        data: String,
        description: String,
        post_id: address,
        title: String,
        user_id: address
    }

    public struct UserUpdated has copy, drop {
        avatar: u256,
        banner: u256,
        description: String,
        updated_at: u64,
        user_id: address,
        user_name: String
    }

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun add_app_profile(
        app: &App,
        clock: &Clock,
        owned_user: &mut UserOwned,
        reward_cost_weights_registry: &RewardCostWeightsRegistry,
        user_witness_config: &UserWitnessConfig,
        avatar: u256,
        banner: u256,
        description: String,
        name: String,
        ctx: &mut TxContext
    ) {
        let app_address = object::id_address(app);

        let timestamp = clock.timestamp_ms();

        owned_user.add_profile(
            app_address,
            avatar,
            banner,
            timestamp,
            description,
            name
        );

        let has_rewards_enabled = app.has_rewards_enabled();

        if (has_rewards_enabled) {
            let current_epoch = reward_registry::get_current(
                reward_cost_weights_registry
            );

            let analytics = user_owned::borrow_or_create_analytics_mut(
                owned_user,
                user_witness_config,
                app_address,
                current_epoch,
                ctx
            );

            let reward_cost_weights = reward_cost_weights_registry.borrow_current();

            let metric = utf8(METRIC_PROFILE_CREATED);
            let claim = reward_cost_weights.get_weight(metric);

            let user_witness = user_witness::create_witness();

            analytics_actions::increment_analytics_for_user<UserWitness>(
                analytics,
                app,
                &user_witness,
                user_witness_config,
                claim,
                metric
            );
        };

        let self = tx_context::sender(ctx);

        event::emit(AppProfileCreated {
            app_id: app_address,
            avatar,
            banner,
            created_at: timestamp,
            description,
            name,
            user_id: self
        });
    }

    public fun add_favorite_channel<ChannelType: key> (
        app: &App,
        clock: &Clock,
        channel: &ChannelType,
        channel_config: &ChannelConfig,
        owned_user: &mut UserOwned,
        ctx: &mut TxContext
    ) {
        admin_access::assert_channel(
            channel_config,
            channel
        );

        let app_address = object::id_address(app);
        let timestamp = clock.timestamp_ms();

        let (
            message,
            self,
            favorited_channel_id,
            _count
        ) = user_owned::add_favorite_channel(
            channel,
            owned_user,
            app_address,
            timestamp,
            ctx
        );

        event::emit(ChannelFavoritesUpdate {
            app_id: app_address,
            favorited_channel_id,
            message,
            updated_at: timestamp,
            user_id: self
        });
    }

    public fun add_favorite_post(
        app: &App,
        clock: &Clock,
        owned_user: &mut UserOwned,
        post: &Post,
        reward_cost_weights_registry: &RewardCostWeightsRegistry,
        user: &mut UserShared,
        user_witness_config: &UserWitnessConfig,
        ctx: &mut TxContext
    ) {
        let favorite_post_author = post.get_author();
        let supplied_author_address = user.get_owner();

        assert!(favorite_post_author == supplied_author_address, ESuppliedAuthorMismatch);

        let app_address = object::id_address(app);
        let timestamp = clock.timestamp_ms();

        let (
            message,
            self,
            favorited_post_id,
            count
        ) = user_owned::add_favorite_post(
            post,
            owned_user,
            app_address,
            timestamp,
            ctx
        );

        let has_rewards_enabled = app.has_rewards_enabled();

        if (
            has_rewards_enabled &&
            favorite_post_author != self &&
            count == 1
        ) {
            let current_epoch = reward_registry::get_current(
                reward_cost_weights_registry
            );

            let analytics_self = user_owned::borrow_or_create_analytics_mut(
                owned_user,
                user_witness_config,
                app_address,
                current_epoch,
                ctx
            );

            let reward_cost_weights = reward_cost_weights_registry.borrow_current();

            let metric_author = utf8(METRIC_POST_FAVORITED);
            let metric_self = utf8(METRIC_FAVORITED_POST);

            let claim_author = reward_cost_weights.get_weight(metric_author);
            let claim_self = reward_cost_weights.get_weight(metric_self);
            
            let user_witness = user_witness::create_witness();

            analytics_actions::increment_analytics_for_user<UserWitness>(
                analytics_self,
                app,
                &user_witness,
                user_witness_config,
                claim_self,
                metric_self
            );

            let analytics_author = user_shared::borrow_or_create_analytics_mut(
                user,
                user_witness_config,
                app_address,
                current_epoch,
                ctx
            );

            analytics_actions::increment_analytics_for_user<UserWitness>(
                analytics_author,
                app,
                &user_witness,
                user_witness_config,
                claim_author,
                metric_author
            );
        };

        event::emit(PostFavoritesUpdate {
            app_id: app_address,
            favorited_post_id,
            message,
            updated_at: timestamp,
            user_id: self
        });
    }

    public fun add_favorite_user(
        app: &App,
        clock: &Clock,
        owned_user: &mut UserOwned,
        user: &UserShared,
        ctx: &mut TxContext
    ) {
        let app_address = object::id_address(app);
        let timestamp = clock.timestamp_ms();

        let (
            message,
            self,
            favorited_user_id,
            _count
        ) = user_owned::add_favorite_user(
            owned_user,
            user,
            app_address,
            timestamp,
            ctx
        );

        event::emit(UserFavoritesUpdate {
            app_id: app_address,
            favorited_user_id,
            message,
            updated_at: timestamp,
            user_id: self
        });
    }

    public fun assert_user_description(
        description: &String
    ) {
        let is_valid_description = is_valid_description(description);

        assert!(is_valid_description, EInvalidUserDescription);
    }

    public fun assert_user_name(
        name: &String
    ) {
        let is_valid_name = string_helpers::is_valid_name(
            name,
            USERNAME_MIN_LENGTH,
            USERNAME_MAX_LENGTH
        );

        assert!(is_valid_name, EInvalidUsername);
    }

    #[allow(lint(self_transfer))]
    public fun claim_reward(
        app: &App,
        mint_config: &MintConfig,
        reward_witness_config: &RewardWitnessConfig,
        treasury: &mut ProtectedTreasury,
        owned_user: &mut UserOwned,
        shared_user: &mut UserShared,
        user_witness_config: &UserWitnessConfig,
        epoch: u64,
        ctx: &mut TxContext
    ) {
        let self = tx_context::sender(ctx);
        let owner = shared_user.get_owner();

        assert!(owner == self, ENotSelf);

        let app_address = object::id_address(app);

        owned_user.assert_profile(app_address);

        let user_witness = user_witness::create_witness();

        let mut total_coin_option: Option<Coin<TRUST>> = option::none();

        let has_owned_analytics = owned_user.has_analytics(
            app_address,
            epoch
        );

        if (has_owned_analytics) {
            let analytics = owned_user.borrow_analytics_mut(
                app_address,
                epoch
            );
            let (
                _amount,
                coin_option
            ) = reward_actions::claim_value_for_user<UserWitness>(
                analytics,
                app,
                mint_config,
                reward_witness_config,
                treasury,
                &user_witness,
                user_witness_config,
                ctx
            );

            if (coin_option.is_some()) {
                total_coin_option.destroy_none();
                total_coin_option = coin_option;
            } else {
                coin_option.destroy_none();
            };
        };

        let has_shared_analytics = shared_user.has_analytics(
            app_address,
            epoch
        );

        if (has_shared_analytics) {
            let analytics = shared_user.borrow_analytics_mut(
                app_address,
                epoch
            );
            let (
                _amount,
                coin_option
            ) = reward_actions::claim_value_for_user<UserWitness>(
                analytics,
                app,
                mint_config,
                reward_witness_config,
                treasury,
                &user_witness,
                user_witness_config,
                ctx
            );

            if (coin_option.is_some()) {
                let coin = coin_option.destroy_some();

                if (total_coin_option.is_some()) {
                    let mut total_coin = total_coin_option.destroy_some();
                    total_coin.join(coin);

                    total_coin_option = option::some(total_coin);
                } else {
                    total_coin_option.destroy_none();
                    total_coin_option = option::some(coin);
                };
            } else {
                coin_option.destroy_none();
            };
        };

        if (total_coin_option.is_some()) {
            let total_coin = total_coin_option.destroy_some();

            let balance = total_coin.balance();
            let amount = balance.value();

            owned_user.add_to_total_rewards(amount);
            owned_user.add_to_profile_rewards(
                app_address,
                amount
            );

            transfer::public_transfer(total_coin, self);
        } else {
            total_coin_option.destroy_none();
        };
    }

    public fun comment<CoinType> (
        app: &App,
        clock: &Clock,
        owned_user: &mut UserOwned,
        parent_post: &mut Post,
        post_fees: &PostFees,
        reward_cost_weights_registry: &RewardCostWeightsRegistry,
        shared_user: &mut UserShared,
        user_witness_config: &UserWitnessConfig,
        data: String,
        description: String,
        title: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ): (
        address,
        address,
        u64
    ) {
        let app_address = object::id_address(app);
        let parent_app_address = parent_post.get_app();

        // verify comment belongs to app
        assert!(app_address == parent_app_address, ECommentAppMismatch);

        let has_rewards_enabled = app.has_rewards_enabled();

        let parent_author = parent_post.get_author();
        let self = tx_context::sender(ctx);

        let user_witness = user_witness::create_witness();

        if (
            has_rewards_enabled &&
            parent_author != self
        ) {
            let supplied_author = shared_user.get_owner();

            assert!(parent_author == supplied_author, ESuppliedAuthorMismatch);

            let current_epoch = reward_registry::get_current(
                reward_cost_weights_registry
            );

            let reward_cost_weights = reward_cost_weights_registry.borrow_current();

            let metric_parent = utf8(METRIC_COMMENT_RECEIVED);
            let metric_self = utf8(METRIC_COMMENT_GIVEN);

            let claim_parent = reward_cost_weights.get_weight(metric_parent);
            let claim_self = reward_cost_weights.get_weight(metric_self);

            let analytics_self = user_owned::borrow_or_create_analytics_mut(
                owned_user,
                user_witness_config,
                app_address,
                current_epoch,
                ctx
            );

            analytics_actions::increment_analytics_for_user<UserWitness>(
                analytics_self,
                app,
                &user_witness,
                user_witness_config,
                claim_self,
                metric_self
            );

            let analytics_parent = user_shared::borrow_or_create_analytics_mut(
                shared_user,
                user_witness_config,
                app_address,
                current_epoch,
                ctx
            );

            analytics_actions::increment_analytics_for_user<UserWitness>(
                analytics_parent,
                app,
                &user_witness,
                user_witness_config,
                claim_parent,
                metric_parent
            );
        };

        let top_parent = parent_post.get_top_parent();

        post_actions::comment_for_user<CoinType, UserWitness>(
            app,
            clock,
            parent_post,
            post_fees,
            &user_witness,
            user_witness_config,
            data,
            description,
            title,
            top_parent,
            custom_payment,
            sui_payment,
            ctx
        )
    }

    public fun create<CoinType> (
        clock: &Clock,
        invite_config: &InviteConfig,
        user_registry: &mut UserRegistry,
        user_invite_registry: &mut UserInviteRegistry,
        user_fees: &UserFees,
        invite_code_option: Option<String>,
        invite_key_option: Option<String>,
        avatar: u256,
        banner: u256,
        description: String,
        name: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ): (address, address) {
        assert_user_name(&name);
        assert_user_description(&description);

        let (
            custom_payment,
            sui_payment
        ) = user_fees::assert_create_user_payment<CoinType>(
            user_fees,
            custom_payment,
            sui_payment
        );

        let is_invite_included = 
            option::is_some(&invite_code_option) &&
            option::is_some(&invite_key_option);

        let is_invite_required = user_invite::is_invite_required(
            invite_config
        );

        assert!(
            !is_invite_required || is_invite_included,
            EInviteRequired
        );

        let invited_by = if (is_invite_included) {
            let invite_code = option::destroy_some(invite_code_option);
            let invite_key = option::destroy_some(invite_key_option);

            user_invite::assert_invite_exists(
                user_invite_registry,
                invite_key
            );

            let (hash, user_address) = user_invite::get_destructured_invite(
                user_invite_registry,
                invite_key
            );

            user_invite::assert_invite_is_valid(
                invite_code,
                invite_key,
                hash
            );

            user_invite::delete_invite(
                user_invite_registry,
                invite_key
            );

            option::some(user_address)
        } else {
            option::none()
        };

        let created_at = clock.timestamp_ms();
        let self = tx_context::sender(ctx);
        let user_key = string_helpers::to_lowercase(
            &name
        );

        let (
            owned_user,
            owned_user_address
        ) = user_owned::create(
            avatar,
            banner,
            created_at,
            description,
            user_key,
            name,
            self,
            ctx
        );

        let shared_user_address = user_shared::create(
            created_at,
            user_key,
            owned_user_address,
            self,
            ctx
        );

        user_owned::set_shared_user(
            owned_user,
            self,
            shared_user_address
        );

        user_registry::add(
            user_registry,
            user_key,
            self,
            owned_user_address,
            shared_user_address
        );

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );

        event::emit(UserCreated {
            avatar,
            banner,
            created_at,
            description,
            invited_by,
            user_owned_id: owned_user_address,
            user_shared_id: shared_user_address,
            user_id: self,
            user_key,
            user_name: name
        });

        (
            owned_user_address,
            shared_user_address
        )
    }

    public fun create_invite<CoinType> (
        invite_config: &InviteConfig,
        user_fees: &UserFees,
        user_invite_registry: &mut UserInviteRegistry,
        _: &UserOwned,
        invite_code: String,
        invite_hash: vector<u8>,
        invite_key: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        user_invite::assert_invite_not_required(invite_config);

        let (
            custom_payment,
            sui_payment
        ) = user_fees::assert_create_invite_payment<CoinType>(
            user_fees,
            custom_payment,
            sui_payment
        );

        let self = tx_context::sender(ctx);

        user_invite::create_invite(
            user_invite_registry,
            invite_hash,
            invite_key,
            self
        );

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );

        event::emit(InviteCreated {
            invite_code,
            invite_key,
            user_id: self
        });
    }

    public fun create_invite_admin(
        _: &InviteCap,
        user_invite_registry: &mut UserInviteRegistry,
        invite_hash: vector<u8>,
        invite_key: String,
        user: address
    ) {
        user_invite::create_invite(
            user_invite_registry,
            invite_hash,
            invite_key,
            user
        );
    }

    public fun follow<CoinType> (
        app: &App,
        clock: &Clock,
        owned_user: &mut UserOwned,
        reward_cost_weights_registry: &RewardCostWeightsRegistry,
        shared_user: &mut UserShared,
        user_fees: &UserFees,
        user_witness_config: &UserWitnessConfig,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let (
            custom_payment,
            sui_payment
        ) = user_fees::assert_follow_user_payment<CoinType>(
            user_fees,
            custom_payment,
            sui_payment
        );

        let self = tx_context::sender(ctx);
        let user_address = user_shared::get_owner(shared_user);

        assert!(self != user_address, ENoSelfJoin);

        let app_address = object::id_address(app);

        let follows = user_shared::borrow_follows_mut(
            shared_user,
            app_address,
            ctx
        );
        
        let timestamp = clock.timestamp_ms();

        let (
            membership_message,
            membership_type,
            membership_count
        ) = membership::wallet_join(
            follows,
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

        if (has_rewards_enabled && membership_count == 1) {
            let current_epoch = reward_registry::get_current(
                reward_cost_weights_registry
            );

            let reward_cost_weights = reward_cost_weights_registry.borrow_current();

            let metric_followed = utf8(METRIC_USER_FOLLOWED);
            let metric_self = utf8(METRIC_FOLLOWED_USER);

            let claim_followed = reward_cost_weights.get_weight(metric_followed);
            let claim_self = reward_cost_weights.get_weight(metric_self);

            let analytics_self = user_owned::borrow_or_create_analytics_mut(
                owned_user,
                user_witness_config,
                app_address,
                current_epoch,
                ctx
            );

            let user_witness = user_witness::create_witness();

            analytics_actions::increment_analytics_for_user<UserWitness>(
                analytics_self,
                app,
                &user_witness,
                user_witness_config,
                claim_self,
                metric_self
            );

            let analytics_followed = user_shared::borrow_or_create_analytics_mut(
                shared_user,
                user_witness_config,
                app_address,
                current_epoch,
                ctx
            );

            analytics_actions::increment_analytics_for_user<UserWitness>(
                analytics_followed,
                app,
                &user_witness,
                user_witness_config,
                claim_followed,
                metric_followed
            );
        };

        event::emit(UserFollowsUpdate {
            account_type: membership_type,
            app_id: app_address,
            followed_user_id: user_address,
            message: membership_message,
            updated_at: timestamp,
            user_id: self
        });
    }

    public fun friend_user<CoinType> (
        app: &App,
        clock: &Clock,
        reward_cost_weights_registry: &RewardCostWeightsRegistry,
        user_fees: &UserFees,
        user_friend: &mut UserShared,
        user_shared: &mut UserShared,
        user_witness_config: &UserWitnessConfig,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let (
            custom_payment,
            sui_payment
        ) = user_fees::assert_friend_user_payment<CoinType>(
            user_fees,
            custom_payment,
            sui_payment
        );

        let friend_address = user_shared::get_owner(user_friend);
        let user_address = user_shared::get_owner(user_shared);

        let self = tx_context::sender(ctx);

        assert!(self == user_address, ENotSelf);

        let app_address = object::id_address(app);

        let friend_requests = user_shared::borrow_friend_requests_mut(
            user_shared,
            app_address,
            ctx
        );

        let already_requested = membership::is_member(
            friend_requests,
            friend_address
        );

        let timestamp = clock.timestamp_ms();

        if (already_requested) {
            membership::wallet_leave(
                friend_requests,
                friend_address,
                timestamp
            );

            let friends = user_shared::borrow_friends_mut(
                user_shared,
                app_address,
                ctx
            );
            membership::wallet_join(
                friends,
                friend_address,
                timestamp
            );

            let friends_friends = user_shared::borrow_friends_mut(
                user_friend,
                app_address,
                ctx
            );
            let (
                membership_message,
                membership_type,
                membership_count
            ) = membership::wallet_join(
                friends_friends,
                user_address,
                timestamp
            );

            let has_rewards_enabled = apps::has_rewards_enabled(
                app
            );

            if (has_rewards_enabled && membership_count == 1) {
                let current_epoch = reward_registry::get_current(
                    reward_cost_weights_registry
                );

                let reward_cost_weights = reward_cost_weights_registry.borrow_current();

                let metric = utf8(METRIC_USER_FRIENDS);

                let claim = reward_cost_weights.get_weight(metric);

                let analytics = user_shared::borrow_or_create_analytics_mut(
                    user_shared,
                    user_witness_config,
                    app_address,
                    current_epoch,
                    ctx
                );

                let user_witness = user_witness::create_witness();

                analytics_actions::increment_analytics_for_user<UserWitness>(
                    analytics,
                    app,
                    &user_witness,
                    user_witness_config,
                    claim,
                    metric
                );

                let friend_analytics = user_shared::borrow_or_create_analytics_mut(
                    user_friend,
                    user_witness_config,
                    app_address,
                    current_epoch,
                    ctx
                );

                analytics_actions::increment_analytics_for_user<UserWitness>(
                    friend_analytics,
                    app,
                    &user_witness,
                    user_witness_config,
                    claim,
                    metric
                );
            };

            event::emit(UserFriendUpdate {
                account_type: membership_type,
                app_id: app_address,
                friended_user_id: friend_address,
                message: membership_message,
                updated_at: timestamp,
                user_id: user_address
            });
        } else {
            let friends_friend_requests = user_shared::borrow_friend_requests_mut(
                user_friend,
                app_address,
                ctx
            );

            let (
                membership_message,
                membership_type,
                _membership_count
            ) = membership::wallet_join(
                friends_friend_requests,
                user_address,
                timestamp
            );

            event::emit(UserFriendRequestUpdate {
                account_type: membership_type,
                app_id: app_address,
                friended_user_id: friend_address,
                message: membership_message,
                updated_at: timestamp,
                user_id: user_address
            });
        };

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );
    }

    public fun like_post<CoinType> (
        app: &App,
        clock: &Clock,
        owned_user: &mut UserOwned,
        post: &mut Post,
        post_fees: &PostFees,
        reward_cost_weights_registry: &RewardCostWeightsRegistry,
        royalties: &Royalties,
        shared_user: &mut UserShared,
        user_witness_config: &UserWitnessConfig,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let author_address = post.get_author();
        let shared_user_address = shared_user.get_owner();

        assert!(author_address == shared_user_address, ESuppliedAuthorMismatch);

        let user_witness = user_witness::create_witness();

        post_actions::like_for_user<CoinType, UserWitness>(
            clock,
            post,
            post_fees,
            royalties,
            &user_witness,
            user_witness_config,
            custom_payment,
            sui_payment,
            ctx
        );

        let has_rewards_enabled = app.has_rewards_enabled();
        let self = tx_context::sender(ctx);

        if (
            has_rewards_enabled &&
            author_address != self
        ) {
            let app_address = object::id_address(app);
            let current_epoch = reward_registry::get_current(
                reward_cost_weights_registry
            );

            let analytics_self = user_owned::borrow_or_create_analytics_mut(
                owned_user,
                user_witness_config,
                app_address,
                current_epoch,
                ctx
            );

            let reward_cost_weights = reward_cost_weights_registry.borrow_current();

            let metric_author = utf8(METRIC_POST_LIKED);
            let metric_self = utf8(METRIC_LIKED_POST);

            let claim_author = reward_cost_weights.get_weight(metric_author);
            let claim_self = reward_cost_weights.get_weight(metric_self);

            let user_witness = user_witness::create_witness();

            analytics_actions::increment_analytics_for_user<UserWitness>(
                analytics_self,
                app,
                &user_witness,
                user_witness_config,
                claim_self,
                metric_self
            );

            let analytics_author = user_shared::borrow_or_create_analytics_mut(
                shared_user,
                user_witness_config,
                app_address,
                current_epoch,
                ctx
            );

            analytics_actions::increment_analytics_for_user<UserWitness>(
                analytics_author,
                app,
                &user_witness,
                user_witness_config,
                claim_author,
                metric_author
            );
        };
    }

    public fun post<CoinType> (
        app: &App,
        clock: &Clock,
        owned_user: &mut UserOwned,
        reward_cost_weights_registry: &RewardCostWeightsRegistry,
        shared_user: &mut UserShared,
        user_fees: &UserFees,
        user_witness_config: &UserWitnessConfig,
        data: String,
        description: String,
        title: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ): (address, u64) {
        let (
            custom_payment,
            sui_payment
        ) = user_fees::assert_post_from_user_payment<CoinType>(
            user_fees,
            custom_payment,
            sui_payment
        );

        let app_address = object::id_address(app);
        let shared_user_address = object::id_address(shared_user);

        let mut posts = user_shared::take_posts(
            shared_user,
            app_address,
            ctx
        );

        let user_witness = user_witness::create_witness();

        let (
            post_address,
            self,
            timestamp
        ) = post_actions::create_for_user<UserWitness>(
            app,
            clock,
            &mut posts,
            &user_witness,
            user_witness_config,
            data,
            description,
            title,
            shared_user_address,
            ctx
        );

        user_shared::return_posts(
            shared_user,
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
            let current_epoch = reward_registry::get_current(
                reward_cost_weights_registry
            );

            let reward_cost_weights = reward_cost_weights_registry.borrow_current();

            let metric = utf8(METRIC_USER_TEXT_POST);

            let claim = reward_cost_weights.get_weight(metric);

            let analytics = user_owned::borrow_or_create_analytics_mut(
                owned_user,
                user_witness_config,
                app_address,
                current_epoch,
                ctx
            );

            let user_witness = user_witness::create_witness();

            analytics_actions::increment_analytics_for_user<UserWitness>(
                analytics,
                app,
                &user_witness,
                user_witness_config,
                claim,
                metric
            );
        };

        let user_id = shared_user.get_owner();

        event::emit(UserPostCreated {
            app_id: app_address,
            created_at: timestamp,
            created_by: self,
            data,
            description,
            post_id: post_address,
            title,
            user_id
        });

        (post_address, timestamp)
    }

    public fun remove_favorite_channel<ChannelType: key> (
        app: &App,
        clock: &Clock,
        channel: &ChannelType,
        owned_user: &mut UserOwned,
        ctx: &mut TxContext
    ) {
        let app_address = object::id_address(app);
        let timestamp = clock.timestamp_ms();

        let (
            message,
            self,
            favorited_channel_id,
            _count
        ) = user_owned::remove_favorite_channel(
            channel,
            owned_user,
            app_address,
            timestamp,
            ctx
        );

        event::emit(ChannelFavoritesUpdate {
            app_id: app_address,
            favorited_channel_id,
            message,
            updated_at: timestamp,
            user_id: self
        });
    }

    public fun remove_favorite_post(
        app: &App,
        clock: &Clock,
        owned_user: &mut UserOwned,
        post: &Post,
        ctx: &mut TxContext
    ) {
        let app_address = object::id_address(app);
        let timestamp = clock.timestamp_ms();

        let (
            message,
            self,
            favorited_post_id,
            _count
        ) = user_owned::remove_favorite_post(
            post,
            owned_user,
            app_address,
            timestamp,
            ctx
        );

        event::emit(PostFavoritesUpdate {
            app_id: app_address,
            favorited_post_id,
            message,
            updated_at: timestamp,
            user_id: self
        });
    }

    public fun remove_favorite_user(
        app: &App,
        clock: &Clock,
        owned_user: &mut UserOwned,
        user: &UserShared,
        ctx: &mut TxContext
    ) {
        let app_address = object::id_address(app);
        let timestamp = clock.timestamp_ms();

        let (
            message,
            self,
            favorited_user_id,
            _count
        ) = user_owned::remove_favorite_user(
            owned_user,
            user,
            app_address,
            timestamp,
            ctx
        );

        event::emit(UserFavoritesUpdate {
            app_id: app_address,
            favorited_user_id,
            message,
            updated_at: timestamp,
            user_id: self
        });
    }

    public fun remove_friend_request(
        app: &App,
        clock: &Clock,
        shared_user: &mut UserShared,
        removed_request: address,
        ctx: &mut TxContext
    ) {
        let self = tx_context::sender(ctx);
        let user_address = user_shared::get_owner(shared_user);

        assert!(self == user_address || self == removed_request, ENotSelf);

        let app_address = object::id_address(app);

        let friend_requests = user_shared::borrow_friend_requests_mut(
            shared_user,
            app_address,
            ctx
        );
        
        let timestamp = clock.timestamp_ms();

        let (
            membership_message,
            membership_type,
            _membership_count
        ) = membership::wallet_leave(
            friend_requests,
            removed_request,
            timestamp
        );

        event::emit(UserFriendRequestUpdate {
            account_type: membership_type,
            app_id: app_address,
            friended_user_id: removed_request,
            message: membership_message,
            updated_at: timestamp,
            user_id: user_address
        });
    }

    public fun unfollow<CoinType> (
        app: &App,
        clock: &Clock,
        shared_user: &mut UserShared,
        user_fees: &UserFees,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let (
            custom_payment,
            sui_payment
        ) = user_fees::assert_unfollow_user_payment<CoinType>(
            user_fees,
            custom_payment,
            sui_payment
        );

        let self = tx_context::sender(ctx);
        let user_address = user_shared::get_owner(shared_user);

        let app_address = object::id_address(app);

        let follows = user_shared::borrow_follows_mut(
            shared_user,
            app_address,
            ctx
        );
        
        let timestamp = clock.timestamp_ms();

        let (
            membership_message,
            membership_type,
            _membership_count
        ) = membership::wallet_leave(
            follows,
            self,
            timestamp
        );

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );

        event::emit(UserFollowsUpdate {
            account_type: membership_type,
            app_id: app_address,
            followed_user_id: user_address,
            message: membership_message,
            updated_at: timestamp,
            user_id: self
        });
    }

    public fun unfriend_user<CoinType> (
        app: &App,
        clock: &Clock,
        user_fees: &UserFees,
        user_friend: &mut UserShared,
        user_shared: &mut UserShared,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let (
            custom_payment,
            sui_payment
        ) = user_fees::assert_unfriend_user_payment<CoinType>(
            user_fees,
            custom_payment,
            sui_payment
        );

        let friend_address = user_shared::get_owner(user_friend);
        let user_address = user_shared::get_owner(user_shared);

        let self = tx_context::sender(ctx);

        assert!(self == friend_address || self == user_address, ENotSelf);

        let app_address = object::id_address(app);
        let timestamp = clock.timestamp_ms();

        let friends = user_shared::borrow_friends_mut(
            user_shared,
            app_address,
            ctx
        );
        membership::wallet_leave(
            friends,
            friend_address,
            timestamp
        );

        let friends_friends = user_shared::borrow_friends_mut(
            user_friend,
            app_address,
            ctx
        );
        let (
            membership_message,
            membership_type,
            _membership_count
        ) = membership::wallet_leave(
            friends_friends,
            user_address,
            timestamp
        );

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );

        event::emit(UserFriendUpdate {
            account_type: membership_type,
            app_id: app_address,
            friended_user_id: friend_address,
            message: membership_message,
            updated_at: timestamp,
            user_id: user_address
        });
    }

    public fun update<CoinType> (
        clock: &Clock,
        user_registry: &UserRegistry,
        user_fees: &UserFees,
        owned_user: &mut UserOwned,
        avatar: u256,
        banner: u256,
        description: String,
        name: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let (
            custom_payment,
            sui_payment
        ) = user_fees::assert_update_user_payment<CoinType>(
            user_fees,
            custom_payment,
            sui_payment
        );

        let self = tx_context::sender(ctx);

        let owned_user_key = user_registry::get_key_from_owner_address(
            user_registry,
            self
        );

        let lowercase_user_name = string_helpers::to_lowercase(
            &name
        );

        assert!(lowercase_user_name == owned_user_key, EUserNameMismatch);

        let updated_at = clock.timestamp_ms();

        user_owned::update(
            owned_user,
            avatar,
            banner,
            description,
            name,
            updated_at
        );

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );

        event::emit(UserUpdated {
            avatar,
            banner,
            user_id: self,
            user_name: name,
            description,
            updated_at
        });
    }

    public fun update_app_profile(
        app: &App,
        clock: &Clock,
        owned_user: &mut UserOwned,
        avatar: u256,
        banner: u256,
        description: String,
        name: String,
        ctx: &mut TxContext
    ) {
        let app_address = object::id_address(app);

        let timestamp = clock.timestamp_ms();

        owned_user.update_profile(
            app_address,
            avatar,
            banner,
            description,
            name,
            timestamp
        );

        let self = tx_context::sender(ctx);

        event::emit(AppProfileUpdated {
            app_id: app_address,
            avatar,
            banner,
            description,
            name,
            updated_at: timestamp,
            user_id: self
        });
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    fun is_valid_description(
        description: &String
    ): bool {
        let len = description.length();

        if (len > DESCRIPTION_MAX_LENGTH) {
            return false
        };

        true
    }

    // --------------- Test Functions ---------------

    #[test_only]
    public fun is_valid_description_for_testing(
        name: &String
    ): bool {
        is_valid_description(name)
    }
}
