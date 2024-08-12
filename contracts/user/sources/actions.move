module sage_user::user_actions {
    use std::string::{String};

    use sui::clock::Clock;
    use sui::event;

    use sage_user::{
        user::{Self, User},
        user_invite::{Self, InviteConfig, UserInviteRegistry},
        user_membership::{Self, UserMembershipRegistry},
        user_registry::{Self, UserRegistry}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EInviteNotFound: u64 = 370;
    const ENoInvite: u64 = 371;
    const ENotInvited: u64 = 372;
    const ENoSelfJoin: u64 = 373;
    const EUserDoesNotExist: u64 = 374;

    // --------------- Name Tag ---------------

    // --------------- Events ---------------

    public struct UserCreated has copy, drop {
        address: address,
        avatar_hash: String,
        banner_hash: String,
        created_at: u64,
        description: String,
        invited_by: Option<address>,
        name: String
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

        let self = tx_context::sender(ctx);
        let created_at = clock.timestamp_ms();

        let user = user::create(
            self,
            avatar_hash,
            banner_hash,
            created_at,
            description,
            name
        );

        user_membership::create(
            user_membership_registry,
            user,
            ctx
        );

        user_registry::add(
            user_registry,
            name,
            self,
            user
        );

        event::emit(UserCreated {
            address: self,
            avatar_hash,
            banner_hash,
            created_at,
            description,
            invited_by,
            name
        });

        user
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

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
