module sage_channel::channel_registry {
    use std::string::{String};

    use sage_admin::{admin::{AdminCap}};

    use sage_channel::{channel::{Channel}};

    use sage_immutable::{immutable_table::{Self, ImmutableTable}};

    use sage_utils::{
        string_helpers::{Self}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EChannelRecordExists: u64 = 370;

    // --------------- Name Tag ---------------

    public struct ChannelRegistry has store {
        registry: ImmutableTable<String, Channel>,
        reverse_registry: ImmutableTable<Channel, String>
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun borrow_channel(
        channel_registry: &mut ChannelRegistry,
        channel_name: String
    ): Channel {
        *channel_registry.registry.borrow(channel_name)
    }

    public fun borrow_channel_name(
        channel_registry: &mut ChannelRegistry,
        channel: Channel
    ): String {
        *channel_registry.reverse_registry.borrow(channel)
    }

    public fun create_channel_registry(
        _: &AdminCap,
        ctx: &mut TxContext
    ): ChannelRegistry {
        ChannelRegistry {
            registry: immutable_table::new(ctx),
            reverse_registry: immutable_table::new(ctx)
        }
    }

    public fun has_record(
        channel_registry: &ChannelRegistry,
        channel_name: String
    ): bool {
        channel_registry.registry.contains(channel_name)
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
    public fun destroy_for_testing(
        channel_registry: ChannelRegistry
    ) {
        let ChannelRegistry {
            registry,
            reverse_registry
        } = channel_registry;

        registry.destroy_for_testing();
        reverse_registry.destroy_for_testing();
    }
}
