module sage_user::soul {
    use std::string::{String};

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    public struct SageSoul has key {
        id: UID,
        name: String
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun get_name(
        soul: &SageSoul
    ): String {
        soul.name
    }

    // --------------- Friend Functions ---------------

    public(package) fun create(
        name: String,
        ctx: &mut TxContext
    ): address {
        let soul = SageSoul {
            id: object::new(ctx),
            name
        };

        let self = tx_context::sender(ctx);
        let soul_address = soul.id.to_address();

        transfer::transfer(soul, self);

        soul_address
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
