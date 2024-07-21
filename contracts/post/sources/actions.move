module sage_post::post_actions {
    use std::string::{String};

    use sui::clock::Clock;
    use sui::event;

    use sage_channel::{
        channel_membership::{Self, ChannelMembershipRegistry},
        channel_registry::{Self, ChannelRegistry}
    };

    use sage_post::{
        channel_posts::{Self, ChannelPostsRegistry},
        post::{Self, Post},
        post_comments::{Self, PostCommentsRegistry},
        post_likes::{Self, PostLikesRegistry, UserPostLikesRegistry},
        user_posts::{Self, UserPostsRegistry}
    };

    use sage_user::{
        user_registry::{Self, UserRegistry}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EUserNotChannelMember: u64 = 0;

    // --------------- Name Tag ---------------

    // --------------- Events ---------------

    public struct ChannelPostCreated has copy, drop {
        key: String,
        channel_name: String,
        created_at: u64,
        created_by: address,
        data: String,
        description: String,
        title: String,
        updated_at: u64
    }

    public struct CommentCreated has copy, drop {
        key: String,
        created_at: u64,
        created_by: address,
        data: String,
        description: String,
        parent_post_key: String,
        title: String,
        updated_at: u64
    }

    public struct UserPostCreated has copy, drop {
        key: String,
        created_at: u64,
        created_by: address,
        data: String,
        description: String,
        title: String,
        updated_at: u64
    }

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun like(
        post_likes_registry: &mut PostLikesRegistry,
        user_post_likes_registry: &mut UserPostLikesRegistry,
        post: Post,
        ctx: &mut TxContext
    ) {
        let user = tx_context::sender(ctx);

        let post_key = post::get_key(post);

        let post_likes = post_likes::get_post_likes(
            post_likes_registry,
            post_key
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
            post_key,
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
    ): String {
        let user = tx_context::sender(ctx);

        let channel = channel_registry::get_channel(
            channel_registry,
            channel_name
        );

        let channel_membership = channel_membership::borrow_membership_mut(
            channel_membership_registry,
            channel
        );

        let is_member = channel_membership::is_member(
            channel_membership,
            user
        );

        assert!(is_member, EUserNotChannelMember);

        let timestamp = clock.timestamp_ms();

        let (post, post_key) = create(
            post_comments_registry,
            post_likes_registry,
            data,
            description,
            title,
            timestamp,
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
            post_key,
            post
        );

        event::emit(ChannelPostCreated {
            key: post_key,
            channel_name,
            created_at: timestamp,
            created_by: user,
            data,
            description,
            title,
            updated_at: timestamp
        });

        post_key
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
    ): String {
        let parent_key = post::get_key(parent_post);

        let timestamp = clock.timestamp_ms();
        let user = tx_context::sender(ctx);

        let (post, post_key) = create(
            post_comments_registry,
            post_likes_registry,
            data,
            description,
            title,
            timestamp,
            ctx
        );

        let has_record = post_comments::has_record(
            post_comments_registry,
            parent_key
        );

        if (!has_record) {
            post_comments::create(
                post_comments_registry,
                parent_key,
                ctx
            );
        };

        let post_comments = post_comments::get_post_comments(
            post_comments_registry,
            parent_key
        );

        post_comments::add(
            post_comments,
            post_key,
            post
        );

        event::emit(CommentCreated {
            key: post_key,
            created_at: timestamp,
            created_by: user,
            data,
            description,
            parent_post_key: parent_key,
            title,
            updated_at: timestamp
        });

        post_key
    }

    public fun post_from_user(
        clock: &Clock,
        post_comments_registry: &mut PostCommentsRegistry,
        post_likes_registry: &mut PostLikesRegistry,
        user_posts_registry: &mut UserPostsRegistry,
        user_registry: &mut UserRegistry,
        data: String,
        description: String,
        title: String,
        ctx: &mut TxContext
    ): String {
        let address = tx_context::sender(ctx);

        let username = user_registry::get_username(
            user_registry,
            address
        );

        let user = user_registry::get_user(
            user_registry,
            username
        );

        let timestamp = clock.timestamp_ms();

        let (post, post_key) = create(
            post_comments_registry,
            post_likes_registry,
            data,
            description,
            title,
            timestamp,
            ctx
        );

        let has_record = user_posts::has_record(
            user_posts_registry,
            user
        );

        if (!has_record) {
            user_posts::create(
                user_posts_registry,
                user,
                ctx
            );
        };

        let user_posts = user_posts::get_user_posts(
            user_posts_registry,
            user
        );

        user_posts::add(
            user_posts,
            post_key,
            post
        );

        event::emit(UserPostCreated {
            key: post_key,
            created_at: timestamp,
            created_by: address,
            data,
            description,
            title,
            updated_at: timestamp
        });

        post_key
    }

    // --------------- Friend Functions ---------------

    public(package) fun create(
        post_comments_registry: &mut PostCommentsRegistry,
        post_likes_registry: &mut PostLikesRegistry,
        data: String,
        description: String,
        title: String,
        timestamp: u64,
        ctx: &mut TxContext
    ): (Post, String) {
        let user = tx_context::sender(ctx);

        let (post, post_key) = post::create(
            user,
            data,
            description,
            title,
            timestamp,
            ctx
        );

        post_comments::create(
            post_comments_registry,
            post_key,
            ctx
        );

        post_likes::create_post_likes(
            post_likes_registry,
            post_key
        );

        (post, post_key)
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
