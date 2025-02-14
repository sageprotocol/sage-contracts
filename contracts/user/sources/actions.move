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
        fees::{Self}
    };

    use sage_user::{
        user::{Self, User},
        user_fees::{Self, UserFees},
        user_invite::{
            Self,
            InviteConfig,
            UserInviteRegistry
        },
        user_membership::{
            Self,
            UserMembership,
            UserMembershipRegistry
        },
        user_posts::{Self},
        user_registry::{Self, UserRegistry}
    };

    use sage_utils::{
        string_helpers::{Self}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EInviteNotAllowed: u64 = 370;
    const EInviteNotFound: u64 = 371;
    const ENoInvite: u64 = 372;
    const ENotInvited: u64 = 373;
    const ENoSelfJoin: u64 = 374;
    const EUserDoesNotExist: u64 = 375;
    const EUserExists: u64 = 376;
    const EUserMembershipMismatch: u64 = 377;
    const EUserNameMismatch: u64 = 378;

    // --------------- Name Tag ---------------

    // --------------- Events ---------------

    public struct InviteCreated has copy, drop {
        invite_code: String,
        invite_key: String,
        user: address
    }

    public struct UserCreated has copy, drop {
        avatar_hash: String,
        banner_hash: String,
        created_at: u64,
        description: String,
        owner: address,
        invited_by: Option<address>,
        shard_address: address,
        user_key: String,
        user_membership_address: address,
        user_name: String
    }

    public struct UserUpdated has copy, drop {
        avatar_hash: String,
        banner_hash: String,
        description: String,
        owner: address,
        updated_at: u64,
        user_key: String,
        user_name: String
    }

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun create<CoinType> (
        clock: &Clock,
        user_registry: &mut UserRegistry,
        user_invite_registry: &mut UserInviteRegistry,
        user_membership_registry: &mut UserMembershipRegistry,
        user_fees: &UserFees,
        invite_config: &InviteConfig,
        invite_code: String,
        invite_key: String,
        avatar_hash: String,
        banner_hash: String,
        description: String,
        name: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ): address {
        let self = tx_context::sender(ctx);

        let user_exists = user_registry::has_address_record(
            user_registry,
            self
        );

        assert!(!user_exists, EUserExists);

        let is_invite_included = invite_key.length() > 0;

        let is_invite_required = user_invite::is_invite_required(
            invite_config
        );

        assert!(
            !is_invite_required || (is_invite_required && is_invite_included),
            ENoInvite
        );

        let (
            custom_payment,
            sui_payment
        ) = user_fees::assert_create_user_payment<CoinType>(
            user_fees,
            custom_payment,
            sui_payment
        );

        let invited_by = if (is_invite_included) {
            let has_record = user_invite::has_record(
                user_invite_registry,
                invite_key
            );

            assert!(has_record, EInviteNotFound);

            let (hash, user) = user_invite::get_destructured_invite(
                user_invite_registry,
                invite_key
            );

            let is_invite_valid = if (!is_invite_required) {
                true
            } else {
                user_invite::is_invite_valid(
                    invite_code,
                    invite_key,
                    hash
                )
            };

            assert!(is_invite_valid, ENotInvited);

            user_invite::delete_invite(
                user_invite_registry,
                invite_key
            );

            option::some(user)
        } else {
            option::none()
        };

        let timestamp = clock.timestamp_ms();
        let user_key = string_helpers::to_lowercase(
            &name
        );

        let user_address = user::create(
            avatar_hash,
            banner_hash,
            timestamp,
            description,
            self,
            name,
            ctx
        );

        let user_membership_address = user_membership::create(
            user_membership_registry,
            user_key,
            ctx
        );

        let user_post_shard_address = user_posts::create(
            timestamp,
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
            avatar_hash,
            banner_hash,
            created_at: timestamp,
            description,
            invited_by,
            owner: self,
            shard_address: user_post_shard_address,
            user_key,
            user_membership_address,
            user_name: name
        });

        user_address
    }

    public fun create_invite<CoinType> (
        user_registry: &UserRegistry,
        user_invite_registry: &mut UserInviteRegistry,
        invite_config: &InviteConfig,
        user_fees: &UserFees,
        invite_code: String,
        invite_hash: vector<u8>,
        invite_key: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let is_invite_required = user_invite::is_invite_required(
            invite_config
        );

        assert!(!is_invite_required, EInviteNotAllowed);

        let self = tx_context::sender(ctx);

        let user_exists = user_registry::has_address_record(
            user_registry,
            self
        );

        assert!(user_exists, EUserDoesNotExist);

        let (
            custom_payment,
            sui_payment
        ) = user_fees::assert_create_invite_payment<CoinType>(
            user_fees,
            custom_payment,
            sui_payment
        );

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

    public fun join<CoinType> (
        user_registry: &UserRegistry,
        user_membership_registry: &UserMembershipRegistry,
        user: &User,
        user_membership: &mut UserMembership,
        user_fees: &UserFees,
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

        let self_key = user_registry::get_user_key_from_owner(
            user_registry,
            self
        );

        let username = user::get_immutable_name(
            user
        );
        let user_key = string_helpers::to_lowercase(
            &username
        );

        assert!(self_key != user_key, ENoSelfJoin);

        let membership_address = user_membership::get_address(
            user_membership
        );
        let expected_membership_address = user_membership::borrow_membership_address(
            user_membership_registry,
            user_key
        );

        assert!(membership_address == expected_membership_address, EUserMembershipMismatch);

        let (
            custom_payment,
            sui_payment
        ) = user_fees::assert_join_user_payment<CoinType>(
            user_fees,
            custom_payment,
            sui_payment
        );

        let owner_address = user_registry::get_owner_address_from_key(
            user_registry,
            user_key
        );

        user_membership::join(
            user_membership,
            owner_address,
            self
        );

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );
    }

    public fun leave<CoinType> (
        user_registry: &UserRegistry,
        user_membership_registry: &UserMembershipRegistry,
        user: &User,
        user_membership: &mut UserMembership,
        user_fees: &UserFees,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let username = user::get_immutable_name(
            user
        );
        let user_key = string_helpers::to_lowercase(
            &username
        );

        let membership_address = user_membership::get_address(
            user_membership
        );
        let expected_membership_address = user_membership::borrow_membership_address(
            user_membership_registry,
            user_key
        );

        assert!(membership_address == expected_membership_address, EUserMembershipMismatch);

        let (
            custom_payment,
            sui_payment
        ) = user_fees::assert_leave_user_payment<CoinType>(
            user_fees,
            custom_payment,
            sui_payment
        );

        let owner_address = user_registry::get_owner_address_from_key(
            user_registry,
            user_key
        );

        let self = tx_context::sender(ctx);

        user_membership::leave(
            user_membership,
            owner_address,
            self
        );

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );
    }

    public fun update<CoinType> (
        clock: &Clock,
        user_registry: &UserRegistry,
        user_fees: &UserFees,
        user: User,
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

        let user_key = user_registry::get_user_key_from_owner(
            user_registry,
            self
        );

        let lowercase_user_name = string_helpers::to_lowercase(
            &name
        );

        assert!(lowercase_user_name == user_key, EUserNameMismatch);

        let updated_at = clock.timestamp_ms();

        let user_request = user::create_user_request(
            user
        );

        let user_request = user::update(
            user_request,
            avatar_hash,
            banner_hash,
            description,
            name,
            updated_at
        );

        user::destroy_user_request(
            user_request,
            self
        );

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );

        event::emit(UserUpdated {
            avatar_hash,
            banner_hash,
            owner: self,
            user_key,
            user_name: name,
            description,
            updated_at
        });
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
