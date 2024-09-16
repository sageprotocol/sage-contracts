module sage_channel::channel_registry {
    use std::string::{String};

    use sui::package::{claim_and_keep};

    use sage_channel::{channel::{Channel}};

    use sage_immutable::{immutable_table::{Self, ImmutableTable}};

    use sage_utils::{
        string_helpers::{Self}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EChannelRecordExists: u64 = 370;

    // --------------- Name Tag ---------------

    public struct ChannelRegistry has key, store {
        id: UID,
        registry: ImmutableTable<String, Channel>,
        reverse_registry: ImmutableTable<Channel, String>
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
            registry: immutable_table::new(ctx),
            reverse_registry: immutable_table::new(ctx)
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

    public fun borrow_channel_key(
        channel_registry: &mut ChannelRegistry,
        channel: Channel
    ): String {
        *channel_registry.reverse_registry.borrow(channel)
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
        name: String,
        channel: Channel
    ) {
        let record_exists = channel_registry.has_record(name);

        assert!(!record_exists, EChannelRecordExists);

        let lowercase_name = string_helpers::to_lowercase(
            &name
        );

        channel_registry.registry.add(lowercase_name, channel);
        channel_registry.reverse_registry.add(channel, lowercase_name);
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(CHANNEL_REGISTRY {}, ctx);
    }
}
