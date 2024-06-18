module sage::post_comments {
    use sui::{table::{Self, Table}};

    use sage::{
        admin::{AdminCap}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    public struct PostCommentsRegistry has store {
        registry: Table<ID, PostComments>
    }

    public struct PostComments has store {
        comments: Table<ID, vector<u8>>
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun create_post_comments_registry(
        _: &AdminCap,
        ctx: &mut TxContext
    ): PostCommentsRegistry {
        PostCommentsRegistry {
            registry: table::new(ctx)
        }
    }

    // --------------- Friend Functions ---------------

    public(package) fun add(
        self: &mut PostComments,
        post_id: ID
    ) {
        self.comments.add(post_id, b"comment");
    }

    public(package) fun create(
        post_comments_registry: &mut PostCommentsRegistry,
        post_id: ID,
        ctx: &mut TxContext
    ) {
        let post_comments = PostComments {
            comments: table::new(ctx)
        };

        post_comments_registry.registry.add(post_id, post_comments);
    }

    public(package) fun get(
        post_comments_registry: &mut PostCommentsRegistry,
        post_id: ID
    ): &mut PostComments {
        &mut post_comments_registry.registry[post_id]
    }

    // --------------- Internal Functions ---------------

}
