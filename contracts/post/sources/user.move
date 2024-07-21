module sage_post::user_posts {
    use std::string::{String};

    use sage_admin::{admin::{AdminCap}};

    use sage_immutable::{immutable_table::{Self, ImmutableTable}};

    use sage_post::{post::{Post}};

    use sage_user::{user::{User}};

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EUserPostsExists: u64 = 0;

    // --------------- Name Tag ---------------

    public struct UserPostsRegistry has store {
        registry: ImmutableTable<User, UserPosts>
    }

    public struct UserPosts has store {
        posts: ImmutableTable<String, Post>
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun borrow_post(
        user_posts: &mut UserPosts,
        post_key: String
    ): Post {
        *user_posts.posts.borrow(post_key)
    }

    public fun create_user_posts_registry(
        _: &AdminCap,
        ctx: &mut TxContext
    ): UserPostsRegistry {
        UserPostsRegistry {
            registry: immutable_table::new(ctx)
        }
    }

    public fun get_user_posts(
        user_posts_registry: &mut UserPostsRegistry,
        user: User
    ): &mut UserPosts {
        user_posts_registry.registry.borrow_mut(user)
    }

    public fun has_post(
        user_posts: &mut UserPosts,
        post_key: String
    ): bool {
        user_posts.posts.contains(post_key)
    }

    public fun has_record(
        user_posts_registry: &UserPostsRegistry,
        user: User
    ): bool {
        user_posts_registry.registry.contains(user)
    }

    // --------------- Friend Functions ---------------

    public(package) fun add(
        user_posts: &mut UserPosts,
        post_key: String,
        post: Post
    ) {
        user_posts.posts.add(post_key, post);
    }

    public(package) fun create(
        user_posts_registry: &mut UserPostsRegistry,
        user: User,
        ctx: &mut TxContext
    ) {
        let has_record = has_record(user_posts_registry, user);

        assert!(!has_record, EUserPostsExists);

        let user_posts = UserPosts {
            posts: immutable_table::new(ctx)
        };

        user_posts_registry.registry.add(user, user_posts);
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public fun destroy_for_testing(
        user_posts_registry: UserPostsRegistry
    ) {
        let UserPostsRegistry {
            registry
        } = user_posts_registry;

        registry.destroy_for_testing();
    }

}
