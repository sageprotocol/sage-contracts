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
        access::{
            Self,
            ChannelConfig,
            UserOwnedConfig,
            UserWitnessConfig
        },
        admin::{InviteCap},
        apps::{Self, App},
        fees::{Self}
    };

    use sage_analytics::{
        analytics_actions::{Self}
    };

    use sage_post::{
        post_actions::{Self}
    };

    use sage_reward::{
        reward_actions::{Self},
        reward_registry::{Self, RewardWeightsRegistry}
    };

    use sage_shared::{
        membership::{Self}
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

    const USERNAME_MIN_LENGTH: u64 = 3;
    const USERNAME_MAX_LENGTH: u64 = 20;

    // --------------- Errors ---------------

    const EInvalidUserDescription: u64 = 370;
    const EInvalidUsername: u64 = 371;
    const EInviteRequired: u64 = 372;
    const ENoSelfJoin: u64 = 373;
    const ENotSelf: u64 = 374;
    const EUserNameMismatch: u64 = 375;

    // --------------- Name Tag ---------------

    public struct AppPosts {
        app: String
    }

    // --------------- Events ---------------

    public struct ChannelFavoritesUpdate has copy, drop {
        app: address,
        favorited_channel: address,
        message: u8,
        updated_at: u64,
        user: address
    }

    public struct InviteCreated has copy, drop {
        invite_code: String,
        invite_key: String,
        user: address
    }

    public struct UserCreated has copy, drop {
        id: address,
        avatar: String,
        banner: String,
        created_at: u64,
        description: String,
        invited_by: Option<address>,
        user_owned: address,
        user_shared: address,
        user_key: String,
        user_name: String
    }

    public struct UserFavoritesUpdate has copy, drop {
        app: address,
        favorited_user: address,
        message: u8,
        updated_at: u64,
        user: address
    }

    public struct UserFollowsUpdate has copy, drop {
        account_type: u8,
        followed_user: address,
        message: u8,
        updated_at: u64,
        user: address
    }

    public struct UserFriendUpdate has copy, drop {
        account_type: u8,
        friended_user: address,
        message: u8,
        updated_at: u64,
        user: address
    }

    public struct UserFriendRequestUpdate has copy, drop {
        account_type: u8,
        friended_user: address,
        message: u8,
        updated_at: u64,
        user: address
    }

    public struct UserPostCreated has copy, drop {
        id: address,
        app: String,
        created_at: u64,
        created_by: address,
        data: String,
        description: String,
        title: String,
        user_key: String
    }

    public struct UserUpdated has copy, drop {
        avatar: String,
        banner: String,
        description: String,
        updated_at: u64,
        user_key: String,
        user_name: String
    }

    public struct USER_ACTIONS has drop {}

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun add_favorite_channel<ChannelType: key> (
        app: &App,
        clock: &Clock,
        channel: &ChannelType,
        channel_config: &ChannelConfig,
        owned_user: &mut UserOwned,
        ctx: &mut TxContext
    ) {
        access::assert_channel(
            channel_config,
            channel
        );

        let (
            app_address,
            message,
            self,
            favorited_channel
        ) = user_owned::add_favorite_channel(
            app,
            channel,
            owned_user,
            ctx
        );

        let timestamp = clock.timestamp_ms();

        event::emit(ChannelFavoritesUpdate {
            app: app_address,
            favorited_channel,
            message,
            updated_at: timestamp,
            user: self
        });
    }

    public fun add_favorite_user (
        app: &App,
        clock: &Clock,
        owned_user: &mut UserOwned,
        user: &UserShared,
        ctx: &mut TxContext
    ) {
        let (
            app_address,
            message,
            self,
            favorited_user
        ) = user_owned::add_favorite_user(
            app,
            owned_user,
            user,
            ctx
        );

        let timestamp = clock.timestamp_ms();

        event::emit(UserFavoritesUpdate {
            app: app_address,
            favorited_user,
            message,
            updated_at: timestamp,
            user: self
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

    public fun create<CoinType> (
        clock: &Clock,
        invite_config: &InviteConfig,
        user_registry: &mut UserRegistry,
        user_invite_registry: &mut UserInviteRegistry,
        user_fees: &UserFees,
        invite_code_option: Option<String>,
        invite_key_option: Option<String>,
        avatar: String,
        banner: String,
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

        let follows = membership::create(ctx);
        let friend_requests = membership::create(ctx);
        let friends = membership::create(ctx);

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
            follows,
            friend_requests,
            friends,
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
            id: self,
            avatar,
            banner,
            created_at,
            description,
            invited_by,
            user_owned: owned_user_address,
            user_shared: shared_user_address,
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
            user: self
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
        reward_weights_registry: &RewardWeightsRegistry,
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

        let follows = user_shared::borrow_follows_mut(shared_user);
        
        let timestamp = clock.timestamp_ms();

        let (
            membership_message,
            membership_type
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

        if (has_rewards_enabled) {
            let app_name = apps::get_name(app);
            let current_epoch = reward_registry::get_current(
                reward_weights_registry
            );

            let analytics = user_owned::borrow_analytics_mut(
                owned_user,
                user_witness_config,
                app_name,
                current_epoch,
                ctx
            );

            let user_witness = user_witness::create_witness();

            analytics_actions::increment_analytics_for_user<UserWitness>(
                analytics,
                user_witness,
                user_witness_config,
                utf8(b"user-followed")
            );

            let friend_analytics = user_shared::borrow_analytics_mut(
                shared_user,
                user_witness_config,
                app_name,
                current_epoch,
                ctx
            );

            let user_witness = user_witness::create_witness();

            analytics_actions::increment_analytics_for_user<UserWitness>(
                friend_analytics,
                user_witness,
                user_witness_config,
                utf8(b"user-follows")
            );
        };

        event::emit(UserFollowsUpdate {
            account_type: membership_type,
            followed_user: user_address,
            message: membership_message,
            updated_at: timestamp,
            user: self
        });
    }

    public fun friend_user<CoinType> (
        app: &App,
        clock: &Clock,
        reward_weights_registry: &RewardWeightsRegistry,
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

        let friend_requests = user_shared::borrow_friend_requests_mut(
            user_shared
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
                user_shared
            );
            let friends_friends = user_shared::borrow_friends_mut(
                user_friend
            );

            membership::wallet_join(
                friends,
                friend_address,
                timestamp
            );
            let (
                membership_message,
                membership_type
            ) = membership::wallet_join(
                friends_friends,
                user_address,
                timestamp
            );

            let has_rewards_enabled = apps::has_rewards_enabled(
                app
            );

            if (has_rewards_enabled) {
                let app_name = apps::get_name(app);
                let current_epoch = reward_registry::get_current(
                    reward_weights_registry
                );

                let analytics = user_shared::borrow_analytics_mut(
                    user_shared,
                    user_witness_config,
                    app_name,
                    current_epoch,
                    ctx
                );

                let user_witness = user_witness::create_witness();

                analytics_actions::increment_analytics_for_user<UserWitness>(
                    analytics,
                    user_witness,
                    user_witness_config,
                    utf8(b"user-friends")
                );

                let friend_analytics = user_shared::borrow_analytics_mut(
                    user_friend,
                    user_witness_config,
                    app_name,
                    current_epoch,
                    ctx
                );

                let user_witness = user_witness::create_witness();

                analytics_actions::increment_analytics_for_user<UserWitness>(
                    friend_analytics,
                    user_witness,
                    user_witness_config,
                    utf8(b"user-friends")
                );
            };

            event::emit(UserFriendUpdate {
                account_type: membership_type,
                friended_user: friend_address,
                message: membership_message,
                updated_at: timestamp,
                user: user_address
            });
        } else {
            let friends_friend_requests = user_shared::borrow_friend_requests_mut(
                user_friend
            );

            let (
                membership_message,
                membership_type
            ) = membership::wallet_join(
                friends_friend_requests,
                user_address,
                timestamp
            );

            event::emit(UserFriendRequestUpdate {
                account_type: membership_type,
                friended_user: friend_address,
                message: membership_message,
                updated_at: timestamp,
                user: user_address
            });
        };

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );
    }

    public fun post<CoinType> (
        app: &App,
        clock: &Clock,
        owned_user: &mut UserOwned,
        owned_user_config: &UserOwnedConfig,
        reward_weights_registry: &RewardWeightsRegistry,
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

        let app_name = apps::get_name(
            app
        );

        let mut posts = user_shared::take_posts(
            shared_user,
            app_name,
            ctx
        );

        let (
            post_address,
            self,
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

        user_shared::return_posts(
            shared_user,
            app_name,
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
                reward_weights_registry
            );

            let analytics = user_owned::borrow_analytics_mut(
                owned_user,
                user_witness_config,
                app_name,
                current_epoch,
                ctx
            );

            let user_witness = user_witness::create_witness();

            analytics_actions::increment_analytics_for_user<UserWitness>(
                analytics,
                user_witness,
                user_witness_config,
                utf8(b"user-text-posts")
            );
        };

        let user_key = user_shared::get_key(shared_user);

        event::emit(UserPostCreated {
            id: post_address,
            app: app_name,
            created_at: timestamp,
            created_by: self,
            data,
            description,
            title,
            user_key
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
        let (
            app_address,
            message,
            self,
            favorited_channel
        ) = user_owned::remove_favorite_channel(
            app,
            channel,
            owned_user,
            ctx
        );

        let timestamp = clock.timestamp_ms();

        event::emit(ChannelFavoritesUpdate {
            app: app_address,
            favorited_channel,
            message,
            updated_at: timestamp,
            user: self
        });
    }

    public fun remove_favorite_user (
        app: &App,
        clock: &Clock,
        owned_user: &mut UserOwned,
        user: &UserShared,
        ctx: &mut TxContext
    ) {
        let (
            app_address,
            message,
            self,
            favorited_user
        ) = user_owned::remove_favorite_user(
            app,
            owned_user,
            user,
            ctx
        );

        let timestamp = clock.timestamp_ms();

        event::emit(UserFavoritesUpdate {
            app: app_address,
            favorited_user,
            message,
            updated_at: timestamp,
            user: self
        });
    }

    public fun remove_friend_request(
        clock: &Clock,
        shared_user: &mut UserShared,
        removed_request: address,
        ctx: &mut TxContext
    ) {
        let self = tx_context::sender(ctx);
        let user_address = user_shared::get_owner(shared_user);

        assert!(self == user_address || self == removed_request, ENotSelf);

        let friend_requests = user_shared::borrow_friend_requests_mut(
            shared_user
        );
        
        let timestamp = clock.timestamp_ms();

        let (
            membership_message,
            membership_type
        ) = membership::wallet_leave(
            friend_requests,
            removed_request,
            timestamp
        );

        event::emit(UserFriendRequestUpdate {
            account_type: membership_type,
            friended_user: removed_request,
            message: membership_message,
            updated_at: timestamp,
            user: user_address
        });
    }

    public fun unfollow<CoinType> (
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

        let follows = user_shared::borrow_follows_mut(shared_user);
        
        let timestamp = clock.timestamp_ms();

        let (
            membership_message,
            membership_type
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
            followed_user: user_address,
            message: membership_message,
            updated_at: timestamp,
            user: self
        });
    }

    public fun unfriend_user<CoinType> (
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

        let friends = user_shared::borrow_friends_mut(
            user_shared
        );
        let friends_friends = user_shared::borrow_friends_mut(
            user_friend
        );
        
        let timestamp = clock.timestamp_ms();

        membership::wallet_leave(
            friends,
            friend_address,
            timestamp
        );
        let (
            membership_message,
            membership_type
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
            friended_user: friend_address,
            message: membership_message,
            updated_at: timestamp,
            user: user_address
        });
    }

    public fun update<CoinType> (
        clock: &Clock,
        user_registry: &UserRegistry,
        user_fees: &UserFees,
        owned_user: &mut UserOwned,
        avatar: String,
        banner: String,
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
            user_key: owned_user_key,
            user_name: name,
            description,
            updated_at
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
