module sage_post::user_posts {
    use std::string::{String};

    use sui::package::{claim_and_keep};

    use sage_immutable::{
        immutable_table::{Self, ImmutableTable},
        immutable_vector::{Self, ImmutableVector}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EUserPostsExists: u64 = 370;

    // --------------- Name Tag ---------------

    // user key <-> post keys
    public struct UserPostsRegistry has key, store {
        id: UID,
        registry: ImmutableTable<String, ImmutableVector<String>>
    }

    public struct USER_POSTS has drop {}

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    fun init(
        otw: USER_POSTS,
        ctx: &mut TxContext
    ) {
        claim_and_keep(otw, ctx);

        let user_post_registry = UserPostsRegistry {
            id: object::new(ctx),
            registry: immutable_table::new(ctx)
        };

        transfer::share_object(user_post_registry);
    }

    // --------------- Public Functions ---------------

    public fun has_post(
        user_posts_registry: &mut UserPostsRegistry,
        user_key: String,
        post_key: String
    ): bool {
        let user_post_keys = *user_posts_registry.registry.borrow(
            user_key
        );

        user_post_keys.contains(&post_key)
    }

    public fun has_record(
        user_posts_registry: &UserPostsRegistry,
        user_key: String
    ): bool {
        user_posts_registry.registry.contains(user_key)
    }

    // --------------- Friend Functions ---------------

    public(package) fun add(
        user_posts_registry: &mut UserPostsRegistry,
        user_key: String,
        post_key: String
    ) {
        let has_record = has_record(
            user_posts_registry,
            user_key
        );

        if (!has_record) {
            create(
                user_posts_registry,
                user_key
            );
        };

        let user_post_keys = borrow_user_post_keys_mut(
            user_posts_registry,
            user_key
        );

        user_post_keys.push_back(post_key);
    }

    public(package) fun borrow_user_post_keys_mut(
        user_posts_registry: &mut UserPostsRegistry,
        user_key: String
    ): &mut ImmutableVector<String> {
        user_posts_registry.registry.borrow_mut(user_key)
    }

    // --------------- Internal Functions ---------------

    fun create(
        user_posts_registry: &mut UserPostsRegistry,
        user_key: String
    ) {
        let has_record = has_record(
            user_posts_registry,
            user_key
        );

        assert!(!has_record, EUserPostsExists);

        let user_post_keys = immutable_vector::empty();

        user_posts_registry.registry.add(user_key, user_post_keys);
    }

    // --------------- Test Functions ---------------

    #[test_only]
    public fun create_for_testing(
        user_posts_registry: &mut UserPostsRegistry,
        user_key: String
    ) {
        create(
            user_posts_registry,
            user_key
        );
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(USER_POSTS {}, ctx);
    }
}
