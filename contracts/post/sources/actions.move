module sage::post_actions {
    use std::string::{String};

    use sui::clock::Clock;

    use sage::{
        channel_posts::{Self, ChannelPostsRegistry},
        channel_registry::{Self, ChannelRegistry},
        post::{Self, Post},
        post_comments::{Self, PostCommentsRegistry},
        post_likes::{Self, PostLikesRegistry}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun like(
        post_likes_registry: &mut PostLikesRegistry,
        post_id: ID,
        ctx: &mut TxContext
    ) {
        let user = tx_context::sender(ctx);

        let post_likes = post_likes::get(
            post_likes_registry,
            post_id
        );

        post_likes::add(
            post_likes,
            post_id,
            user
        );
    }

    public fun post_from_channel(
        clock: &Clock,
        channel_registry: &mut ChannelRegistry,
        channel_posts_registry: &mut ChannelPostsRegistry,
        post_comments_registry: &mut PostCommentsRegistry,
        post_likes_registry: &mut PostLikesRegistry,
        channel_name: String,
        data: String,
        description: String,
        title: String,
        ctx: &mut TxContext
    ) {
        let channel_id = channel_registry::get_channel_id(
            channel_registry,
            channel_name
        );

        let post = create(
            clock,
            post_comments_registry,
            post_likes_registry,
            data,
            description,
            title,
            ctx
        );

        let channel_posts = channel_posts::get(
            channel_posts_registry,
            channel_id
        );

        channel_posts::add(
            channel_posts,
            channel_id,
            post
        );
    }

    public fun post_from_post(
        clock: &Clock,
        post_comments_registry: &mut PostCommentsRegistry,
        post_likes_registry: &mut PostLikesRegistry,
        original_post: Post,
        data: String,
        description: String,
        title: String,
        ctx: &mut TxContext
    ): UID {
        let (
            original_uid,
            original_id
        ) = post::get_id(original_post);

        let post = create(
            clock,
            post_comments_registry,
            post_likes_registry,
            data,
            description,
            title,
            ctx
        );

        let post_comments = post_comments::get(
            post_comments_registry,
            original_id
        );

        post_comments::add(
            post_comments,
            original_id,
            post
        );

        original_uid
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    public(package) fun create(
        clock: &Clock,
        post_comments_registry: &mut PostCommentsRegistry,
        post_likes_registry: &mut PostLikesRegistry,
        data: String,
        description: String,
        title: String,
        ctx: &mut TxContext
    ): Post {
        let user = tx_context::sender(ctx);

        let timestamp = clock.timestamp_ms();

        let (post, post_id) = post::create(
            user,
            data,
            description,
            title,
            timestamp,
            ctx
        );

        post_comments::create(
            post_comments_registry,
            post_id,
            ctx
        );

        post_likes::create(
            post_likes_registry,
            post_id,
            ctx
        );

        post
    }

    // --------------- Test Functions ---------------
}
