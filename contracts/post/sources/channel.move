module sage_post::channel_posts {
    use std::string::{String};

    use sage_admin::{admin::{AdminCap}};

    use sage_channel::{channel::{Channel}};

    use sage_immutable::{immutable_table::{Self, ImmutableTable}};

    use sage_post::{post::{Post}};

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EChannelPostsExists: u64 = 0;

    // --------------- Name Tag ---------------

    public struct ChannelPostsRegistry has store {
        registry: ImmutableTable<Channel, ChannelPosts>
    }

    public struct ChannelPosts has store {
        posts: ImmutableTable<String, Post>
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun borrow_post(
        channel_posts: &mut ChannelPosts,
        post_key: String
    ): Post {
        *channel_posts.posts.borrow(post_key)
    }

    public fun create_channel_posts_registry(
        _: &AdminCap,
        ctx: &mut TxContext
    ): ChannelPostsRegistry {
        ChannelPostsRegistry {
            registry: immutable_table::new(ctx)
        }
    }

    public fun get_channel_posts(
        channel_posts_registry: &mut ChannelPostsRegistry,
        channel: Channel
    ): &mut ChannelPosts {
        channel_posts_registry.registry.borrow_mut(channel)
    }

    public fun has_post(
        channel_posts: &mut ChannelPosts,
        post_key: String
    ): bool {
        channel_posts.posts.contains(post_key)
    }

    public fun has_record(
        channel_posts_registry: &ChannelPostsRegistry,
        channel: Channel
    ): bool {
        channel_posts_registry.registry.contains(channel)
    }

    // --------------- Friend Functions ---------------

    public(package) fun add(
        channel_posts: &mut ChannelPosts,
        post_key: String,
        post: Post
    ) {
        channel_posts.posts.add(post_key, post);
    }

    public(package) fun create(
        channel_posts_registry: &mut ChannelPostsRegistry,
        channel: Channel,
        ctx: &mut TxContext
    ) {
        let has_record = has_record(channel_posts_registry, channel);

        assert!(!has_record, EChannelPostsExists);

        let channel_posts = ChannelPosts {
            posts: immutable_table::new(ctx)
        };

        channel_posts_registry.registry.add(channel, channel_posts);
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

        registry.destroy_for_testing();
    }

}
