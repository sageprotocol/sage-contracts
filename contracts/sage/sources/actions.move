module sage::actions {
    use std::string::{String};

    use sui::dynamic_field as field;
    use sui::clock::Clock;
    use sui::package::{claim_and_keep};

    use sage_admin::{
        admin::{AdminCap}
    };

    use sage_channel::{
        channel::{Channel},
        channel_actions::{Self},
        channel_membership::{Self, ChannelMembershipRegistry},
        channel_registry::{Self, ChannelRegistry}
    };

    use sage_post::{
        channel_posts::{Self, ChannelPostsRegistry},
        post::{Post},
        post_actions::{Self},
        post_comments::{Self, PostCommentsRegistry},
        post_likes::{Self, PostLikesRegistry, UserPostLikesRegistry},
        user_posts::{Self, UserPostsRegistry}
    };

    use sage_user::{
        user::{User},
        user_actions::{Self},
        user_membership::{Self, UserMembershipRegistry},
        user_registry::{Self, UserRegistry}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    public struct SageChannel has key {
        id: UID
    }

    public struct SageChannelMembership has key {
        id: UID
    }

    public struct SageChannelPosts has key {
        id: UID
    }

    public struct SagePostComments has key {
        id: UID
    }

    public struct SagePostLikes has key {
        id: UID
    }

    public struct SageUserMembership has key {
        id: UID
    }

    public struct SageUserPostLikes has key {
        id: UID
    }

    public struct SageUserPosts has key {
        id: UID
    }

    public struct SageUsers has key {
        id: UID
    }

    public struct ACTIONS has drop {}

    public struct RegistryKey<phantom Registry> has copy, store, drop {}

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    fun init(
        otw: ACTIONS,
        ctx: &mut TxContext
    ) {
        claim_and_keep(otw, ctx);

        let sage_channel = SageChannel {
            id: object::new(ctx)
        };
        let sage_channel_membership = SageChannelMembership {
            id: object::new(ctx)
        };
        let sage_channel_posts = SageChannelPosts {
            id: object::new(ctx)
        };
        let sage_post_comments = SagePostComments {
            id: object::new(ctx)
        };
        let sage_post_likes = SagePostLikes {
            id: object::new(ctx)
        };
        let sage_user_membership = SageUserMembership {
            id: object::new(ctx)
        };
        let sage_user_post_likes = SageUserPostLikes {
            id: object::new(ctx)
        };
        let sage_user_posts = SageUserPosts {
            id: object::new(ctx)
        };
        let sage_users = SageUsers {
            id: object::new(ctx)
        };

        transfer::share_object(sage_channel);
        transfer::share_object(sage_channel_membership);
        transfer::share_object(sage_channel_posts);
        transfer::share_object(sage_post_comments);
        transfer::share_object(sage_post_likes);
        transfer::share_object(sage_user_membership);
        transfer::share_object(sage_user_post_likes);
        transfer::share_object(sage_user_posts);
        transfer::share_object(sage_users);
    }

    // --------------- Public Functions ---------------

    public fun create_registries(
        admin_cap: &AdminCap,
        sage_channel: &mut SageChannel,
        sage_channel_membership: &mut SageChannelMembership,
        sage_channel_posts: &mut SageChannelPosts,
        sage_post_comments: &mut SagePostComments,
        sage_post_likes: &mut SagePostLikes,
        sage_user_membership: &mut SageUserMembership,
        sage_user_post_likes: &mut SageUserPostLikes,
        sage_user_posts: &mut SageUserPosts,
        sage_users: &mut SageUsers,
        ctx: &mut TxContext
    ) {
        let channel_registry = channel_registry::create_channel_registry(
            admin_cap,
            ctx
        );

        let channel_membership_registry = channel_membership::create_channel_membership_registry(
            admin_cap,
            ctx
        );

        let channel_posts_registry = channel_posts::create_channel_posts_registry(
            admin_cap,
            ctx
        );

        let post_comments_registry = post_comments::create_post_comments_registry(
            admin_cap,
            ctx
        );

        let post_likes_registry = post_likes::create_post_likes_registry(
            admin_cap,
            ctx
        );

        let user_membership_registry = user_membership::create_user_membership_registry(
            admin_cap,
            ctx
        );

        let user_post_likes_registry = post_likes::create_user_post_likes_registry(
            admin_cap,
            ctx
        );

        let user_posts_registry = user_posts::create_user_posts_registry(
            admin_cap,
            ctx
        );

        let user_registry = user_registry::create_user_registry(
            admin_cap,
            ctx
        );

        field::add(&mut sage_channel.id, RegistryKey<ChannelRegistry> {}, channel_registry);
        field::add(&mut sage_channel_membership.id, RegistryKey<ChannelMembershipRegistry> {}, channel_membership_registry);
        field::add(&mut sage_channel_posts.id, RegistryKey<ChannelPostsRegistry> {}, channel_posts_registry);
        field::add(&mut sage_post_comments.id, RegistryKey<PostCommentsRegistry> {}, post_comments_registry);
        field::add(&mut sage_post_likes.id, RegistryKey<PostLikesRegistry> {}, post_likes_registry);
        field::add(&mut sage_user_membership.id, RegistryKey<UserMembershipRegistry> {}, user_membership_registry);
        field::add(&mut sage_user_post_likes.id, RegistryKey<UserPostLikesRegistry> {}, user_post_likes_registry);
        field::add(&mut sage_user_posts.id, RegistryKey<UserPostsRegistry> {}, user_posts_registry);
        field::add(&mut sage_users.id, RegistryKey<UserRegistry> {}, user_registry);
    }

    public fun create_channel(
        clock: &Clock,
        sage_channel: &mut SageChannel,
        sage_channel_membership: &mut SageChannelMembership,
        channel_name: String,
        avatar_hash: String,
        banner_hash: String,
        description: String,
        ctx: &mut TxContext
    ): Channel {
        let channel_registry = field::borrow_mut(&mut sage_channel.id, RegistryKey<ChannelRegistry> {});
        let channel_membership_registry = field::borrow_mut(&mut sage_channel_membership.id, RegistryKey<ChannelMembershipRegistry> {});

        channel_actions::create(
            clock,
            channel_registry,
            channel_membership_registry,
            channel_name,
            avatar_hash,
            banner_hash,
            description,
            ctx
        )
    }

    public fun create_user(
        clock: &Clock,
        sage_users: &mut SageUsers,
        avatar_hash: String,
        banner_hash: String,
        description: String,
        name: String,
        ctx: &mut TxContext
    ): User {
        let user_registry = field::borrow_mut(&mut sage_users.id, RegistryKey<UserRegistry> {});

        user_actions::create(
            clock,
            user_registry,
            avatar_hash,
            banner_hash,
            description,
            name,
            ctx
        )
    }

    public fun like_post(
        sage_post_likes: &mut SagePostLikes,
        sage_user_post_likes: &mut SageUserPostLikes,
        post: Post,
        ctx: &mut TxContext
    ) {
        let post_likes_registry = field::borrow_mut(&mut sage_post_likes.id, RegistryKey<PostLikesRegistry> {});
        let user_post_likes_registry = field::borrow_mut(&mut sage_user_post_likes.id, RegistryKey<UserPostLikesRegistry> {});

        post_actions::like(
            post_likes_registry,
            user_post_likes_registry,
            post,
            ctx
        );
    }

    public fun join_channel(
        sage_channel: &mut SageChannel,
        sage_channel_membership: &mut SageChannelMembership,
        channel_name: String,
        ctx: &mut TxContext
    ) {
        let channel_registry = field::borrow_mut(&mut sage_channel.id, RegistryKey<ChannelRegistry> {});
        let channel_membership_registry = field::borrow_mut(&mut sage_channel_membership.id, RegistryKey<ChannelMembershipRegistry> {});

        channel_actions::join(
            channel_registry,
            channel_membership_registry,
            channel_name,
            ctx
        );
    }

    public fun leave_channel(
        sage_channel: &mut SageChannel,
        sage_channel_membership: &mut SageChannelMembership,
        channel_name: String,
        ctx: &mut TxContext
    ) {
        let channel_registry = field::borrow_mut(&mut sage_channel.id, RegistryKey<ChannelRegistry> {});
        let channel_membership_registry = field::borrow_mut(&mut sage_channel_membership.id, RegistryKey<ChannelMembershipRegistry> {});

        channel_actions::leave(
            channel_registry,
            channel_membership_registry,
            channel_name,
            ctx
        );
    }

    public fun join_user(
        sage_user: &mut SageUsers,
        sage_user_membership: &mut SageUserMembership,
        followed_user: address,
        ctx: &mut TxContext
    ) {
        let user_registry = field::borrow_mut(&mut sage_user.id, RegistryKey<UserRegistry> {});
        let user_membership_registry = field::borrow_mut(&mut sage_user_membership.id, RegistryKey<UserMembershipRegistry> {});

        user_actions::join(
            user_registry,
            user_membership_registry,
            followed_user,
            ctx
        );
    }

    public fun leave_user(
        sage_user: &mut SageUsers,
        sage_user_membership: &mut SageUserMembership,
        followed_user: address,
        ctx: &mut TxContext
    ) {
        let user_registry = field::borrow_mut(&mut sage_user.id, RegistryKey<UserRegistry> {});
        let user_membership_registry = field::borrow_mut(&mut sage_user_membership.id, RegistryKey<UserMembershipRegistry> {});

        user_actions::leave(
            user_registry,
            user_membership_registry,
            followed_user,
            ctx
        );
    }

    public fun post_from_channel(
        clock: &Clock,
        sage_channel: &mut SageChannel,
        sage_channel_membership: &mut SageChannelMembership,
        sage_channel_posts: &mut SageChannelPosts,
        sage_post_comments: &mut SagePostComments,
        sage_post_likes: &mut SagePostLikes,
        channel_name: String,
        data: String,
        description: String,
        title: String,
        ctx: &mut TxContext
    ): ID {
        let channel_registry = field::borrow_mut(&mut sage_channel.id, RegistryKey<ChannelRegistry> {});
        let channel_membership_registry = field::borrow_mut(&mut sage_channel_membership.id, RegistryKey<ChannelMembershipRegistry> {});
        let channel_posts_registry = field::borrow_mut(&mut sage_channel_posts.id, RegistryKey<ChannelPostsRegistry> {});
        let post_comments_registry = field::borrow_mut(&mut sage_post_comments.id, RegistryKey<PostCommentsRegistry> {});
        let post_likes_registry = field::borrow_mut(&mut sage_post_likes.id, RegistryKey<PostLikesRegistry> {});

        post_actions::post_from_channel(
            clock,
            channel_registry,
            channel_membership_registry,
            channel_posts_registry,
            post_comments_registry,
            post_likes_registry,
            channel_name,
            data,
            description,
            title,
            ctx
        )
    }

    public fun post_from_post(
        clock: &Clock,
        sage_post_comments: &mut SagePostComments,
        sage_post_likes: &mut SagePostLikes,
        parent_post: Post,
        data: String,
        description: String,
        title: String,
        ctx: &mut TxContext
    ): ID {
        let post_comments_registry = field::borrow_mut(&mut sage_post_comments.id, RegistryKey<PostCommentsRegistry> {});
        let post_likes_registry = field::borrow_mut(&mut sage_post_likes.id, RegistryKey<PostLikesRegistry> {});

        post_actions::post_from_post(
            clock,
            post_comments_registry,
            post_likes_registry,
            parent_post,
            data,
            description,
            title,
            ctx
        )
    }

    public fun post_from_user(
        clock: &Clock,
        sage_post_comments: &mut SagePostComments,
        sage_post_likes: &mut SagePostLikes,
        sage_user_posts: &mut SageUserPosts,
        sage_users: &mut SageUsers,
        data: String,
        description: String,
        title: String,
        ctx: &mut TxContext
    ): ID {
        let post_comments_registry = field::borrow_mut(&mut sage_post_comments.id, RegistryKey<PostCommentsRegistry> {});
        let post_likes_registry = field::borrow_mut(&mut sage_post_likes.id, RegistryKey<PostLikesRegistry> {});
        let user_posts_registry = field::borrow_mut(&mut sage_user_posts.id, RegistryKey<UserPostsRegistry> {});
        let user_registry = field::borrow_mut(&mut sage_users.id, RegistryKey<UserRegistry> {});
        
        post_actions::post_from_user(
            clock,
            post_comments_registry,
            post_likes_registry,
            user_posts_registry,
            user_registry,
            data,
            description,
            title,
            ctx
        )
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public fun init_for_testing(
        ctx: &mut TxContext
    ): (SageChannel, SageChannelMembership, SageChannelPosts, SagePostComments, SagePostLikes, SageUserMembership, SageUserPostLikes, SageUserPosts, SageUsers) {
        (
            SageChannel { id: object::new(ctx) },
            SageChannelMembership { id: object::new(ctx) },
            SageChannelPosts { id: object::new(ctx) },
            SagePostComments { id: object::new(ctx) },
            SagePostLikes { id: object::new(ctx) },
            SageUserMembership { id: object::new(ctx) },
            SageUserPostLikes { id: object::new(ctx) },
            SageUserPosts { id: object::new(ctx) },
            SageUsers { id: object::new(ctx) }
        )
    }

    #[test_only]
    public fun borrow_channel_registry_for_testing(
        sage_channel: &mut SageChannel
    ): &mut ChannelRegistry {
        let channel_registry = field::borrow_mut<RegistryKey<ChannelRegistry>, ChannelRegistry>(
            &mut sage_channel.id,
            RegistryKey<ChannelRegistry> {}
        );

        channel_registry
    }

    #[test_only]
    public fun borrow_channel_membership_registry_for_testing(
        sage_channel_membership: &mut SageChannelMembership
    ): &mut ChannelMembershipRegistry {
        let channel_membership_registry = field::borrow_mut<RegistryKey<ChannelMembershipRegistry>, ChannelMembershipRegistry>(
            &mut sage_channel_membership.id,
            RegistryKey<ChannelMembershipRegistry> {}
        );

        channel_membership_registry
    }

    #[test_only]
    public fun borrow_channel_posts_registry_for_testing(
        sage_channel_posts: &mut SageChannelPosts
    ): &mut ChannelPostsRegistry {
        let channel_posts_registry = field::borrow_mut<RegistryKey<ChannelPostsRegistry>, ChannelPostsRegistry>(
            &mut sage_channel_posts.id,
            RegistryKey<ChannelPostsRegistry> {}
        );

        channel_posts_registry
    }

    #[test_only]
    public fun borrow_posts_comments_registry_for_testing(
        sage_post_comments: &mut SagePostComments
    ): &mut PostCommentsRegistry {
        let post_comments_registry = field::borrow_mut<RegistryKey<PostCommentsRegistry>, PostCommentsRegistry>(
            &mut sage_post_comments.id,
            RegistryKey<PostCommentsRegistry> {}
        );

        post_comments_registry
    }

    #[test_only]
    public fun borrow_posts_likes_registry_for_testing(
        sage_post_likes: &mut SagePostLikes
    ): &mut PostLikesRegistry {
        let post_likes_registry = field::borrow_mut<RegistryKey<PostLikesRegistry>, PostLikesRegistry>(
            &mut sage_post_likes.id,
            RegistryKey<PostLikesRegistry> {}
        );

        post_likes_registry
    }

    #[test_only]
    public fun borrow_user_membership_registry_for_testing(
        sage_user_membership: &mut SageUserPostLikes
    ): &mut UserMembershipRegistry {
        let user_membership_registry = field::borrow_mut<RegistryKey<UserMembershipRegistry>, UserMembershipRegistry>(
            &mut sage_user_membership.id,
            RegistryKey<UserMembershipRegistry> {}
        );

        user_membership_registry
    }

    #[test_only]
    public fun borrow_user_posts_likes_registry_for_testing(
        sage_user_post_likes: &mut SageUserPostLikes
    ): &mut UserPostLikesRegistry {
        let user_post_likes_registry = field::borrow_mut<RegistryKey<UserPostLikesRegistry>, UserPostLikesRegistry>(
            &mut sage_user_post_likes.id,
            RegistryKey<UserPostLikesRegistry> {}
        );

        user_post_likes_registry
    }

    #[test_only]
    public fun borrow_user_posts_registry_for_testing(
        sage_user_posts: &mut SageUserPosts
    ): &mut UserPostsRegistry {
        let user_posts_registry = field::borrow_mut<RegistryKey<UserPostsRegistry>, UserPostsRegistry>(
            &mut sage_user_posts.id,
            RegistryKey<UserPostsRegistry> {}
        );

        user_posts_registry
    }

    #[test_only]
    public fun borrow_users_registry_for_testing(
        sage_users: &mut SageUsers
    ): &mut UserRegistry {
        let user_registry = field::borrow_mut<RegistryKey<UserRegistry>, UserRegistry>(
            &mut sage_users.id,
            RegistryKey<UserRegistry> {}
        );

        user_registry
    }

    #[test_only]
    public fun destroy_channel_for_testing(
        sage_channel: SageChannel
    ) {
        let SageChannel {
            id
        } = sage_channel;

        object::delete(id);
    }

    #[test_only]
    public fun destroy_channel_membership_for_testing(
        sage_channel_membership: SageChannelMembership
    ) {
        let SageChannelMembership {
            id
        } = sage_channel_membership;

        object::delete(id);
    }

    #[test_only]
    public fun destroy_channel_posts_for_testing(
        sage_channel_posts: SageChannelPosts
    ) {
        let SageChannelPosts {
            id
        } = sage_channel_posts;

        object::delete(id);
    }

    #[test_only]
    public fun destroy_post_comments_for_testing(
        sage_post_comments: SagePostComments
    ) {
        let SagePostComments {
            id
        } = sage_post_comments;

        object::delete(id);
    }

    #[test_only]
    public fun destroy_post_likes_for_testing(
        sage_post_likes: SagePostLikes
    ) {
        let SagePostLikes {
            id
        } = sage_post_likes;

        object::delete(id);
    }

    #[test_only]
    public fun destroy_user_membership_for_testing(
        sage_user_membership: SageUserMembership
    ) {
        let SageUserMembership {
            id
        } = sage_user_membership;

        object::delete(id);
    }

    #[test_only]
    public fun destroy_user_post_likes_for_testing(
        sage_user_post_likes: SageUserPostLikes
    ) {
        let SageUserPostLikes {
            id
        } = sage_user_post_likes;

        object::delete(id);
    }

    #[test_only]
    public fun destroy_user_posts_for_testing(
        sage_user_posts: SageUserPosts
    ) {
        let SageUserPosts {
            id
        } = sage_user_posts;

        object::delete(id);
    }

    #[test_only]
    public fun destroy_users_for_testing(
        sage_users: SageUsers
    ) {
        let SageUsers {
            id
        } = sage_users;

        object::delete(id);
    }
}
