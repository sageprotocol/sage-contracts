module sage_admin::admin {
    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    public struct AdminCap has key {
        id: UID
    }

    public struct FeeCap has key {
        id: UID
    }

    public struct InviteCap has key {
        id: UID
    }

    public struct NotificationCap has key {
        id: UID
    }

    public struct TreasuryCap has key {
        id: UID
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    fun init(ctx: &mut TxContext) {
        let admin_cap = AdminCap { id: object::new(ctx) };
        let fee_cap = FeeCap { id: object::new(ctx) };
        let invite_cap = InviteCap { id: object::new(ctx) };
        let notification_cap = NotificationCap { id: object::new(ctx) };
        let treasury_cap = TreasuryCap { id: object::new(ctx) };

        transfer::transfer(admin_cap, @admin);
        transfer::transfer(fee_cap, @admin);
        transfer::transfer(invite_cap, @server);
        transfer::transfer(notification_cap, @server);
        transfer::transfer(treasury_cap, @treasury);
    }

    // --------------- Public Functions ---------------

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}
