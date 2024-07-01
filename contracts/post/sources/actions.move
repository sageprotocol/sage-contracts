module sage_post::post_actions {
    use std::string::{String};

    use sui::clock::Clock;

    use sage_channel::{
        channel_membership::{Self, ChannelMembershipRegistry},
        channel_registry::{Self, ChannelRegistry}
    };

    use sage_post::{
        channel_posts::{Self, ChannelPostsRegistry},
        post::{Self, Post},
        post_comments::{Self, PostCommentsRegistry},
        post_likes::{Self, PostLikesRegistry, UserPostLikesRegistry}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EUserNotChannelMember: u64 = 0;

    // --------------- Name Tag ---------------

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun like(
        post_likes_registry: &mut PostLikesRegistry,
        user_post_likes_registry: &mut UserPostLikesRegistry,
        post_id: ID,
        ctx: &mut TxContext
    ) {
        let user = tx_context::sender(ctx);

        let post_likes = post_likes::get_post_likes(
            post_likes_registry,
            post_id
        );

        let has_user_likes = post_likes::has_user_likes_record(
            user_post_likes_registry,
            user
        );

        if (!has_user_likes) {
            post_likes::create_user_post_likes(
                user_post_likes_registry,
                user
            );
        };

        let user_post_likes = post_likes::get_user_post_likes(
            user_post_likes_registry,
            user
        );

        post_likes::add(
            post_likes,
            user_post_likes,
            post_id,
            user
        );
    }

    public fun post_from_channel(
        clock: &Clock,
        channel_registry: &mut ChannelRegistry,
        channel_membership_registry: &mut ChannelMembershipRegistry,
        channel_posts_registry: &mut ChannelPostsRegistry,
        post_comments_registry: &mut PostCommentsRegistry,
        post_likes_registry: &mut PostLikesRegistry,
        channel_name: String,
        data: String,
        description: String,
        title: String,
        ctx: &mut TxContext
    ): ID {
        let user = tx_context::sender(ctx);

        let channel = channel_registry::get_channel(
            channel_registry,
            channel_name
        );

        let channel_membership = channel_membership::get_membership(
            channel_membership_registry,
            channel
        );

        let is_member = channel_membership::is_member(
            channel_membership,
            user
        );

        assert!(is_member, EUserNotChannelMember);

        let (post, post_id) = create(
            clock,
            post_comments_registry,
            post_likes_registry,
            data,
            description,
            title,
            ctx
        );

        let has_record = channel_posts::has_record(
            channel_posts_registry,
            channel
        );

        if (!has_record) {
            channel_posts::create(
                channel_posts_registry,
                channel,
                ctx
            );
        };

        let channel_posts = channel_posts::get_channel_posts(
            channel_posts_registry,
            channel
        );

        channel_posts::add(
            channel_posts,
            post_id,
            post
        );

        post_id
    }

    public fun post_from_post(
        clock: &Clock,
        post_comments_registry: &mut PostCommentsRegistry,
        post_likes_registry: &mut PostLikesRegistry,
        parent_post: Post,
        data: String,
        description: String,
        title: String,
        ctx: &mut TxContext
    ): ID {
        let parent_id = post::get_id(parent_post);

        let (post, post_id) = create(
            clock,
            post_comments_registry,
            post_likes_registry,
            data,
            description,
            title,
            ctx
        );

        let has_record = post_comments::has_record(
            post_comments_registry,
            parent_id
        );

        if (!has_record) {
            post_comments::create(
                post_comments_registry,
                parent_id,
                ctx
            );
        };

        let post_comments = post_comments::get_post_comments(
            post_comments_registry,
            parent_id
        );

        post_comments::add(
            post_comments,
            post_id,
            post
        );

        post_id
    }

    // --------------- Friend Functions ---------------

    public(package) fun create(
        clock: &Clock,
        post_comments_registry: &mut PostCommentsRegistry,
        post_likes_registry: &mut PostLikesRegistry,
        data: String,
        description: String,
        title: String,
        ctx: &mut TxContext
    ): (Post, ID) {
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

        post_likes::create_post_likes(
            post_likes_registry,
            post_id
        );

        (post, post_id)
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
