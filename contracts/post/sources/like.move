module sage_post::post_likes {
    use std::string::{String};

    use sui::event;

    use sage_admin::{admin::{AdminCap}};

    use sage_immutable::{
        immutable_table::{Self, ImmutableTable},
        immutable_vector::{Self, ImmutableVector}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EUserAlreadyLiked: u64 = 0;

    // --------------- Name Tag ---------------

    public struct PostLikesRegistry has store {
        registry: ImmutableTable<String, PostLikes>
    }

    public struct PostLikes has store {
        likes: ImmutableVector<address>
    }

    public struct UserPostLikesRegistry has store {
        registry: ImmutableTable<address, UserPostLikes>
    }

    public struct UserPostLikes has store {
        likes: ImmutableVector<String>
    }

    // --------------- Events ---------------

    public struct PostLiked has copy, drop {
        key: String,
        user: address
    }

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun borrow_post_likes(
        post_likes_registry: &mut PostLikesRegistry,
        post_key: String
    ): &mut PostLikes {
        post_likes_registry.registry.borrow_mut(post_key)
    }

    public fun borrow_user_post_likes(
        user_post_likes_registry: &mut UserPostLikesRegistry,
        user: address
    ): &mut UserPostLikes {
        user_post_likes_registry.registry.borrow_mut(user)
    }

    public fun create_post_likes_registry(
        _: &AdminCap,
        ctx: &mut TxContext
    ): PostLikesRegistry {
        PostLikesRegistry {
            registry: immutable_table::new(ctx)
        }
    }

    public fun create_user_post_likes_registry(
        _: &AdminCap,
        ctx: &mut TxContext
    ): UserPostLikesRegistry {
        UserPostLikesRegistry {
            registry: immutable_table::new(ctx)
        }
    }

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

        let post_likes = borrow_post_likes(
            post_likes_registry,
            post_key
        );

        let user_post_likes = borrow_user_post_likes(
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
            key: post_key,
            user
        });
    }

    // --------------- Internal Functions ---------------

    fun create_post_likes(
        post_likes_registry: &mut PostLikesRegistry,
        post_key: String
    ) {
        let post_likes = PostLikes {
            likes: immutable_vector::empty<address>()
        };

        post_likes_registry.registry.add(post_key, post_likes);
    }

    fun create_user_post_likes(
        user_post_likes_registry: &mut UserPostLikesRegistry,
        user: address
    ) {
        let user_post_likes = UserPostLikes {
            likes: immutable_vector::empty<String>()
        };

        user_post_likes_registry.registry.add(user, user_post_likes);
    }

    // --------------- Test Functions ---------------

    #[test_only]
    public fun destroy_for_testing(
        post_likes_registry: PostLikesRegistry,
        user_post_likes_registry: UserPostLikesRegistry
    ) {
        let PostLikesRegistry {
            registry: post_likes_reg
        } = post_likes_registry;

        let UserPostLikesRegistry {
            registry: user_post_likes_reg
        } = user_post_likes_registry;

        post_likes_reg.destroy_for_testing();
        user_post_likes_reg.destroy_for_testing();
    }

}
