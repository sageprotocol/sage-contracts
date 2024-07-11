#[test_only]
module sage::test_common {
    use sui::test_scenario::{Self as ts, Scenario};

    use sage::actions::{
        Self,
        SageChannel,
        SageChannelMembership,
        SageChannelPosts,
        SagePostComments,
        SagePostLikes,
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
    public fun setup_for_testing(): (Scenario, SageChannel, SageChannelMembership, SageChannelPosts, SagePostComments, SagePostLikes, SageUserMembership, SageUserPostLikes, SageUserPosts, SageUsers) {
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
            sage_post_comments,
            sage_post_likes,
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
                mut sage_post_comments,
                mut sage_post_likes,
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
                &mut sage_post_comments,
                &mut sage_post_likes,
                &mut sage_user_membership,
                &mut sage_user_post_likes,
                &mut sage_user_posts,
                &mut sage_users,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, admin_cap);

            (sage_channel, sage_channel_membership, sage_channel_posts, sage_post_comments, sage_post_likes, sage_user_membership, sage_user_post_likes, sage_user_posts, sage_users)
        };

        (scenario_val, sage_channel, sage_channel_membership, sage_channel_posts, sage_post_comments, sage_post_likes, sage_user_membership, sage_user_post_likes, sage_user_posts, sage_users)
    }
}
