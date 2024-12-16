module sage_post::channel_posts {
    use std::{
        string::{String}
    };

    use sui::{
        package::{claim_and_keep},
        table::{Self, Table}
    };

    use sage_channel::{
        channel::{Channel}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EChannelPostsExists: u64 = 370;

    // --------------- Name Tag ---------------

    public struct ChannelPostsRegistry has key, store {
        id: UID,
        registry: Table<Channel, vector<String>>
    }

    public struct CHANNEL_POSTS has drop {}

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    fun init(
        otw: CHANNEL_POSTS,
        ctx: &mut TxContext
    ) {
        claim_and_keep(otw, ctx);

        let post_registry = ChannelPostsRegistry {
            id: object::new(ctx),
            registry: table::new(ctx)
        };

        transfer::share_object(post_registry);
    }

    // --------------- Public Functions ---------------

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

        let channel_post_keys = borrow_channel_post_keys_mut(
            channel_posts_registry,
            channel
        );

        channel_post_keys.push_back(post_key);
    }

    public(package) fun borrow_channel_post_keys_mut(
        channel_posts_registry: &mut ChannelPostsRegistry,
        channel: Channel
    ): &mut vector<String> {
        channel_posts_registry.registry.borrow_mut(channel)
    }

    // --------------- Internal Functions ---------------

    fun create(
        channel_posts_registry: &mut ChannelPostsRegistry,
        channel: Channel
    ) {
        let has_record = has_record(channel_posts_registry, channel);

        assert!(!has_record, EChannelPostsExists);

        let channel_post_keys = vector::empty();

        channel_posts_registry.registry.add(channel, channel_post_keys);
    }

    // --------------- Test Functions ---------------

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(CHANNEL_POSTS {}, ctx);
    }
}
