module sage_post::post_likes {
    use std::{
        string::{String}
    };

    use sui::{
        event,
        package::{claim_and_keep},
        table::{Self, Table}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EUserAlreadyLiked: u64 = 370;

    // --------------- Name Tag ---------------

    public struct PostLikesRegistry has key, store {
        id: UID,
        registry: Table<String, PostLikes>
    }

    public struct PostLikes has store {
        likes: vector<address>
    }

    public struct UserPostLikesRegistry has key, store {
        id: UID,
        registry: Table<address, UserPostLikes>
    }

    public struct UserPostLikes has store {
        likes: vector<String>
    }

    public struct POST_LIKES has drop {}

    // --------------- Events ---------------

    public struct PostLiked has copy, drop {
        post_key: String,
        user: address
    }

    // --------------- Constructor ---------------

    fun init(
        otw: POST_LIKES,
        ctx: &mut TxContext
    ) {
        claim_and_keep(otw, ctx);

        let post_likes_registry = PostLikesRegistry {
            id: object::new(ctx),
            registry: table::new(ctx)
        };
        let user_post_likes_registry = UserPostLikesRegistry {
            id: object::new(ctx),
            registry: table::new(ctx)
        };

        transfer::share_object(post_likes_registry);
        transfer::share_object(user_post_likes_registry);
    }

    // --------------- Public Functions ---------------

    public fun get_post_likes_count(
        post_likes: &PostLikes
    ): u64 {
        post_likes.likes.length()
    }

    public fun get_user_likes_count(
        user_likes: &UserPostLikes
    ): u64 {
        user_likes.likes.length()
    }

    public fun has_post_likes(
        post_likes: &PostLikes,
        user: address
    ): bool {
        post_likes.likes.contains(&user)
    }

    public fun has_user_likes(
        user_post_likes: &UserPostLikes,
        post_key: String
    ): bool {
        user_post_likes.likes.contains(&post_key)
    }

    public fun has_post_likes_record(
        post_likes_registry: &PostLikesRegistry,
        post_key: String
    ): bool {
        post_likes_registry.registry.contains(post_key)
    }

    public fun has_user_likes_record(
        user_post_likes_registry: &UserPostLikesRegistry,
        user: address
    ): bool {
        user_post_likes_registry.registry.contains(user)
    }

    // --------------- Friend Functions ---------------

    public(package) fun add(
        post_likes_registry: &mut PostLikesRegistry,
        user_post_likes_registry: &mut UserPostLikesRegistry,
        post_key: String,
        user: address
    ) {
        let has_record = has_post_likes_record(
            post_likes_registry,
            post_key
        );

        if (!has_record) {
            create_post_likes(
                post_likes_registry,
                post_key
            );
        };

        let has_record = has_user_likes_record(
            user_post_likes_registry,
            user
        );

        if (!has_record) {
            create_user_post_likes(
                user_post_likes_registry,
                user
            );
        };

        let post_likes = borrow_post_likes_mut(
            post_likes_registry,
            post_key
        );

        let user_post_likes = borrow_user_post_likes_mut(
            user_post_likes_registry,
            user
        );

        let has_liked = post_likes.has_post_likes(
            user
        );

        assert!(!has_liked, EUserAlreadyLiked);

        let has_liked = user_post_likes.has_user_likes(
            post_key
        );

        assert!(!has_liked, EUserAlreadyLiked);

        post_likes.likes.push_back(user);
        user_post_likes.likes.push_back(post_key);

        event::emit(PostLiked {
            post_key,
            user
        });
    }

    public(package) fun borrow_post_likes_mut(
        post_likes_registry: &mut PostLikesRegistry,
        post_key: String
    ): &mut PostLikes {
        post_likes_registry.registry.borrow_mut(post_key)
    }

    public(package) fun borrow_user_post_likes_mut(
        user_post_likes_registry: &mut UserPostLikesRegistry,
        user: address
    ): &mut UserPostLikes {
        user_post_likes_registry.registry.borrow_mut(user)
    }

    // --------------- Internal Functions ---------------

    fun create_post_likes(
        post_likes_registry: &mut PostLikesRegistry,
        post_key: String
    ) {
        let post_likes = PostLikes {
            likes: vector::empty<address>()
        };

        post_likes_registry.registry.add(post_key, post_likes);
    }

    fun create_user_post_likes(
        user_post_likes_registry: &mut UserPostLikesRegistry,
        user: address
    ) {
        let user_post_likes = UserPostLikes {
            likes: vector::empty<String>()
        };

        user_post_likes_registry.registry.add(user, user_post_likes);
    }

    // --------------- Test Functions ---------------

   #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(POST_LIKES {}, ctx);
    }
}
