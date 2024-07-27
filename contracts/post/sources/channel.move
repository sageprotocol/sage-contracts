module sage_post::channel_posts {
    use std::string::{String};

    use sage_admin::{admin::{AdminCap}};

    use sage_channel::{channel::{Channel}};

    use sage_immutable::{
        immutable_table::{Self, ImmutableTable},
        immutable_vector::{Self, ImmutableVector}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EChannelPostsExists: u64 = 370;

    // --------------- Name Tag ---------------

    public struct ChannelPostsRegistry has store {
        registry: ImmutableTable<Channel, ImmutableVector<String>>
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun borrow_channel_post_keys(
        channel_posts_registry: &mut ChannelPostsRegistry,
        channel: Channel
    ): &mut ImmutableVector<String> {
        channel_posts_registry.registry.borrow_mut(channel)
    }

    public fun create_channel_posts_registry(
        _: &AdminCap,
        ctx: &mut TxContext
    ): ChannelPostsRegistry {
        ChannelPostsRegistry {
            registry: immutable_table::new(ctx)
        }
    }

    public fun has_post(
        channel_posts_registry: &mut ChannelPostsRegistry,
        channel: Channel,
        post_key: String
    ): bool {
        let channel_post_keys = *channel_posts_registry.registry.borrow(
            channel
        );

        channel_post_keys.contains(&post_key)
    }

    public fun has_record(
        channel_posts_registry: &ChannelPostsRegistry,
        channel: Channel
    ): bool {
        channel_posts_registry.registry.contains(channel)
    }

    // --------------- Friend Functions ---------------

    public(package) fun add(
        channel_posts_registry: &mut ChannelPostsRegistry,
        channel: Channel,
        post_key: String
    ) {
        let has_record = has_record(
            channel_posts_registry,
            channel
        );

        if (!has_record) {
            create(
                channel_posts_registry,
                channel
            );
        };

        let channel_post_keys = borrow_channel_post_keys(
            channel_posts_registry,
            channel
        );

        channel_post_keys.push_back(post_key);
    }

    // --------------- Internal Functions ---------------

    fun create(
        channel_posts_registry: &mut ChannelPostsRegistry,
        channel: Channel
    ) {
        let has_record = has_record(channel_posts_registry, channel);

        assert!(!has_record, EChannelPostsExists);

        let channel_post_keys = immutable_vector::empty();

        channel_posts_registry.registry.add(channel, channel_post_keys);
    }

    // --------------- Test Functions ---------------

    #[test_only]
    public fun destroy_for_testing(
        channel_posts_registry: ChannelPostsRegistry
    ) {
        let ChannelPostsRegistry {
            registry
        } = channel_posts_registry;

        registry.destroy_for_testing();
    }

}
