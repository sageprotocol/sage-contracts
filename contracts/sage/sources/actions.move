module sage::actions {
    use std::string::{String};

    use sui::dynamic_field as field;
    use sui::clock::Clock;
    use sui::package::{claim_and_keep};

    use sage_admin::{
        admin::{AdminCap, NotificationCap}
    };

    use sage_channel::{
        channel::{Channel},
        channel_actions::{Self},
        channel_membership::{Self, ChannelMembershipRegistry},
        channel_registry::{Self, ChannelRegistry}
    };

    use sage_notification::{
        notification::{Notification},
        notification_actions::{Self},
        notification_registry::{Self, NotificationRegistry}
    };

    use sage_post::{
        channel_posts::{Self, ChannelPostsRegistry},
        post_actions::{Self},
        post_comments::{Self, PostCommentsRegistry},
        post_likes::{Self, PostLikesRegistry, UserPostLikesRegistry},
        post_registry::{Self, PostRegistry},
        user_posts::{Self, UserPostsRegistry}
    };

    use sage_user::{
        user::{User},
        user_actions::{Self},
        user_invite::{Self, InviteConfig, UserInviteRegistry},
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

    public struct SageInviteConfig has key {
        id: UID
    }

    public struct SageNotification has key {
        id: UID
    }

    public struct SagePostComments has key {
        id: UID
    }

    public struct SagePost has key {
        id: UID
    }

    public struct SagePostLikes has key {
        id: UID
    }

    public struct SageUserInvite has key {
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
        let sage_invite_config = SageInviteConfig {
            id: object::new(ctx)
        };
        let sage_notification = SageNotification {
            id: object::new(ctx)
        };
        let sage_post = SagePost {
            id: object::new(ctx)
        };
        let sage_post_comments = SagePostComments {
            id: object::new(ctx)
        };
        let sage_post_likes = SagePostLikes {
            id: object::new(ctx)
        };
        let sage_user_invite = SageUserInvite {
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
        transfer::share_object(sage_invite_config);
        transfer::share_object(sage_notification);
        transfer::share_object(sage_post);
        transfer::share_object(sage_post_comments);
        transfer::share_object(sage_post_likes);
        transfer::share_object(sage_user_invite);
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
        sage_invite_config: &mut SageInviteConfig,
        sage_notification: &mut SageNotification,
        sage_post: &mut SagePost,
        sage_post_comments: &mut SagePostComments,
        sage_post_likes: &mut SagePostLikes,
        sage_user_invite: &mut SageUserInvite,
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

        let invite_config = user_invite::create_invite_config(admin_cap);

        let notification_registry = notification_registry::create_notification_registry(
            admin_cap,
            ctx
        );

        let post_registry = post_registry::create_post_registry(
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

        let user_invite_registry = user_invite::create_invite_registry(
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
        field::add(&mut sage_invite_config.id, RegistryKey<InviteConfig> {}, invite_config);
        field::add(&mut sage_notification.id, RegistryKey<NotificationRegistry> {}, notification_registry);
        field::add(&mut sage_post.id, RegistryKey<PostRegistry> {}, post_registry);
        field::add(&mut sage_post_comments.id, RegistryKey<PostCommentsRegistry> {}, post_comments_registry);
        field::add(&mut sage_post_likes.id, RegistryKey<PostLikesRegistry> {}, post_likes_registry);
        field::add(&mut sage_user_invite.id, RegistryKey<UserInviteRegistry> {}, user_invite_registry);
        field::add(&mut sage_user_membership.id, RegistryKey<UserMembershipRegistry> {}, user_membership_registry);
        field::add(&mut sage_user_post_likes.id, RegistryKey<UserPostLikesRegistry> {}, user_post_likes_registry);
        field::add(&mut sage_user_posts.id, RegistryKey<UserPostsRegistry> {}, user_posts_registry);
        field::add(&mut sage_users.id, RegistryKey<UserRegistry> {}, user_registry);
    }

    public fun create_channel(
        clock: &Clock,
        sage_channel: &mut SageChannel,
        sage_channel_membership: &mut SageChannelMembership,
        sage_users: &mut SageUsers,
        channel_name: String,
        avatar_hash: String,
        banner_hash: String,
        description: String,
        ctx: &mut TxContext
    ): Channel {
        let channel_registry = field::borrow_mut(&mut sage_channel.id, RegistryKey<ChannelRegistry> {});
        let channel_membership_registry = field::borrow_mut(&mut sage_channel_membership.id, RegistryKey<ChannelMembershipRegistry> {});
        let user_registry = field::borrow_mut(&mut sage_users.id, RegistryKey<UserRegistry> {});

        channel_actions::create(
            clock,
            channel_registry,
            channel_membership_registry,
            user_registry,
            channel_name,
            avatar_hash,
            banner_hash,
            description,
            ctx
        )
    }

    public fun create_notification(
        notification_cap: &NotificationCap,
        clock: &Clock,
        sage_notification: &mut SageNotification,
        user: address,
        message: String,
        reward_amount: u64
    ): Notification {
        let notification_registry = field::borrow_mut(&mut sage_notification.id, RegistryKey<NotificationRegistry> {});

        notification_actions::create(
            notification_cap,
            clock,
            notification_registry,
            user,
            message,
            reward_amount
        )
    }

    public fun create_user(
        clock: &Clock,
        sage_users: &mut SageUsers,
        sage_user_invite: &mut SageUserInvite,
        sage_user_membership: &mut SageUserMembership,
        sage_invite_config: &mut SageInviteConfig,
        invite_code: String,
        invite_key: String,
        avatar_hash: String,
        banner_hash: String,
        description: String,
        name: String,
        ctx: &mut TxContext
    ): User {
        let invite_config = field::borrow_mut(&mut sage_invite_config.id, RegistryKey<InviteConfig> {});
        let user_registry = field::borrow_mut(&mut sage_users.id, RegistryKey<UserRegistry> {});
        let user_invite_registry = field::borrow_mut(&mut sage_user_invite.id, RegistryKey<UserInviteRegistry> {});
        let user_membership_registry = field::borrow_mut(&mut sage_user_membership.id, RegistryKey<UserMembershipRegistry> {});

        user_actions::create(
            clock,
            user_registry,
            user_invite_registry,
            user_membership_registry,
            invite_config,
            invite_code,
            invite_key,
            avatar_hash,
            banner_hash,
            description,
            name,
            ctx
        )
    }

    public fun like_post(
        sage_post: &mut SagePost,
        sage_post_likes: &mut SagePostLikes,
        sage_users: &mut SageUsers,
        sage_user_post_likes: &mut SageUserPostLikes,
        post_key: String,
        ctx: &mut TxContext
    ) {
        let post_registry = field::borrow_mut(&mut sage_post.id, RegistryKey<PostRegistry> {});
        let post_likes_registry = field::borrow_mut(&mut sage_post_likes.id, RegistryKey<PostLikesRegistry> {});
        let user_registry = field::borrow_mut(&mut sage_users.id, RegistryKey<UserRegistry> {});
        let user_post_likes_registry = field::borrow_mut(&mut sage_user_post_likes.id, RegistryKey<UserPostLikesRegistry> {});

        post_actions::like(
            post_registry,
            post_likes_registry,
            user_registry,
            user_post_likes_registry,
            post_key,
            ctx
        );
    }

    public fun join_channel(
        sage_channel: &mut SageChannel,
        sage_channel_membership: &mut SageChannelMembership,
        sage_users: &mut SageUsers,
        channel_name: String,
        ctx: &mut TxContext
    ) {
        let channel_registry = field::borrow_mut(&mut sage_channel.id, RegistryKey<ChannelRegistry> {});
        let channel_membership_registry = field::borrow_mut(&mut sage_channel_membership.id, RegistryKey<ChannelMembershipRegistry> {});
        let user_registry = field::borrow_mut(&mut sage_users.id, RegistryKey<UserRegistry> {});

        channel_actions::join(
            channel_registry,
            channel_membership_registry,
            user_registry,
            channel_name,
            ctx
        );
    }

    public fun leave_channel(
        sage_channel: &mut SageChannel,
        sage_channel_membership: &mut SageChannelMembership,
        sage_users: &mut SageUsers,
        channel_name: String,
        ctx: &mut TxContext
    ) {
        let channel_registry = field::borrow_mut(&mut sage_channel.id, RegistryKey<ChannelRegistry> {});
        let channel_membership_registry = field::borrow_mut(&mut sage_channel_membership.id, RegistryKey<ChannelMembershipRegistry> {});
        let user_registry = field::borrow_mut(&mut sage_users.id, RegistryKey<UserRegistry> {});

        channel_actions::leave(
            channel_registry,
            channel_membership_registry,
            user_registry,
            channel_name,
            ctx
        );
    }

    public fun join_user(
        sage_users: &mut SageUsers,
        sage_user_membership: &mut SageUserMembership,
        username: String,
        ctx: &mut TxContext
    ) {
        let user_registry = field::borrow_mut(&mut sage_users.id, RegistryKey<UserRegistry> {});
        let user_membership_registry = field::borrow_mut(&mut sage_user_membership.id, RegistryKey<UserMembershipRegistry> {});

        user_actions::join(
            user_registry,
            user_membership_registry,
            username,
            ctx
        );
    }

    public fun leave_user(
        sage_users: &mut SageUsers,
        sage_user_membership: &mut SageUserMembership,
        username: String,
        ctx: &mut TxContext
    ) {
        let user_registry = field::borrow_mut(&mut sage_users.id, RegistryKey<UserRegistry> {});
        let user_membership_registry = field::borrow_mut(&mut sage_user_membership.id, RegistryKey<UserMembershipRegistry> {});

        user_actions::leave(
            user_registry,
            user_membership_registry,
            username,
            ctx
        );
    }

    public fun post_from_channel(
        clock: &Clock,
        sage_channel: &mut SageChannel,
        sage_channel_membership: &mut SageChannelMembership,
        sage_channel_posts: &mut SageChannelPosts,
        sage_post: &mut SagePost,
        sage_users: &mut SageUsers,
        channel_name: String,
        data: String,
        description: String,
        title: String,
        ctx: &mut TxContext
    ): String {
        let channel_registry = field::borrow_mut(&mut sage_channel.id, RegistryKey<ChannelRegistry> {});
        let channel_membership_registry = field::borrow_mut(&mut sage_channel_membership.id, RegistryKey<ChannelMembershipRegistry> {});
        let channel_posts_registry = field::borrow_mut(&mut sage_channel_posts.id, RegistryKey<ChannelPostsRegistry> {});
        let post_registry = field::borrow_mut(&mut sage_post.id, RegistryKey<PostRegistry> {});
        let user_registry = field::borrow_mut(&mut sage_users.id, RegistryKey<UserRegistry> {});

        post_actions::post_from_channel(
            clock,
            channel_registry,
            channel_membership_registry,
            channel_posts_registry,
            post_registry,
            user_registry,
            channel_name,
            data,
            description,
            title,
            ctx
        )
    }

    public fun post_from_post(
        clock: &Clock,
        sage_post: &mut SagePost,
        sage_post_comments: &mut SagePostComments,
        sage_users: &mut SageUsers,
        parent_key: String,
        data: String,
        description: String,
        title: String,
        ctx: &mut TxContext
    ): String {
        let post_registry = field::borrow_mut(&mut sage_post.id, RegistryKey<PostRegistry> {});
        let post_comments_registry = field::borrow_mut(&mut sage_post_comments.id, RegistryKey<PostCommentsRegistry> {});
        let user_registry = field::borrow_mut(&mut sage_users.id, RegistryKey<UserRegistry> {});

        post_actions::post_from_post(
            clock,
            post_registry,
            post_comments_registry,
            user_registry,
            parent_key,
            data,
            description,
            title,
            ctx
        )
    }

    public fun post_from_user(
        clock: &Clock,
        sage_post: &mut SagePost,
        sage_user_posts: &mut SageUserPosts,
        sage_users: &mut SageUsers,
        data: String,
        description: String,
        title: String,
        user_address: address,
        ctx: &mut TxContext
    ): String {
        let post_registry = field::borrow_mut(&mut sage_post.id, RegistryKey<PostRegistry> {});
        let user_posts_registry = field::borrow_mut(&mut sage_user_posts.id, RegistryKey<UserPostsRegistry> {});
        let user_registry = field::borrow_mut(&mut sage_users.id, RegistryKey<UserRegistry> {});
        
        post_actions::post_from_user(
            clock,
            post_registry,
            user_posts_registry,
            user_registry,
            data,
            description,
            title,
            user_address,
            ctx
        )
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public fun init_for_testing(
        ctx: &mut TxContext
    ): (
        SageChannel,
        SageChannelMembership,
        SageChannelPosts,
        SageInviteConfig,
        SageNotification,
        SagePost,
        SagePostComments,
        SagePostLikes,
        SageUserInvite,
        SageUserMembership,
        SageUserPostLikes,
        SageUserPosts,
        SageUsers
    ) {
        (
            SageChannel { id: object::new(ctx) },
            SageChannelMembership { id: object::new(ctx) },
            SageChannelPosts { id: object::new(ctx) },
            SageInviteConfig { id: object::new(ctx) },
            SageNotification { id: object::new(ctx) },
            SagePost { id: object::new(ctx) },
            SagePostComments { id: object::new(ctx) },
            SagePostLikes { id: object::new(ctx) },
            SageUserInvite { id: object::new(ctx) },
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
    public fun borrow_invite_config_for_testing(
        sage_invite_config: &mut SageInviteConfig
    ): &mut InviteConfig {
        let invite_config = field::borrow_mut<RegistryKey<InviteConfig>, InviteConfig>(
            &mut sage_invite_config.id,
            RegistryKey<InviteConfig> {}
        );

        invite_config
    }

    #[test_only]
    public fun borrow_notification_registry_for_testing(
        sage_notification: &mut SageNotification
    ): &mut NotificationRegistry {
        let notification_registry = field::borrow_mut<RegistryKey<NotificationRegistry>, NotificationRegistry>(
            &mut sage_notification.id,
            RegistryKey<NotificationRegistry> {}
        );

        notification_registry
    }

    #[test_only]
    public fun borrow_post_registry_for_testing(
        sage_post: &mut SagePost
    ): &mut PostRegistry {
        let post_registry = field::borrow_mut<RegistryKey<PostRegistry>, PostRegistry>(
            &mut sage_post.id,
            RegistryKey<PostRegistry> {}
        );

        post_registry
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
    public fun borrow_user_invite_registry_for_testing(
        sage_user_invite: &mut SageUserInvite
    ): &mut UserInviteRegistry {
        let notification_registry = field::borrow_mut<RegistryKey<UserInviteRegistry>, UserInviteRegistry>(
            &mut sage_user_invite.id,
            RegistryKey<UserInviteRegistry> {}
        );

        notification_registry
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
    public fun destroy_notification_for_testing(
        sage_notification: SageNotification
    ) {
        let SageNotification {
            id
        } = sage_notification;

        object::delete(id);
    }

    #[test_only]
    public fun destroy_invite_config_for_testing(
        sage_invite_config: SageInviteConfig
    ) {
        let SageInviteConfig {
            id
        } = sage_invite_config;

        object::delete(id);
    }

    #[test_only]
    public fun destroy_post_for_testing(
        sage_post: SagePost
    ) {
        let SagePost {
            id
        } = sage_post;

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
    public fun destroy_user_invite_for_testing(
        sage_user_invite: SageUserInvite
    ) {
        let SageUserInvite {
            id
        } = sage_user_invite;

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
