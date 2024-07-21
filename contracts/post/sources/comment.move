module sage_post::post_comments {
    use std::string::{String};

    use sage_admin::{admin::{AdminCap}};

    use sage_immutable::{immutable_table::{Self, ImmutableTable}};

    use sage_post::{post::{Post}};

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EPostCommentsExists: u64 = 0;

    // --------------- Name Tag ---------------

    public struct PostCommentsRegistry has store {
        registry: ImmutableTable<String, PostComments>
    }

    public struct PostComments has store {
        comments: ImmutableTable<String, Post>
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun create_post_comments_registry(
        _: &AdminCap,
        ctx: &mut TxContext
    ): PostCommentsRegistry {
        PostCommentsRegistry {
            registry: immutable_table::new(ctx)
        }
    }

    public fun get_post_comments(
        post_comments_registry: &mut PostCommentsRegistry,
        post_key: String
    ): &mut PostComments {
        post_comments_registry.registry.borrow_mut(post_key)
    }

    public fun has_post(
        post_comments: &mut PostComments,
        post_key: String
    ): bool {
        post_comments.comments.contains(post_key)
    }

    public fun has_record(
        post_comments_registry: &PostCommentsRegistry,
        post_key: String
    ): bool {
        post_comments_registry.registry.contains(post_key)
    }

    // --------------- Friend Functions ---------------

    public(package) fun add(
        post_comments: &mut PostComments,
        post_key: String,
        post: Post
    ) {
        post_comments.comments.add(post_key, post);
    }

    public(package) fun create(
        post_comments_registry: &mut PostCommentsRegistry,
        post_key: String,
        ctx: &mut TxContext
    ) {
        let has_record = has_record(post_comments_registry, post_key);

        assert!(!has_record, EPostCommentsExists);

        let post_comments = PostComments {
            comments: immutable_table::new(ctx)
        };

        post_comments_registry.registry.add(post_key, post_comments);
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

        registry.destroy_for_testing();
    }
}
