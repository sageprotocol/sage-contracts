module sage::channel_registry {
    use std::string::{String};

    use sui::{table::{Self, Table}};

    use sage::{
        channel_name::{Self, ChannelName},
        channel_record::{Self, ChannelRecord}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EChannelRecordExists: u64 = 0;

    // --------------- Name Tag ---------------

    public struct Registry has store {
        registry: Table<ChannelName, ChannelRecord>,
        reverse_registry: Table<ChannelRecord, ChannelName>
    }

    public struct AdminCap has key {
        id: UID
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    fun init(ctx: &mut TxContext) {
        let admin = tx_context::sender(ctx);
        let admin_cap = AdminCap { id: object::new(ctx) };

        transfer::transfer(admin_cap, admin);
    }

    // --------------- Public Functions ---------------

    public fun create(
        _: &AdminCap,
        ctx: &mut TxContext
    ): Registry {
        Registry {
            registry: table::new(ctx),
            reverse_registry: table::new(ctx)
        }
    }

    public fun has_record(
        self: &Registry,
        channel_name: ChannelName
    ): bool {
        self.registry.contains(channel_name)
    }

    // --------------- Friend Functions ---------------

    public(package) fun add_record(
        self: &mut Registry,
        name: String,
        channel_id: ID
    ) {
        let channel_name = channel_name::create(name);

        let record_exists = self.has_record(channel_name);

        assert!(!record_exists, EChannelRecordExists);

        let channel_record = channel_record::create(
            channel_id
        );

        self.registry.add(channel_name, channel_record);
        self.reverse_registry.add(channel_record, channel_name);
    }
}
