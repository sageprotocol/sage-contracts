module sage::post_likes {
    use sui::{table::{Self, Table}};

    use sage::{
        admin::{AdminCap}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EUserAlreadyLiked: u64 = 0;

    // --------------- Name Tag ---------------

    public struct PostLikesRegistry has store {
        registry: Table<ID, PostLikes>
    }

    public struct PostLikes has store {
        likes: Table<address, vector<u8>>
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun create_post_likes_registry(
        _: &AdminCap,
        ctx: &mut TxContext
    ): PostLikesRegistry {
        PostLikesRegistry {
            registry: table::new(ctx)
        }
    }

    public fun has_record(
        self: &PostLikes,
        user: address
    ): bool {
        self.likes.contains(user)
    }

    // --------------- Friend Functions ---------------

    public(package) fun add(
        self: &mut PostLikes,
        user: address
    ) {
        let has_liked = self.has_record(
            user
        );

        assert!(!has_liked, EUserAlreadyLiked);

        self.likes.add(user, b"likes");
    }

    public(package) fun create(
        post_likes_registry: &mut PostLikesRegistry,
        post_id: ID,
        ctx: &mut TxContext
    ) {
        let post_likes = PostLikes {
            likes: table::new(ctx)
        };

        post_likes_registry.registry.add(post_id, post_likes);
    }

    public(package) fun get(
        post_likes_registry: &mut PostLikesRegistry,
        post_id: ID
    ): &mut PostLikes {
        &mut post_likes_registry.registry[post_id]
    }

    // --------------- Internal Functions ---------------

}
