module sage_post::post_comments {
    use std::string::{String};

    use sage_admin::{admin::{AdminCap}};

    use sage_immutable::{
        immutable_table::{Self, ImmutableTable},
        immutable_vector::{Self, ImmutableVector}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EPostCommentsExists: u64 = 370;

    // --------------- Name Tag ---------------

    public struct PostCommentsRegistry has store {
        registry: ImmutableTable<String, ImmutableVector<String>>
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun borrow_post_comment_keys(
        post_comments_registry: &mut PostCommentsRegistry,
        post_key: String
    ): &mut ImmutableVector<String> {
        post_comments_registry.registry.borrow_mut(post_key)
    }

    public fun create_post_comments_registry(
        _: &AdminCap,
        ctx: &mut TxContext
    ): PostCommentsRegistry {
        PostCommentsRegistry {
            registry: immutable_table::new(ctx)
        }
    }

    public fun has_post(
        post_comments_registry: &mut PostCommentsRegistry,
        parent_post_key: String,
        post_key: String
    ): bool {
        let parent_post_comment_keys = *post_comments_registry.registry.borrow(
            parent_post_key
        );

        parent_post_comment_keys.contains(&post_key)
    }

    public fun has_record(
        post_comments_registry: &PostCommentsRegistry,
        post_key: String
    ): bool {
        post_comments_registry.registry.contains(post_key)
    }

    // --------------- Friend Functions ---------------

    public(package) fun add(
        post_comments_registry: &mut PostCommentsRegistry,
        parent_post_key: String,
        post_key: String
    ) {
        let has_record = has_record(
            post_comments_registry,
            parent_post_key
        );

        if (!has_record) {
            create(
                post_comments_registry,
                parent_post_key
            );
        };

        let parent_post_comment_keys = borrow_post_comment_keys(
            post_comments_registry,
            parent_post_key
        );

        parent_post_comment_keys.push_back(post_key);
    }

    // --------------- Internal Functions ---------------

    fun create(
        post_comments_registry: &mut PostCommentsRegistry,
        parent_post_key: String
    ) {
        let has_record = has_record(
            post_comments_registry,
            parent_post_key
        );

        assert!(!has_record, EPostCommentsExists);

        let parent_post_comment_keys = immutable_vector::empty();

        post_comments_registry.registry.add(parent_post_key, parent_post_comment_keys);
    }

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
