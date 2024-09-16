module sage_post::post_registry {
    use std::string::{String};

    use sui::package::{claim_and_keep};

    use sage_post::{post::{Post}};

    use sage_immutable::{immutable_table::{Self, ImmutableTable}};

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EPostRecordExists: u64 = 370;

    // --------------- Name Tag ---------------

    public struct PostRegistry has key, store {
        id: UID,
        registry: ImmutableTable<String, Post>
    }

    public struct POST_REGISTRY has drop {}

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    fun init(
        otw: POST_REGISTRY,
        ctx: &mut TxContext
    ) {
        claim_and_keep(otw, ctx);

        let post_registry = PostRegistry {
            id: object::new(ctx),
            registry: immutable_table::new(ctx)
        };

        transfer::share_object(post_registry);
    }

    // --------------- Public Functions ---------------

    public fun borrow_post(
        post_registry: &PostRegistry,
        post_key: String
    ): Post {
        *post_registry.registry.borrow(post_key)
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
    public fun init_for_testing(ctx: &mut TxContext) {
        init(POST_REGISTRY {}, ctx);
    }
}
