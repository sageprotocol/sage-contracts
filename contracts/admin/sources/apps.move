module sage_admin::apps {
    use std::{
        string::{String}
    };

    use sui::{
        dynamic_field,
        package::{claim_and_keep},
        table::{Self, Table}
    };

    use sage_admin::{
        admin::{FeeCap}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    public struct App has key {
        id: UID,
        name: String
    }

    public struct AppRegistry has key {
        id: UID,
        registry: Table<String, address>
    }

    public struct APPS has drop {}

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    fun init(
        otw: APPS,
        ctx: &mut TxContext
    ) {
        claim_and_keep(otw, ctx);

        let app_registry = AppRegistry {
            id: object::new(ctx),
            registry: table::new(ctx)
        };

        transfer::share_object(app_registry);
    }

    // --------------- Public Functions ---------------

    public fun add_fee_config(
        _: &FeeCap,
        app: &mut App,
        name: String,
        value: address
    ) {
        dynamic_field::add(
            &mut app.id,
            name,
            value
        );
    }

    public fun get_address(
        app: &App
    ): address {
        app.id.to_address()
    }

    public fun get_name(
        app: &App
    ): String {
        app.name
    }

    public fun has_record(
        app_registry: &AppRegistry,
        app_key: String
    ): bool {
        app_registry.registry.contains(app_key)
    }

    // --------------- Friend Functions ---------------

    public(package) fun create(
        app_registry: &mut AppRegistry,
        app_key: String,
        ctx: &mut TxContext
    ): address {
        let app = App {
            id: object::new(ctx),
            name: app_key
        };

        let app_address = app.id.to_address();

        app_registry.registry.add(
            app_key,
            app_address
        );

        transfer::share_object(app);

        app_address
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public fun create_for_testing(
        app_key: String,
        ctx: &mut TxContext
    ): App {
        App {
            id: object::new(ctx),
            name: app_key
        }
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(APPS {}, ctx);
    }
}
