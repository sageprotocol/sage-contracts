module sage_user::user_actions {
    use std::string::{String};

    use sui::{
        clock::Clock,
        coin::{Coin},
        event,
        sui::{SUI}
    };

    use sage_admin::{
        admin::{InviteCap},
        apps::{Self, App},
        authentication::{Self, AuthenticationConfig},
        fees::{Self}
    };

    use sage_post::{
        post_actions::{Self}
    };

    use sage_shared::{
        membership::{Self},
        posts::{Self}
    };

    use sage_user::{
        soul::{Self},
        user::{Self, User},
        user_fees::{Self, UserFees},
        user_invite::{
            Self,
            InviteConfig,
            UserInviteRegistry
        },
        user_registry::{Self, UserRegistry}
    };

    use sage_utils::{
        string_helpers::{Self}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EInviteRequired: u64 = 370;
    const ENoSelfJoin: u64 = 371;
    const EUserNameMismatch: u64 = 372;

    // --------------- Name Tag ---------------

    // --------------- Events ---------------

    public struct InviteCreated has copy, drop {
        invite_code: String,
        invite_key: String,
        user: address
    }

    public struct UserCreated has copy, drop {
        id: address,
        avatar_hash: String,
        banner_hash: String,
        created_at: u64,
        description: String,
        invited_by: Option<address>,
        owner: address,
        soul: address,
        user_key: String,
        user_name: String
    }

    public struct UserMembershipUpdate has copy, drop {
        account_type: u8,
        followed_user: address,
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
        avatar_hash: String,
        banner_hash: String,
        description: String,
        updated_at: u64,
        user_key: String,
        user_name: String
    }

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun create<CoinType> (
        clock: &Clock,
        invite_config: &InviteConfig,
        user_registry: &mut UserRegistry,
        user_invite_registry: &mut UserInviteRegistry,
        user_fees: &UserFees,
        invite_code_option: Option<String>,
        invite_key_option: Option<String>,
        avatar_hash: String,
        banner_hash: String,
        description: String,
        name: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ): address {
        let (
            custom_payment,
            sui_payment
        ) = user_fees::assert_create_user_payment<CoinType>(
            user_fees,
            custom_payment,
            sui_payment
        );

        let is_invite_included = option::is_some(&invite_code_option) && option::is_some(&invite_key_option);

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

        let channel_following = membership::create(ctx);
        let follows = membership::create(ctx);
        let posts = posts::create(ctx);
        let soul_address = soul::create(
            user_key,
            ctx
        );
        let user_following = membership::create(ctx);

        let user_address = user::create(
            avatar_hash,
            banner_hash,
            channel_following,
            created_at,
            description,
            follows,
            user_key,
            self,
            name,
            posts,
            soul_address,
            user_following,
            ctx
        );

        user_registry::add(
            user_registry,
            user_key,
            self,
            user_address
        );

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );

        event::emit(UserCreated {
            id: user_address,
            avatar_hash,
            banner_hash,
            created_at,
            description,
            invited_by,
            owner: self,
            soul: soul_address,
            user_key,
            user_name: name
        });

        user_address
    }

    public fun create_invite<CoinType, SoulType: key> (
        authentication_config: &AuthenticationConfig,
        invite_config: &InviteConfig,
        user_fees: &UserFees,
        user_invite_registry: &mut UserInviteRegistry,
        soul: &SoulType,
        invite_code: String,
        invite_hash: vector<u8>,
        invite_key: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        authentication::assert_authentication<SoulType>(
            authentication_config,
            soul
        );

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

    public fun join<CoinType, SoulType: key> (
        authentication_config: &AuthenticationConfig,
        clock: &Clock,
        soul: &SoulType,
        user: &mut User,
        user_fees: &UserFees,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        authentication::assert_authentication<SoulType>(
            authentication_config,
            soul
        );

        let (
            custom_payment,
            sui_payment
        ) = user_fees::assert_join_user_payment<CoinType>(
            user_fees,
            custom_payment,
            sui_payment
        );

        let self = tx_context::sender(ctx);
        let user_address = user::get_owner(user);

        assert!(self != user_address, ENoSelfJoin);

        let follows = user::borrow_follows_mut(user);

        let (
            membership_message,
            membership_type
        ) = membership::wallet_join(
            follows,
            self
        );

        let updated_at = clock.timestamp_ms();

        event::emit(UserMembershipUpdate {
            account_type: membership_type,
            followed_user: user_address,
            message: membership_message,
            updated_at,
            user: self
        });

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );
    }

    public fun leave<CoinType> (
        clock: &Clock,
        user: &mut User,
        user_fees: &UserFees,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let (
            custom_payment,
            sui_payment
        ) = user_fees::assert_leave_user_payment<CoinType>(
            user_fees,
            custom_payment,
            sui_payment
        );

        let self = tx_context::sender(ctx);
        let user_address = user::get_owner(user);

        let follows = user::borrow_follows_mut(user);

        let (
            membership_message,
            membership_type
        ) = membership::wallet_leave(
            follows,
            self
        );

        let updated_at = clock.timestamp_ms();

        event::emit(UserMembershipUpdate {
            account_type: membership_type,
            followed_user: user_address,
            message: membership_message,
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
        clock: &Clock,
        soul: &SoulType,
        user: &mut User,
        user_fees: &UserFees,
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

        let posts = user::borrow_posts_mut(user);

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
        let self = tx_context::sender(ctx);
        let user_key = user::get_key(user);

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

    public fun update<CoinType> (
        clock: &Clock,
        user_registry: &UserRegistry,
        user_fees: &UserFees,
        user: &mut User,
        avatar_hash: String,
        banner_hash: String,
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

        user::update(
            user,
            avatar_hash,
            banner_hash,
            description,
            name,
            updated_at
        );

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );

        event::emit(UserUpdated {
            avatar_hash,
            banner_hash,
            user_key: owned_user_key,
            user_name: name,
            description,
            updated_at
        });
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
