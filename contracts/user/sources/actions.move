module sage_user::user_actions {
    use std::string::{String};

    use sui::clock::Clock;
    use sui::event;

    use sage_user::{
        user::{Self, User},
        user_registry::{Self, UserRegistry}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

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

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
