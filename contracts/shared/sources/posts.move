module sage_shared::posts {
    use sui::{
        table::{Self, Table}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    public struct Posts has store {
        posts: Table<u64, address>
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun add(
        posts: &mut Posts,
        post_timestamp: u64,
        post_address: address
    ) {
        posts.posts.add(
            post_timestamp, 
            post_address
        );
    }

    public fun create(
        ctx: &mut TxContext
    ): Posts {
        Posts {
            posts: table::new(ctx)
        }
    }

    public fun get_length(
        posts: &Posts
    ): u64 {
        posts.posts.length()
    }

    public fun has_record(
        posts: &Posts,
        post_timestamp: u64
    ): bool {
        posts.posts.contains(post_timestamp)
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
