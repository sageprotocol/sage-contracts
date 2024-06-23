module sage::channel_registry {
    use std::string::{String};

    use sui::{table::{Self, Table}};

    use sage::{
        admin::{AdminCap}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EChannelRecordExists: u64 = 0;

    // --------------- Name Tag ---------------

    public struct ChannelRegistry has store {
        registry: Table<String, ID>,
        reverse_registry: Table<ID, String>
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun create_channel_registry(
        _: &AdminCap,
        ctx: &mut TxContext
    ): ChannelRegistry {
        ChannelRegistry {
            registry: table::new(ctx),
            reverse_registry: table::new(ctx)
        }
    }

    public fun get_channel_id(
        channel_registry: &mut ChannelRegistry,
        channel_name: String
    ): ID {
        channel_registry.registry[channel_name]
    }

    public fun get_channel_name(
        channel_registry: &mut ChannelRegistry,
        channel_id: ID
    ): String {
        channel_registry.reverse_registry[channel_id]
    }

    public fun has_record(
        channel_registry: &ChannelRegistry,
        channel_name: String
    ): bool {
        channel_registry.registry.contains(channel_name)
    }

    // --------------- Friend Functions ---------------

    public(package) fun add_record(
        channel_registry: &mut ChannelRegistry,
        name: String,
        channel_id: ID
    ) {
        let record_exists = channel_registry.has_record(name);

        assert!(!record_exists, EChannelRecordExists);

        channel_registry.registry.add(name, channel_id);
        channel_registry.reverse_registry.add(channel_id, name);
    }

    // --------------- Test Functions ---------------

    #[test_only]
    public fun destroy_for_testing(
        channel_registry: ChannelRegistry
    ) {
        let ChannelRegistry {
            registry,
            reverse_registry
        } = channel_registry;

        registry.drop();
        reverse_registry.drop();
    }
}
