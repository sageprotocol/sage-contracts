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
        user_invite::{Self, InviteConfig, UserInviteRegistry},
        user_membership::{Self, UserMembershipRegistry},
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
    const EUserNameMismatch: u64 = 376;

    // --------------- Name Tag ---------------

    // --------------- Events ---------------

    public struct InviteCreated has copy, drop {
        invite_code: String,
        invite_key: String,
        user: address
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
        let (
            custom_payment,
            sui_payment
        ) = user_fees::assert_create_user_payment<CoinType>(
            user_fees,
            custom_payment,
            sui_payment
        );

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );

        let is_invite_included = invite_key.length() > 0;

        let is_invite_required = user_invite::is_invite_required(
            invite_config
        );

        assert!(
            !is_invite_required || (is_invite_required && is_invite_included),
            ENoInvite
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

        let created_at = clock.timestamp_ms();
        let self = tx_context::sender(ctx);
        let user_key = string_helpers::to_lowercase(
            &name
        );

        let user_address = user::create(
            avatar_hash,
            banner_hash,
            created_at,
            description,
            invited_by,
            self,
            name,
            user_key,
            ctx
        );

        user_membership::create(
            user_membership_registry,
            user_address,
            ctx
        );

        user_registry::add(
            user_registry,
            user_key,
            self,
            user_address
        );

        user_address
    }

    public fun create_invite<CoinType> (
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
        let (
            custom_payment,
            sui_payment
        ) = user_fees::assert_create_invite_payment<CoinType>(
            user_fees,
            custom_payment,
            sui_payment
        );

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );

        let is_invite_required = user_invite::is_invite_required(
            invite_config
        );

        assert!(!is_invite_required, EInviteNotAllowed);

        let self = tx_context::sender(ctx);

        user_invite::create_invite(
            user_invite_registry,
            invite_hash,
            invite_key,
            self
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
        user_membership_registry: &mut UserMembershipRegistry,
        user_fees: &UserFees,
        username: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let (
            custom_payment,
            sui_payment
        ) = user_fees::assert_join_user_payment<CoinType>(
            user_fees,
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

        let self_key = user_registry::get_user_key_from_owner(
            user_registry,
            self
        );

        let user_key = string_helpers::to_lowercase(
            &username
        );

        assert!(self_key != user_key, ENoSelfJoin);

        let user_address = user_registry::get_user_address_from_key(
            user_registry,
            user_key
        );

        let user_membership = user_membership::borrow_membership_mut(
            user_membership_registry,
            user_address
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
    }

    public fun leave<CoinType> (
        user_registry: &UserRegistry,
        user_membership_registry: &mut UserMembershipRegistry,
        user_fees: &UserFees,
        username: String,
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

        let user_key = string_helpers::to_lowercase(
            &username
        );

        let user_address = user_registry::get_user_address_from_key(
            user_registry,
            user_key
        );

        let user_membership = user_membership::borrow_membership_mut(
            user_membership_registry,
            user_address
        );

        let owner_address = user_registry::get_owner_address_from_key(
            user_registry,
            user_key
        );

        user_membership::leave(
            user_membership,
            owner_address,
            self
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

        fees::collect_payment<CoinType>(
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
            user_key,
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
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
