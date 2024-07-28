module sage_user::user_actions {
    use std::string::{String};

    use sui::clock::Clock;
    use sui::event;

    use sage_user::{
        user::{Self, User},
        user_membership::{Self, UserMembershipRegistry},
        user_registry::{Self, UserRegistry}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const ENoSelfJoin: u64 = 370;

    // --------------- Name Tag ---------------

    // --------------- Events ---------------

    public struct UserCreated has copy, drop {
        address: address,
        avatar_hash: String,
        banner_hash: String,
        created_at: u64,
        description: String,
        name: String
    }

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun create(
        clock: &Clock,
        user_registry: &mut UserRegistry,
        user_membership_registry: &mut UserMembershipRegistry,
        avatar_hash: String,
        banner_hash: String,
        description: String,
        name: String,
        ctx: &mut TxContext
    ): User {
        let address = tx_context::sender(ctx);
        let created_at = clock.timestamp_ms();

        let user = user::create(
            address,
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
            address,
            user
        );

        event::emit(UserCreated {
            address,
            avatar_hash,
            banner_hash,
            created_at,
            description,
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

        let user = user_registry::borrow_user(
            user_registry,
            username
        );

        let address = user::get_address(user);

        assert!(self != address, ENoSelfJoin);

        let user_membership = user_membership::borrow_membership_mut(
            user_membership_registry,
            user
        );

        user_membership::join(
            user_membership,
            address,
            ctx
        );
    }

    public fun leave(
        user_registry: &mut UserRegistry,
        user_membership_registry: &mut UserMembershipRegistry,
        username: String,
        ctx: &mut TxContext
    ) {
        let user = user_registry::borrow_user(
            user_registry,
            username
        );

        let address = user::get_address(user);

        let user_membership = user_membership::borrow_membership_mut(
            user_membership_registry,
            user
        );

        user_membership::leave(
            user_membership,
            address,
            ctx
        );
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
