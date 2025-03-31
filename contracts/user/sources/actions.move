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
        user_fees::{Self, UserFees},
        user_invite::{
            Self,
            InviteConfig,
            UserInviteRegistry
        },
        user_owned::{Self, UserOwned},
        user_registry::{Self, UserRegistry},
        user_shared::{Self, UserShared}
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
    const EUserNameMismatch: u64 = 374;

    // --------------- Name Tag ---------------

    // --------------- Events ---------------

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

    public struct UserFollowsUpdate has copy, drop {
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
        avatar: String,
        banner: String,
        description: String,
        updated_at: u64,
        user_key: String,
        user_name: String
    }

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

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
        let posts = posts::create(ctx);

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
            user_key,
            owned_user_address,
            self,
            posts,
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
        authentication_config: &AuthenticationConfig,
        invite_config: &InviteConfig,
        user_fees: &UserFees,
        user_invite_registry: &mut UserInviteRegistry,
        owned_user: &UserOwned,
        invite_code: String,
        invite_hash: vector<u8>,
        invite_key: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        authentication::assert_authentication<UserOwned>(
            authentication_config,
            owned_user
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

    public fun follow<CoinType> (
        authentication_config: &AuthenticationConfig,
        clock: &Clock,
        owned_user: &UserOwned,
        shared_user: &mut UserShared,
        user_fees: &UserFees,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        authentication::assert_authentication<UserOwned>(
            authentication_config,
            owned_user
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
        let user_address = user_shared::get_owner(shared_user);

        assert!(self != user_address, ENoSelfJoin);

        let follows = user_shared::borrow_follows_mut(shared_user);

        let (
            membership_message,
            membership_type
        ) = membership::wallet_join(
            follows,
            self
        );

        let updated_at = clock.timestamp_ms();

        event::emit(UserFollowsUpdate {
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
        ) = user_fees::assert_leave_user_payment<CoinType>(
            user_fees,
            custom_payment,
            sui_payment
        );

        let self = tx_context::sender(ctx);
        let user_address = user_shared::get_owner(shared_user);

        let follows = user_shared::borrow_follows_mut(shared_user);

        let (
            membership_message,
            membership_type
        ) = membership::wallet_leave(
            follows,
            self
        );

        let updated_at = clock.timestamp_ms();

        event::emit(UserFollowsUpdate {
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

    public fun post<CoinType> (
        app: &App,
        authentication_config: &AuthenticationConfig,
        clock: &Clock,
        owned_user: &UserOwned,
        shared_user: &mut UserShared,
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

        let posts = user_shared::borrow_posts_mut(shared_user);

        let (
            post_address,
            _self,
            timestamp
        ) = post_actions::create<UserOwned>(
            authentication_config,
            clock,
            owned_user,
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

        let app_name = apps::get_name(app);
        let self = tx_context::sender(ctx);
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
