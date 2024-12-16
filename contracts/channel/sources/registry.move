module sage_channel::channel_registry {
    use std::string::{String};

    use sui::package::{claim_and_keep};

    use sage_channel::{
        channel::{Channel}
    };

    use sage_immutable::{
        immutable_table::{Self, ImmutableTable}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EChannelRecordDoesNotExist: u64 = 370;
    const EChannelRecordExists: u64 = 371;

    // --------------- Name Tag ---------------

    public struct ChannelRegistry has key, store {
        id: UID,
        registry: ImmutableTable<String, Channel>
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
            registry: immutable_table::new(ctx)
        };

        transfer::share_object(channel_registry);
    }

    // --------------- Public Functions ---------------

    public fun borrow_channel(
        channel_registry: &ChannelRegistry,
        channel_key: String
    ): Channel {
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
        channel: Channel
    ) {
        let record_exists = channel_registry.has_record(channel_key);

        assert!(!record_exists, EChannelRecordExists);

        channel_registry.registry.add(channel_key, channel);
    }

    public(package) fun replace(
        channel_registry: &mut ChannelRegistry,
        channel_key: String,
        channel: Channel
    ) {
        let record_exists = channel_registry.has_record(channel_key);

        assert!(record_exists, EChannelRecordDoesNotExist);

        channel_registry.registry.replace(channel_key, channel);
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(CHANNEL_REGISTRY {}, ctx);
    }
}
