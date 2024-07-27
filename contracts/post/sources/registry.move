module sage_post::post_registry {
    use std::string::{String};

    use sage_admin::{admin::{AdminCap}};

    use sage_post::{post::{Post}};

    use sage_immutable::{immutable_table::{Self, ImmutableTable}};

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EPostRecordExists: u64 = 0;

    // --------------- Name Tag ---------------

    public struct PostRegistry has store {
        registry: ImmutableTable<String, Post>
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun borrow_post(
        post_registry: &mut PostRegistry,
        post_key: String
    ): Post {
        *post_registry.registry.borrow(post_key)
    }

    public fun create_post_registry(
        _: &AdminCap,
        ctx: &mut TxContext
    ): PostRegistry {
        PostRegistry {
            registry: immutable_table::new(ctx)
        }
    }

    public fun has_record(
        post_registry: &PostRegistry,
        post_key: String
    ): bool {
        post_registry.registry.contains(post_key)
    }

    // --------------- Friend Functions ---------------

    public(package) fun add(
        post_registry: &mut PostRegistry,
        post_key: String,
        post: Post
    ) {
        let record_exists = post_registry.has_record(post_key);

        assert!(!record_exists, EPostRecordExists);

        post_registry.registry.add(post_key, post);
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public fun destroy_for_testing(
        post_registry: PostRegistry
    ) {
        let PostRegistry {
            registry
        } = post_registry;

        registry.destroy_for_testing();
    }
}
