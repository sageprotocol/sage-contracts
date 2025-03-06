module sage_shared::likes {
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

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun add(
        likes: &mut Likes,
        key: address
    ) {
        likes.likes.add(key, LIKE);
    }

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

    public fun create(
        ctx: &mut TxContext
    ): Likes {
        let likes = Likes {
            likes: table::new(ctx)
        };

        likes
    }

    public fun get_length(
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

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
