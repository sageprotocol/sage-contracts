module sage_user::user_actions {
    use std::string::{String};

    use sui::{
        clock::Clock,
        event
    };

    use sage_admin::{
        admin::{AdminCap, InviteCap}
    };

    use sage_user::{
        user::{Self, User},
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

    public fun create(
        clock: &Clock,
        user_registry: &mut UserRegistry,
        user_invite_registry: &mut UserInviteRegistry,
        user_membership_registry: &mut UserMembershipRegistry,
        invite_config: &InviteConfig,
        invite_code: String,
        invite_key: String,
        avatar_hash: String,
        banner_hash: String,
        description: String,
        name: String,
        ctx: &mut TxContext
    ): User {
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

        let user = user::create(
            self,
            avatar_hash,
            banner_hash,
            created_at,
            description,
            invited_by,
            name,
            user_key
        );

        user_membership::create(
            user_membership_registry,
            user,
            ctx
        );

        user_registry::add(
            user_registry,
            user_key,
            self,
            user
        );

        user
    }

    public fun create_invite(
        user_invite_registry: &mut UserInviteRegistry,
        invite_config: &InviteConfig,
        invite_code: String,
        invite_hash: vector<u8>,
        invite_key: String,
        ctx: &mut TxContext
    ) {
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

    public fun join(
        user_registry: &mut UserRegistry,
        user_membership_registry: &mut UserMembershipRegistry,
        username: String,
        ctx: &mut TxContext
    ) {
        let self = tx_context::sender(ctx);

        let user_exists = user_registry::has_address_record(
            user_registry,
            self
        );

        assert!(user_exists, EUserDoesNotExist);

        let user = user_registry::borrow_user(
            user_registry,
            username
        );

        let user_address = user::get_address(user);

        assert!(self != user_address, ENoSelfJoin);

        let user_membership = user_membership::borrow_membership_mut(
            user_membership_registry,
            user
        );

        user_membership::join(
            user_membership,
            user_address,
            ctx
        );
    }

    public fun leave(
        user_registry: &mut UserRegistry,
        user_membership_registry: &mut UserMembershipRegistry,
        username: String,
        ctx: &mut TxContext
    ) {
        let self = tx_context::sender(ctx);

        let user_exists = user_registry::has_address_record(
            user_registry,
            self
        );

        assert!(user_exists, EUserDoesNotExist);

        let user = user_registry::borrow_user(
            user_registry,
            username
        );

        let user_address = user::get_address(user);

        let user_membership = user_membership::borrow_membership_mut(
            user_membership_registry,
            user
        );

        user_membership::leave(
            user_membership,
            user_address,
            ctx
        );
    }

    public fun update_avatar_admin (
        _: &AdminCap,
        clock: &Clock,
        user_registry: &mut UserRegistry,
        user_key: String,
        avatar_hash: String
    ) {
        let mut user = user_registry::borrow_user(
            user_registry,
            user_key
        );
        
        let updated_at = clock.timestamp_ms();

        let user = user::update_avatar(
            user_key,
            &mut user,
            avatar_hash,
            updated_at
        );

        user_registry::replace(
            user_registry,
            user_key,
            user
        );
    }

    public fun update_banner_admin (
        _: &AdminCap,
        clock: &Clock,
        user_registry: &mut UserRegistry,
        user_key: String,
        banner_hash: String
    ) {
        let mut user = user_registry::borrow_user(
            user_registry,
            user_key
        );
        
        let updated_at = clock.timestamp_ms();

        let user = user::update_banner(
            user_key,
            &mut user,
            banner_hash,
            updated_at
        );

        user_registry::replace(
            user_registry,
            user_key,
            user
        );
    }

    public fun update_description_admin (
        _: &AdminCap,
        clock: &Clock,
        user_registry: &mut UserRegistry,
        user_key: String,
        description: String
    ) {
        let mut user = user_registry::borrow_user(
            user_registry,
            user_key
        );
        
        let updated_at = clock.timestamp_ms();

        let user = user::update_description(
            user_key,
            &mut user,
            description,
            updated_at
        );

        user_registry::replace(
            user_registry,
            user_key,
            user
        );
    }

    public fun update_name_admin (
        _: &AdminCap,
        clock: &Clock,
        user_registry: &mut UserRegistry,
        user_key: String,
        name: String
    ) {
        let mut user = user_registry::borrow_user(
            user_registry,
            user_key
        );

        let lowercase_user_name = string_helpers::to_lowercase(
            &name
        );

        assert!(lowercase_user_name == user_key, EUserNameMismatch);
        
        let updated_at = clock.timestamp_ms();

        let user = user::update_name(
            user_key,
            &mut user,
            name,
            updated_at
        );

        user_registry::replace(
            user_registry,
            user_key,
            user
        );
    }

    public fun update_avatar_self (
        clock: &Clock,
        user_registry: &mut UserRegistry,
        avatar_hash: String,
        ctx: &mut TxContext
    ) {
        let self = tx_context::sender(ctx);

        let user_key = user_registry::borrow_user_key(
            user_registry,
            self
        );

        let updated_at = clock.timestamp_ms();
        let user = user_registry::borrow_user_mut(
            user_registry,
            user_key
        );

        user::update_avatar(
            user_key,
            user,
            avatar_hash,
            updated_at
        );
    }

    public fun update_banner_self (
        clock: &Clock,
        user_registry: &mut UserRegistry,
        banner_hash: String,
        ctx: &mut TxContext
    ) {
        let self = tx_context::sender(ctx);

        let user_key = user_registry::borrow_user_key(
            user_registry,
            self
        );

        let updated_at = clock.timestamp_ms();
        let user = user_registry::borrow_user_mut(
            user_registry,
            user_key
        );

        user::update_banner(
            user_key,
            user,
            banner_hash,
            updated_at
        );
    }

    public fun update_description_self (
        clock: &Clock,
        user_registry: &mut UserRegistry,
        description: String,
        ctx: &mut TxContext
    ) {
        let self = tx_context::sender(ctx);

        let user_key = user_registry::borrow_user_key(
            user_registry,
            self
        );

        let updated_at = clock.timestamp_ms();
        let user = user_registry::borrow_user_mut(
            user_registry,
            user_key
        );

        user::update_description(
            user_key,
            user,
            description,
            updated_at
        );
    }

    public fun update_name_self (
        clock: &Clock,
        user_registry: &mut UserRegistry,
        name: String,
        ctx: &mut TxContext
    ) {
        let self = tx_context::sender(ctx);

        let user_key = user_registry::borrow_user_key(
            user_registry,
            self
        );

        let lowercase_user_name = string_helpers::to_lowercase(
            &name
        );

        assert!(lowercase_user_name == user_key, EUserNameMismatch);

        let updated_at = clock.timestamp_ms();
        let user = user_registry::borrow_user_mut(
            user_registry,
            user_key
        );

        user::update_name(
            user_key,
            user,
            name,
            updated_at
        );
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
