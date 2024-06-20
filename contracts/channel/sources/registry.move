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

    #[test_only]
    public fun destroy_for_testing(
        self: ChannelRegistry
    ) {
        let ChannelRegistry {
            registry,
            reverse_registry
        } = self;

        registry.drop();
        reverse_registry.drop();
    }

    public fun has_record(
        self: &ChannelRegistry,
        channel_name: String
    ): bool {
        self.registry.contains(channel_name)
    }

    // --------------- Friend Functions ---------------

    public(package) fun add_record(
        self: &mut ChannelRegistry,
        name: String,
        channel_id: ID
    ) {
        let record_exists = self.has_record(name);

        assert!(!record_exists, EChannelRecordExists);

        self.registry.add(name, channel_id);
        self.reverse_registry.add(channel_id, name);
    }
}
