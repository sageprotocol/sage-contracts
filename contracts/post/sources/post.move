module sage::post {
    use std::string::{String};

    use sui::clock::Clock;
    use sui::event;

    use sage::{
        channel::{Self, Channel},
        post_likes::{Self, PostLikesRegistry}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // const EPostNotOwned: u64 = 0;

    // --------------- Name Tag ---------------

    public struct Post has key, store {
        id: UID,
        created_at: u64,
        created_by: address,
        data: String,
        description: String,
        edited: bool,
        parent: ID,
        title: String,
        updated_at: u64
    }

    // --------------- Events ---------------

    public struct PostCreated has copy, drop {
        id: ID,
        created_at: u64,
        created_by: address,
        data: String,
        description: String,
        edited: bool,
        parent: ID,
        title: String,
        updated_at: u64
    }

    public struct PostLiked has copy, drop {
        id: ID,
        user: address
    }

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
            user
        );

        event::emit(PostLiked {
            id: post_id,
            user
        });
    }

    public fun post_from_channel(
        clock: &Clock,
        post_likes_registry: &mut PostLikesRegistry,
        channel: Channel,
        data: String,
        description: String,
        title: String,
        ctx: &mut TxContext
    ): Post {
        let parent = channel::get_id(channel);

        create(
            clock,
            post_likes_registry,
            data,
            description,
            parent,
            title,
            ctx
        )
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    fun create(
        clock: &Clock,
        post_likes_registry: &mut PostLikesRegistry,
        data: String,
        description: String,
        parent: ID,
        title: String,
        ctx: &mut TxContext
    ): Post {
        let uid = object::new(ctx);
        let user = tx_context::sender(ctx);

        let id = object::uid_to_inner(&uid);

        let timestamp = clock.timestamp_ms();

        let post = Post {
            id: uid,
            created_at: timestamp,
            created_by: user,
            data,
            description,
            edited: false,
            parent,
            title,
            updated_at: timestamp
        };

        post_likes::create(
            post_likes_registry,
            id,
            ctx
        );

        event::emit(PostCreated {
            id,
            created_at: timestamp,
            created_by: user,
            data,
            description,
            edited: false,
            parent,
            title,
            updated_at: timestamp
        });

        post
    }
}
