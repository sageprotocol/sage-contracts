module sage_channel::channel_registry {
    use std::string::{String};

    use sui::{
        package::{claim_and_keep},
        table::{Self, Table}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    public struct ChannelRegistry has key, store {
        id: UID,
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

        let channel_registry = ChannelRegistry {
            id: object::new(ctx),
            registry: table::new(ctx)
        };

        transfer::share_object(channel_registry);
    }

    // --------------- Public Functions ---------------

    public fun borrow_channel_address(
        channel_registry: &ChannelRegistry,
        channel_key: String
    ): address {
        *channel_registry.registry.borrow(channel_key)
    }

    public fun has_record(
        channel_registry: &ChannelRegistry,
        channel_key: String
    ): bool {
        channel_registry.registry.contains(channel_key)
    }

    // --------------- Friend Functions ---------------

    public(package) fun add(
        channel_registry: &mut ChannelRegistry,
        channel_key: String,
        channel_address: address
    ) {
        channel_registry.registry.add(channel_key, channel_address);
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(CHANNEL_REGISTRY {}, ctx);
    }
}
