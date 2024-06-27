module sage::post_comments {
    use sui::{table::{Self, Table}};

    use sage::{
        admin::{AdminCap},
        post::{Post}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EPostCommentsExists: u64 = 0;

    // --------------- Name Tag ---------------

    public struct PostCommentsRegistry has store {
        registry: Table<ID, PostComments>
    }

    public struct PostComments has store {
        comments: Table<ID, Post>
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

    public fun get_post_comments(
        post_comments_registry: &mut PostCommentsRegistry,
        post_id: ID
    ): &mut PostComments {
        &mut post_comments_registry.registry[post_id]
    }

    public fun has_record(
        post_comments_registry: &PostCommentsRegistry,
        post_id: ID
    ): bool {
        post_comments_registry.registry.contains(post_id)
    }

    // --------------- Friend Functions ---------------

    public(package) fun add(
        post_comments: &mut PostComments,
        post_id: ID,
        post: Post
    ) {
        post_comments.comments.add(post_id, post);
    }

    public(package) fun create(
        post_comments_registry: &mut PostCommentsRegistry,
        post_id: ID,
        ctx: &mut TxContext
    ) {
        let has_record = has_record(post_comments_registry, post_id);

        assert!(!has_record, EPostCommentsExists);

        let post_comments = PostComments {
            comments: table::new(ctx)
        };

        post_comments_registry.registry.add(post_id, post_comments);
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public fun destroy_for_testing(
        post_comments_registry: PostCommentsRegistry
    ) {
        let PostCommentsRegistry {
            registry
        } = post_comments_registry;

        registry.destroy_empty();
    }

}
