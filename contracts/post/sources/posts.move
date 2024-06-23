module sage::channel_posts {
    use sui::{table::{Self, Table}};

    use sage::{
        admin::{AdminCap},
        post::{Post}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EChannelPostsExists: u64 = 0;

    // --------------- Name Tag ---------------

    public struct ChannelPostsRegistry has store {
        registry: Table<ID, ChannelPosts>
    }

    public struct ChannelPosts has store {
        posts: Table<ID, Post>
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun create_channel_posts_registry(
        _: &AdminCap,
        ctx: &mut TxContext
    ): ChannelPostsRegistry {
        ChannelPostsRegistry {
            registry: table::new(ctx)
        }
    }

    public fun has_record(
        channel_posts_registry: &ChannelPostsRegistry,
        channel_id: ID
    ): bool {
        channel_posts_registry.registry.contains(channel_id)
    }

    // --------------- Friend Functions ---------------

    public(package) fun add(
        channel_posts: &mut ChannelPosts,
        channel_id: ID,
        post: Post
    ) {
        channel_posts.posts.add(channel_id, post);
    }

    public(package) fun create(
        channel_posts_registry: &mut ChannelPostsRegistry,
        channel_id: ID,
        ctx: &mut TxContext
    ) {
        let has_record = has_record(channel_posts_registry, channel_id);

        assert!(!has_record, EChannelPostsExists);

        let channel_posts = ChannelPosts {
            posts: table::new(ctx)
        };

        channel_posts_registry.registry.add(channel_id, channel_posts);
    }

    public(package) fun get(
        channel_posts_registry: &mut ChannelPostsRegistry,
        channel_id: ID
    ): &mut ChannelPosts {
        &mut channel_posts_registry.registry[channel_id]
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public fun destroy_for_testing(
        channel_posts_registry: ChannelPostsRegistry
    ) {
        let ChannelPostsRegistry {
            registry
        } = channel_posts_registry;

        registry.destroy_empty();
    }

}
