module sage_post::channel_posts {
    use std::{
        string::{String}
    };

    use sui::{
        package::{claim_and_keep},
        table::{Self, Table}
    };

    use sage_channel::{
        channel::{
            Self,
            Channel
        }
    };

    use sage_utils::{
        string_helpers::{Self}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EChannelPostsExists: u64 = 370;

    // --------------- Name Tag ---------------

    // channel key <-> post keys
    public struct ChannelPostsRegistry has key, store {
        id: UID,
        registry: Table<String, vector<String>>
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
        channel_posts_registry: &ChannelPostsRegistry,
        channel: &Channel,
        post_key: String
    ): bool {
        let channel_name = channel::get_name(channel);
        let channel_key = string_helpers::to_lowercase(&channel_name);

        let channel_post_keys = *channel_posts_registry.registry.borrow(
            channel_key
        );

        channel_post_keys.contains(&post_key)
    }

    public fun has_record(
        channel_posts_registry: &ChannelPostsRegistry,
        channel: &Channel
    ): bool {
        let channel_name = channel::get_name(channel);
        let channel_key = string_helpers::to_lowercase(&channel_name);

        channel_posts_registry.registry.contains(channel_key)
    }

    // --------------- Friend Functions ---------------

    public(package) fun add(
        channel_posts_registry: &mut ChannelPostsRegistry,
        channel: &Channel,
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

        let channel_name = channel::get_name(channel);
        let channel_key = string_helpers::to_lowercase(&channel_name);

        let channel_post_keys = borrow_channel_post_keys_mut(
            channel_posts_registry,
            channel_key
        );

        channel_post_keys.push_back(post_key);
    }

    public(package) fun borrow_channel_post_keys_mut(
        channel_posts_registry: &mut ChannelPostsRegistry,
        channel_key: String
    ): &mut vector<String> {
        channel_posts_registry.registry.borrow_mut(channel_key)
    }

    // --------------- Internal Functions ---------------

    fun create(
        channel_posts_registry: &mut ChannelPostsRegistry,
        channel: &Channel
    ) {
        let has_record = has_record(channel_posts_registry, channel);

        assert!(!has_record, EChannelPostsExists);

        let channel_post_keys = vector::empty();

        let channel_name = channel::get_name(channel);
        let channel_key = string_helpers::to_lowercase(&channel_name);

        channel_posts_registry.registry.add(
            channel_key,
            channel_post_keys
        );
    }

    // --------------- Test Functions ---------------

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(CHANNEL_POSTS {}, ctx);
    }
}
