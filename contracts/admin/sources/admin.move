module sage::admin {
    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    public struct AdminCap has key {
        id: UID
    }

    public struct UpdateCap has key {
        id: UID
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    fun init(ctx: &mut TxContext) {
        let admin = tx_context::sender(ctx);

        let admin_cap = AdminCap { id: object::new(ctx) };
        let update_cap = UpdateCap { id: object::new(ctx) };

        transfer::transfer(admin_cap, admin);
        transfer::transfer(update_cap, admin);
    }

    // --------------- Public Functions ---------------

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

}
