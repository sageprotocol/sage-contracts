module sage_post::post_likes {
    use sui::{
        table::{Self, Table}
    };

    // --------------- Constants ---------------

    const LIKE: u8 = 1;

    // --------------- Errors ---------------

    const EAlreadyLiked: u64 = 370;

    // --------------- Name Tag ---------------

    public struct Likes has store {
        likes: Table<address, u8>
    }

    // --------------- Events ---------------

    // public struct PostLiked has copy, drop {
    //     post_key: String,
    //     user: address
    // }

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun assert_has_not_liked(
        likes: &Likes,
        key: address
    ) {
        let has_liked = has_liked(
            likes,
            key
        );

        assert!(!has_liked, EAlreadyLiked);
    }

    public fun get_likes_length(
        likes: &Likes
    ): u64 {
        likes.likes.length()
    }

    public fun has_liked(
        likes: &Likes,
        key: address
    ): bool {
        likes.likes.contains(key)
    }

    // --------------- Friend Functions ---------------

    public(package) fun add(
        likes: &mut Likes,
        key: address
    ) {
        likes.likes.add(key, LIKE);
    }

    public(package) fun create(
        ctx: &mut TxContext
    ): Likes {
        let likes = Likes {
            likes: table::new(ctx)
        };

        likes
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
