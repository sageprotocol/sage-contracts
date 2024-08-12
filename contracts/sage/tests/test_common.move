#[test_only]
module sage::test_common {
    use sui::test_scenario::{Self as ts, Scenario};

    use sage::actions::{
        Self,
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
    };

    use sage_admin::{admin::{Self, AdminCap}};

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public fun destroy_for_testing(
        sage_channel: SageChannel,
        sage_channel_membership: SageChannelMembership,
        sage_channel_posts: SageChannelPosts,
        sage_invite_config: SageInviteConfig,
        sage_notification: SageNotification,
        sage_post: SagePost,
        sage_post_comments: SagePostComments,
        sage_post_likes: SagePostLikes,
        sage_user_invite: SageUserInvite,
        sage_user_membership: SageUserMembership,
        sage_user_post_likes: SageUserPostLikes,
        sage_user_posts: SageUserPosts,
        sage_users: SageUsers
    ) {
        actions::destroy_channel_for_testing(sage_channel);
        actions::destroy_channel_membership_for_testing(sage_channel_membership);
        actions::destroy_channel_posts_for_testing(sage_channel_posts);
        actions::destroy_invite_config_for_testing(sage_invite_config);
        actions::destroy_notification_for_testing(sage_notification);
        actions::destroy_post_for_testing(sage_post);
        actions::destroy_post_comments_for_testing(sage_post_comments);
        actions::destroy_post_likes_for_testing(sage_post_likes);
        actions::destroy_user_invite_for_testing(sage_user_invite);
        actions::destroy_user_membership_for_testing(sage_user_membership);
        actions::destroy_user_post_likes_for_testing(sage_user_post_likes);
        actions::destroy_user_posts_for_testing(sage_user_posts);
        actions::destroy_users_for_testing(sage_users);
    }

    #[test_only]
    public fun setup_for_testing(): (
        Scenario,
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
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let (
            sage_channel,
            sage_channel_membership,
            sage_channel_posts,
            sage_invite_config,
            sage_notification,
            sage_post,
            sage_post_comments,
            sage_post_likes,
            sage_user_invite,
            sage_user_membership,
            sage_user_post_likes,
            sage_user_posts,
            sage_users
        ) = {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            let (
                mut sage_channel,
                mut sage_channel_membership,
                mut sage_channel_posts,
                mut sage_invite_config,
                mut sage_notification,
                mut sage_post,
                mut sage_post_comments,
                mut sage_post_likes,
                mut sage_user_invite,
                mut sage_user_membership,
                mut sage_user_post_likes,
                mut sage_user_posts,
                mut sage_users
            ) = actions::init_for_testing(
                ts::ctx(scenario)
            );

            actions::create_registries(
                &admin_cap,
                &mut sage_channel,
                &mut sage_channel_membership,
                &mut sage_channel_posts,
                &mut sage_invite_config,
                &mut sage_notification,
                &mut sage_post,
                &mut sage_post_comments,
                &mut sage_post_likes,
                &mut sage_user_invite,
                &mut sage_user_membership,
                &mut sage_user_post_likes,
                &mut sage_user_posts,
                &mut sage_users,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, admin_cap);

            (
                sage_channel,
                sage_channel_membership,
                sage_channel_posts,
                sage_invite_config,
                sage_notification,
                sage_post,
                sage_post_comments,
                sage_post_likes,
                sage_user_invite,
                sage_user_membership,
                sage_user_post_likes,
                sage_user_posts,
                sage_users
            )
        };

        (
            scenario_val,
            sage_channel,
            sage_channel_membership,
            sage_channel_posts,
            sage_invite_config,
            sage_notification,
            sage_post,
            sage_post_comments,
            sage_post_likes,
            sage_user_invite,
            sage_user_membership,
            sage_user_post_likes,
            sage_user_posts,
            sage_users
        )
    }
}
