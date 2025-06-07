module sage_channel::channel_registry {
    use std::string::{String};

    use sui::{
        package::{claim_and_keep},
        table::{Self, Table}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EAppChannelRegistryMismatch: u64 = 370;

    // --------------- Name Tag ---------------

    public struct AppChannelRegistry has key {
        id: UID,
        registry: Table<address, address>
    }

    public struct ChannelRegistry has key {
        id: UID,
        app: address,
        registry: Table<String, address>
    }

    public struct CHANNEL_REGISTRY has drop {}

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    fun init(
        otw: CHANNEL_REGISTRY,
        ctx: &mut TxContext
    ) {
        claim_and_keep(otw, ctx);

        let app_channel_registry = AppChannelRegistry {
            id: object::new(ctx),
            registry: table::new(ctx)
        };

        transfer::share_object(app_channel_registry);
    }

    // --------------- Public Functions ---------------

    public fun assert_app_channel_registry_match(
        channel_registry: &ChannelRegistry,
        app_address: address
    ) {
        assert!(app_address == channel_registry.app, EAppChannelRegistryMismatch);
    }

    public fun borrow_channel_address(
        channel_registry: &ChannelRegistry,
        channel_key: String
    ): address {
        *channel_registry.registry.borrow(channel_key)
    }

    public fun borrow_channel_registry_address(
        app_channel_registry: &AppChannelRegistry,
        app_address: address
    ): address {
        *app_channel_registry.registry.borrow(app_address)
    }

    public fun has_record(
        channel_registry: &ChannelRegistry,
        channel_key: String
    ): bool {
        channel_registry.registry.contains(channel_key)
    }

    public fun has_channel_registry(
        app_channel_registry: &AppChannelRegistry,
        app_address: address
    ): bool {
        app_channel_registry.registry.contains(app_address)
    }

    // --------------- Friend Functions ---------------

    public(package) fun add(
        channel_registry: &mut ChannelRegistry,
        channel_key: String,
        channel_address: address
    ) {
        channel_registry.registry.add(channel_key, channel_address);
    }

    public(package) fun add_registry(
        app_channel_registry: &mut AppChannelRegistry,
        app_address: address,
        channel_registry_address: address
    ) {
        app_channel_registry.registry.add(app_address, channel_registry_address);
    }

    public(package) fun create(
        app_address: address,
        ctx: &mut TxContext
    ): ChannelRegistry {
        ChannelRegistry {
            id: object::new(ctx),
            app: app_address,
            registry: table::new(ctx)
        }
    }

    public(package) fun share_registry(
        channel_registry: ChannelRegistry
    ) {
        transfer::share_object(channel_registry);
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(CHANNEL_REGISTRY {}, ctx);
    }
}
