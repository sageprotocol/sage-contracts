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
        post::{Self},
        post_comments::{Self, PostCommentsRegistry},
        post_likes::{Self, PostLikesRegistry, UserPostLikesRegistry},
        post_registry::{Self, PostRegistry},
        user_posts::{Self, UserPostsRegistry}
    };

    use sage_user::{
        user_registry::{Self, UserRegistry}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EChannelDoesNotExist: u64 = 370;
    const EParentPostDoesNotExist: u64 = 371;
    const EPostDoesNotExist: u64 = 372;
    const EUserDoesNotExist: u64 = 373;
    const EUserNotChannelMember: u64 = 374;

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
        post_registry: &mut PostRegistry,
        post_likes_registry: &mut PostLikesRegistry,
        user_post_likes_registry: &mut UserPostLikesRegistry,
        post_key: String,
        ctx: &mut TxContext
    ) {
        let has_record = post_registry::has_record(
            post_registry,
            post_key
        );

        assert!(has_record, EPostDoesNotExist);

        let user = tx_context::sender(ctx);

        post_likes::add(
            post_likes_registry,
            user_post_likes_registry,
            post_key,
            user
        );
    }

    public fun post_from_channel(
        clock: &Clock,
        channel_registry: &mut ChannelRegistry,
        channel_membership_registry: &mut ChannelMembershipRegistry,
        channel_posts_registry: &mut ChannelPostsRegistry,
        post_registry: &mut PostRegistry,
        channel_name: String,
        data: String,
        description: String,
        title: String,
        ctx: &mut TxContext
    ): String {
        let has_record = channel_registry::has_record(
            channel_registry,
            channel_name
        );

        assert!(has_record, EChannelDoesNotExist);

        let channel = channel_registry::borrow_channel(
            channel_registry,
            channel_name
        );

        let channel_membership = channel_membership::borrow_membership_mut(
            channel_membership_registry,
            channel
        );

        let user = tx_context::sender(ctx);

        let is_member = channel_membership::is_member(
            channel_membership,
            user
        );

        assert!(is_member, EUserNotChannelMember);

        let timestamp = clock.timestamp_ms();

        let (post, post_key) = post::create(
            user,
            data,
            description,
            title,
            timestamp,
            ctx
        );

        post_registry::add(
            post_registry,
            post_key,
            post
        );

        channel_posts::add(
            channel_posts_registry,
            channel,
            post_key
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
        post_registry: &mut PostRegistry,
        post_comments_registry: &mut PostCommentsRegistry,
        parent_key: String,
        data: String,
        description: String,
        title: String,
        ctx: &mut TxContext
    ): String {
        let timestamp = clock.timestamp_ms();
        let user = tx_context::sender(ctx);

        let has_record = post_registry::has_record(
            post_registry,
            parent_key
        );

        assert!(has_record, EParentPostDoesNotExist);

        let (post, post_key) = post::create(
            user,
            data,
            description,
            title,
            timestamp,
            ctx
        );

        post_registry::add(
            post_registry,
            post_key,
            post
        );

        post_comments::add(
            post_comments_registry,
            parent_key,
            post_key
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
        post_registry: &mut PostRegistry,
        user_posts_registry: &mut UserPostsRegistry,
        user_registry: &mut UserRegistry,
        data: String,
        description: String,
        title: String,
        ctx: &mut TxContext
    ): String {
        let address = tx_context::sender(ctx);

        let has_record = user_registry::has_address_record(
            user_registry,
            address
        );

        assert!(has_record, EUserDoesNotExist);

        let username = user_registry::borrow_username(
            user_registry,
            address
        );

        let user = user_registry::borrow_user(
            user_registry,
            username
        );

        let timestamp = clock.timestamp_ms();

        let (post, post_key) = post::create(
            address,
            data,
            description,
            title,
            timestamp,
            ctx
        );

        post_registry::add(
            post_registry,
            post_key,
            post
        );

        user_posts::add(
            user_posts_registry,
            user,
            post_key
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

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
