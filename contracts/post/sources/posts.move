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

    public fun borrow_channel_post(
        channel_posts: &mut ChannelPosts,
        post_id: ID
    ): &Post {
        channel_posts.posts.borrow_mut(post_id)
    }

    public fun create_channel_posts_registry(
        _: &AdminCap,
        ctx: &mut TxContext
    ): ChannelPostsRegistry {
        ChannelPostsRegistry {
            registry: table::new(ctx)
        }
    }

    public fun get_channel_posts(
        channel_posts_registry: &mut ChannelPostsRegistry,
        channel_id: ID
    ): &mut ChannelPosts {
        &mut channel_posts_registry.registry[channel_id]
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
        post_id: ID,
        post: Post
    ) {
        channel_posts.posts.add(post_id, post);
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

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public(package) fun destroy_for_testing(
        channel_posts_registry: ChannelPostsRegistry
    ) {
        let ChannelPostsRegistry {
            registry
        } = channel_posts_registry;

        registry.destroy_empty();
    }

}
