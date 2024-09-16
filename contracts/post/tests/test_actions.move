#[test_only]
module sage_post::test_post_actions {
    use std::string::{utf8};

    use sui::{
        clock::{Self, Clock},
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy}
    };

    use sage_admin::{admin::{Self, InviteCap}};

    use sage_channel::{
        channel_actions::{Self},
        channel_membership::{Self, ChannelMembershipRegistry},
        channel_registry::{Self, ChannelRegistry}
    };

    use sage_post::{
        channel_posts::{Self, ChannelPostsRegistry},
        post_actions::{Self, EUserNotChannelMember},
        post_comments::{Self, PostCommentsRegistry},
        post_likes::{Self, PostLikesRegistry, UserPostLikesRegistry},
        post_registry::{Self, PostRegistry},
        user_posts::{Self, UserPostsRegistry}
    };

    use sage_user::{
        user_actions::{Self},
        user_invite::{Self, InviteConfig, UserInviteRegistry},
        user_membership::{Self, UserMembershipRegistry},
        user_registry::{Self, UserRegistry}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;
    const OTHER: address = @0xBABE;
    const SERVER: address = @server;

    // --------------- Errors ---------------

    const EChannelPostFailure: u64 = 0;
    const EPostCommentFailure: u64 = 1;
    const EPostNotCreated: u64 = 2;
    const EPostNotLiked: u64 = 3;
    const EUserPostFailure: u64 = 4;

    // --------------- Test Functions ---------------

    #[test_only]
    fun destroy_for_testing(
        channel_membership_registry: ChannelMembershipRegistry,
        channel_posts_registry: ChannelPostsRegistry,
        channel_registry: ChannelRegistry,
        post_comments_registry: PostCommentsRegistry,
        post_likes_registry: PostLikesRegistry,
        post_registry: PostRegistry,
        user_invite_registry: UserInviteRegistry,
        user_membership_registry: UserMembershipRegistry,
        user_post_likes_registry: UserPostLikesRegistry,
        user_posts_registry: UserPostsRegistry,
        user_registry: UserRegistry,
        invite_config: InviteConfig
    ) {
        destroy(channel_membership_registry);
        destroy(channel_posts_registry);
        destroy(channel_registry);
        destroy(invite_config);
        destroy(post_comments_registry);
        destroy(post_likes_registry);
        destroy(user_post_likes_registry);
        destroy(post_registry);
        destroy(user_invite_registry);
        destroy(user_membership_registry);
        destroy(user_posts_registry);
        destroy(user_registry);
    }

    #[test_only]
    fun setup_for_testing(): (
        Scenario,
        ChannelMembershipRegistry,
        ChannelPostsRegistry,
        ChannelRegistry,
        PostCommentsRegistry,
        PostLikesRegistry,
        PostRegistry,
        UserInviteRegistry,
        UserMembershipRegistry,
        UserPostLikesRegistry,
        UserPostsRegistry,
        UserRegistry,
        InviteConfig
    ) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
            channel_membership::init_for_testing(ts::ctx(scenario));
            channel_posts::init_for_testing(ts::ctx(scenario));
            channel_registry::init_for_testing(ts::ctx(scenario));
            post_comments::init_for_testing(ts::ctx(scenario));
            post_likes::init_for_testing(ts::ctx(scenario));
            post_registry::init_for_testing(ts::ctx(scenario));
            user_invite::init_for_testing(ts::ctx(scenario));
            user_membership::init_for_testing(ts::ctx(scenario));
            user_posts::init_for_testing(ts::ctx(scenario));
            user_registry::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let (
            channel_membership_registry,
            channel_posts_registry,
            channel_registry,
            post_comments_registry,
            post_likes_registry,
            post_registry,
            user_invite_registry,
            user_membership_registry,
            user_post_likes_registry,
            user_posts_registry,
            user_registry,
            invite_config
        ) = {
            let channel_membership_registry = scenario.take_shared<ChannelMembershipRegistry>();
            let channel_posts_registry = scenario.take_shared<ChannelPostsRegistry>();
            let channel_registry = scenario.take_shared<ChannelRegistry>();
            let invite_config = scenario.take_shared<InviteConfig>();
            let post_comments_registry = scenario.take_shared<PostCommentsRegistry>();
            let post_likes_registry = scenario.take_shared<PostLikesRegistry>();
            let post_registry = scenario.take_shared<PostRegistry>();
            let user_invite_registry = scenario.take_shared<UserInviteRegistry>();
            let user_membership_registry = scenario.take_shared<UserMembershipRegistry>();
            let user_post_likes_registry = scenario.take_shared<UserPostLikesRegistry>();
            let user_posts_registry = scenario.take_shared<UserPostsRegistry>();
            let user_registry = scenario.take_shared<UserRegistry>();

            (
                channel_membership_registry,
                channel_posts_registry,
                channel_registry,
                post_comments_registry,
                post_likes_registry,
                post_registry,
                user_invite_registry,
                user_membership_registry,
                user_post_likes_registry,
                user_posts_registry,
                user_registry,
                invite_config
            )
        };

        (
            scenario_val,
            channel_membership_registry,
            channel_posts_registry,
            channel_registry,
            post_comments_registry,
            post_likes_registry,
            post_registry,
            user_invite_registry,
            user_membership_registry,
            user_post_likes_registry,
            user_posts_registry,
            user_registry,
            invite_config
        )
    }

    #[test]
    fun test_post_actions_init() {
        let (
            mut scenario_val,
            channel_membership_registry_val,
            channel_posts_registry_val,
            channel_registry_val,
            post_comments_registry_val,
            post_likes_registry_val,
            post_registry_val,
            user_invite_registry_val,
            user_membership_registry_val,
            user_post_likes_registry_val,
            user_posts_registry_val,
            user_registry_val,
            invite_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                channel_membership_registry_val,
                channel_posts_registry_val,
                channel_registry_val,
                post_comments_registry_val,
                post_likes_registry_val,
                post_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                user_post_likes_registry_val,
                user_posts_registry_val,
                user_registry_val,
                invite_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_post_from_channel() {
        let (
            mut scenario_val,
            mut channel_membership_registry_val,
            mut channel_posts_registry_val,
            mut channel_registry_val,
            post_comments_registry_val,
            post_likes_registry_val,
            mut post_registry_val,
            mut user_invite_registry_val,
            mut user_membership_registry_val,
            user_post_likes_registry_val,
            user_posts_registry_val,
            mut user_registry_val,
            mut invite_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let channel_registry = &mut channel_registry_val;
        let channel_membership_registry = &mut channel_membership_registry_val;
        let channel_posts_registry = &mut channel_posts_registry_val;
        let post_registry = &mut post_registry_val;
        let user_registry = &mut user_registry_val;
        let user_invite_registry = &mut user_invite_registry_val;
        let user_membership_registry = &mut user_membership_registry_val;

        let channel_name = utf8(b"channel-name");

        ts::next_tx(scenario, ADMIN);
        {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);
        };

        ts::next_tx(scenario, SERVER);
        {
            let invite_cap = ts::take_from_sender<InviteCap>(scenario);

            user_invite::set_invite_config(
                &invite_cap,
                &mut invite_config,
                false
            );

            ts::return_to_sender(scenario, invite_cap);
        };

        ts::next_tx(scenario, ADMIN);
        let clock = {
            let clock: Clock = ts::take_shared(scenario);

            let _user = user_actions::create(
                &clock,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                &invite_config,
                utf8(b""),
                utf8(b""),
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                utf8(b"user-name"),
                ts::ctx(scenario)
            );

            let _channel = channel_actions::create(
                &clock,
                channel_registry,
                channel_membership_registry,
                user_registry,
                channel_name,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                ts::ctx(scenario)
            );

            clock
        };

        ts::next_tx(scenario, ADMIN);
        {
            let post_key = post_actions::post_from_channel(
                &clock,
                channel_registry,
                channel_membership_registry,
                channel_posts_registry,
                post_registry,
                user_registry,
                channel_name,
                utf8(b"data"),
                utf8(b"description"),
                utf8(b"title"),
                ts::ctx(scenario)
            );

            let has_record = post_registry::has_record(
                post_registry,
                post_key
            );

            assert!(has_record, EPostNotCreated);

            let channel = channel_registry::borrow_channel(
                channel_registry,
                channel_name
            );

            let has_post = channel_posts::has_post(
                channel_posts_registry,
                channel,
                post_key
            );

            assert!(has_post, EChannelPostFailure);
        };

        ts::next_tx(scenario, ADMIN);
        {
            ts::return_shared(clock);

            destroy_for_testing(
                channel_membership_registry_val,
                channel_posts_registry_val,
                channel_registry_val,
                post_comments_registry_val,
                post_likes_registry_val,
                post_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                user_post_likes_registry_val,
                user_posts_registry_val,
                user_registry_val,
                invite_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EUserNotChannelMember)]
    fun test_post_from_channel_not_member() {
        let (
            mut scenario_val,
            mut channel_membership_registry_val,
            mut channel_posts_registry_val,
            mut channel_registry_val,
            post_comments_registry_val,
            post_likes_registry_val,
            mut post_registry_val,
            mut user_invite_registry_val,
            mut user_membership_registry_val,
            user_post_likes_registry_val,
            user_posts_registry_val,
            mut user_registry_val,
            mut invite_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let channel_registry = &mut channel_registry_val;
        let channel_membership_registry = &mut channel_membership_registry_val;
        let channel_posts_registry = &mut channel_posts_registry_val;
        let post_registry = &mut post_registry_val;
        let user_registry = &mut user_registry_val;
        let user_invite_registry = &mut user_invite_registry_val;
        let user_membership_registry = &mut user_membership_registry_val;

        let channel_name = utf8(b"channel-name");

        ts::next_tx(scenario, ADMIN);
        {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);
        };

        ts::next_tx(scenario, ADMIN);
        let clock = {
            let clock: Clock = ts::take_shared(scenario);

            clock
        };

        ts::next_tx(scenario, SERVER);
        {
            let invite_cap = ts::take_from_sender<InviteCap>(scenario);

            user_invite::set_invite_config(
                &invite_cap,
                &mut invite_config,
                false
            );

            ts::return_to_sender(scenario, invite_cap);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let _user = user_actions::create(
                &clock,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                &invite_config,
                utf8(b""),
                utf8(b""),
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                utf8(b"user-name"),
                ts::ctx(scenario)
            );

            let _channel = channel_actions::create(
                &clock,
                channel_registry,
                channel_membership_registry,
                user_registry,
                channel_name,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                ts::ctx(scenario)
            );

            channel_actions::leave(
                channel_registry,
                channel_membership_registry,
                user_registry,
                channel_name,
                ts::ctx(scenario)
            );

            post_actions::post_from_channel(
                &clock,
                channel_registry,
                channel_membership_registry,
                channel_posts_registry,
                post_registry,
                user_registry,
                channel_name,
                utf8(b"data"),
                utf8(b"description"),
                utf8(b"title"),
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            ts::return_shared(clock);

            destroy_for_testing(
                channel_membership_registry_val,
                channel_posts_registry_val,
                channel_registry_val,
                post_comments_registry_val,
                post_likes_registry_val,
                post_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                user_post_likes_registry_val,
                user_posts_registry_val,
                user_registry_val,
                invite_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_post_from_post() {
        let (
            mut scenario_val,
            mut channel_membership_registry_val,
            mut channel_posts_registry_val,
            mut channel_registry_val,
            mut post_comments_registry_val,
            post_likes_registry_val,
            mut post_registry_val,
            mut user_invite_registry_val,
            mut user_membership_registry_val,
            user_post_likes_registry_val,
            user_posts_registry_val,
            mut user_registry_val,
            mut invite_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;
        
        let channel_registry = &mut channel_registry_val;
        let channel_membership_registry = &mut channel_membership_registry_val;
        let channel_posts_registry = &mut channel_posts_registry_val;
        let post_comments_registry = &mut post_comments_registry_val;
        let post_registry = &mut post_registry_val;
        let user_registry = &mut user_registry_val;
        let user_invite_registry = &mut user_invite_registry_val;
        let user_membership_registry = &mut user_membership_registry_val;

        let channel_name = utf8(b"channel-name");

        ts::next_tx(scenario, ADMIN);
        {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);
        };

        ts::next_tx(scenario, SERVER);
        {
            let invite_cap = ts::take_from_sender<InviteCap>(scenario);

            user_invite::set_invite_config(
                &invite_cap,
                &mut invite_config,
                false
            );

            ts::return_to_sender(scenario, invite_cap);
        };

        ts::next_tx(scenario, ADMIN);
        let clock = {
            let clock: Clock = ts::take_shared(scenario);

            let _user = user_actions::create(
                &clock,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                &invite_config,
                utf8(b""),
                utf8(b""),
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                utf8(b"user-name"),
                ts::ctx(scenario)
            );

            let _channel = channel_actions::create(
                &clock,
                channel_registry,
                channel_membership_registry,
                user_registry,
                channel_name,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                ts::ctx(scenario)
            );

            clock
        };

        ts::next_tx(scenario, ADMIN);
        {
            let parent_post_key = post_actions::post_from_channel(
                &clock,
                channel_registry,
                channel_membership_registry,
                channel_posts_registry,
                post_registry,
                user_registry,
                channel_name,
                utf8(b"data"),
                utf8(b"description"),
                utf8(b"title"),
                ts::ctx(scenario)
            );

            let post_key = post_actions::post_from_post(
                &clock,
                post_registry,
                post_comments_registry,
                user_registry,
                parent_post_key,
                utf8(b"data"),
                utf8(b"description"),
                utf8(b"title"),
                ts::ctx(scenario)
            );

            let has_record = post_registry::has_record(
                post_registry,
                post_key
            );

            assert!(has_record, EPostNotCreated);

            let has_post = post_comments::has_post(
                post_comments_registry,
                parent_post_key,
                post_key
            );

            assert!(has_post, EPostCommentFailure);
        };

        ts::next_tx(scenario, ADMIN);
        {
            ts::return_shared(clock);

            destroy_for_testing(
                channel_membership_registry_val,
                channel_posts_registry_val,
                channel_registry_val,
                post_comments_registry_val,
                post_likes_registry_val,
                post_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                user_post_likes_registry_val,
                user_posts_registry_val,
                user_registry_val,
                invite_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_post_from_user_self() {
        let (
            mut scenario_val,
            channel_membership_registry_val,
            channel_posts_registry_val,
            channel_registry_val,
            post_comments_registry_val,
            post_likes_registry_val,
            mut post_registry_val,
            mut user_invite_registry_val,
            mut user_membership_registry_val,
            user_post_likes_registry_val,
            mut user_posts_registry_val,
            mut user_registry_val,
            mut invite_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let post_registry = &mut post_registry_val;
        let user_invite_registry = &mut user_invite_registry_val;
        let user_membership_registry = &mut user_membership_registry_val;
        let user_posts_registry = &mut user_posts_registry_val;
        let user_registry = &mut user_registry_val;

        let username = utf8(b"user-name");

        ts::next_tx(scenario, ADMIN);
        {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);
        };

        ts::next_tx(scenario, SERVER);
        {
            let invite_cap = ts::take_from_sender<InviteCap>(scenario);

            user_invite::set_invite_config(
                &invite_cap,
                &mut invite_config,
                false
            );

            ts::return_to_sender(scenario, invite_cap);
        };

        ts::next_tx(scenario, ADMIN);
        let clock = {
            let clock: Clock = ts::take_shared(scenario);

            let _user = user_actions::create(
                &clock,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                &invite_config,
                utf8(b""),
                utf8(b""),
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                username,
                ts::ctx(scenario)
            );

            clock
        };

        ts::next_tx(scenario, ADMIN);
        {
            let post_key = post_actions::post_from_user(
                &clock,
                post_registry,
                user_posts_registry,
                user_registry,
                utf8(b"data"),
                utf8(b"description"),
                utf8(b"title"),
                ADMIN,
                ts::ctx(scenario)
            );

            let has_record = post_registry::has_record(
                post_registry,
                post_key
            );

            assert!(has_record, EPostNotCreated);

            let username = user_registry::borrow_username(
                user_registry,
                ADMIN
            );

            let user = user_registry::borrow_user(
                user_registry,
                username
            );

            let has_post = user_posts::has_post(
                user_posts_registry,
                user,
                post_key
            );

            assert!(has_post, EUserPostFailure);
        };

        ts::next_tx(scenario, ADMIN);
        {
            ts::return_shared(clock);

            destroy_for_testing(
                channel_membership_registry_val,
                channel_posts_registry_val,
                channel_registry_val,
                post_comments_registry_val,
                post_likes_registry_val,
                post_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                user_post_likes_registry_val,
                user_posts_registry_val,
                user_registry_val,
                invite_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_post_from_user_other() {
        let (
            mut scenario_val,
            channel_membership_registry_val,
            channel_posts_registry_val,
            channel_registry_val,
            post_comments_registry_val,
            post_likes_registry_val,
            mut post_registry_val,
            mut user_invite_registry_val,
            mut user_membership_registry_val,
            user_post_likes_registry_val,
            mut user_posts_registry_val,
            mut user_registry_val,
            mut invite_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let post_registry = &mut post_registry_val;
        let user_invite_registry = &mut user_invite_registry_val;
        let user_membership_registry = &mut user_membership_registry_val;
        let user_posts_registry = &mut user_posts_registry_val;
        let user_registry = &mut user_registry_val;

        let username = utf8(b"user-name");

        ts::next_tx(scenario, ADMIN);
        {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);
        };

        ts::next_tx(scenario, SERVER);
        {
            let invite_cap = ts::take_from_sender<InviteCap>(scenario);

            user_invite::set_invite_config(
                &invite_cap,
                &mut invite_config,
                false
            );

            ts::return_to_sender(scenario, invite_cap);
        };

        ts::next_tx(scenario, ADMIN);
        let clock = {
            let clock: Clock = ts::take_shared(scenario);

            let _user = user_actions::create(
                &clock,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                &invite_config,
                utf8(b""),
                utf8(b""),
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                utf8(b"user-admin"),
                ts::ctx(scenario)
            );

            clock
        };

        ts::next_tx(scenario, OTHER);
        {
            let _user = user_actions::create(
                &clock,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                &invite_config,
                utf8(b""),
                utf8(b""),
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                username,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let post_key = post_actions::post_from_user(
                &clock,
                post_registry,
                user_posts_registry,
                user_registry,
                utf8(b"data"),
                utf8(b"description"),
                utf8(b"title"),
                OTHER,
                ts::ctx(scenario)
            );

            let has_record = post_registry::has_record(
                post_registry,
                post_key
            );

            assert!(has_record, EPostNotCreated);

            let username = user_registry::borrow_username(
                user_registry,
                OTHER
            );

            let user = user_registry::borrow_user(
                user_registry,
                username
            );

            let has_post = user_posts::has_post(
                user_posts_registry,
                user,
                post_key
            );

            assert!(has_post, EUserPostFailure);
        };

        ts::next_tx(scenario, ADMIN);
        {
            ts::return_shared(clock);

            destroy_for_testing(
                channel_membership_registry_val,
                channel_posts_registry_val,
                channel_registry_val,
                post_comments_registry_val,
                post_likes_registry_val,
                post_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                user_post_likes_registry_val,
                user_posts_registry_val,
                user_registry_val,
                invite_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_post_like() {
        let (
            mut scenario_val,
            channel_membership_registry_val,
            channel_posts_registry_val,
            channel_registry_val,
            post_comments_registry_val,
            mut post_likes_registry_val,
            mut post_registry_val,
            mut user_invite_registry_val,
            mut user_membership_registry_val,
            mut user_post_likes_registry_val,
            mut user_posts_registry_val,
            mut user_registry_val,
            mut invite_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let post_likes_registry = &mut post_likes_registry_val;
        let post_registry = &mut post_registry_val;
        let user_invite_registry = &mut user_invite_registry_val;
        let user_membership_registry = &mut user_membership_registry_val;
        let user_post_likes_registry = &mut user_post_likes_registry_val;
        let user_posts_registry = &mut user_posts_registry_val;
        let user_registry = &mut user_registry_val;

        let username = utf8(b"user-name");

        ts::next_tx(scenario, ADMIN);
        {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);
        };

        ts::next_tx(scenario, SERVER);
        {
            let invite_cap = ts::take_from_sender<InviteCap>(scenario);

            user_invite::set_invite_config(
                &invite_cap,
                &mut invite_config,
                false
            );

            ts::return_to_sender(scenario, invite_cap);
        };

        ts::next_tx(scenario, ADMIN);
        let clock = {
            let clock: Clock = ts::take_shared(scenario);

            let _user = user_actions::create(
                &clock,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                &invite_config,
                utf8(b""),
                utf8(b""),
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                username,
                ts::ctx(scenario)
            );

            clock
        };

        ts::next_tx(scenario, ADMIN);
        {
            let post_key = post_actions::post_from_user(
                &clock,
                post_registry,
                user_posts_registry,
                user_registry,
                utf8(b"data"),
                utf8(b"description"),
                utf8(b"title"),
                ADMIN,
                ts::ctx(scenario)
            );

            post_actions::like(
                post_registry,
                post_likes_registry,
                user_registry,
                user_post_likes_registry,
                post_key,
                ts::ctx(scenario)
            );

            let post_likes = post_likes::borrow_post_likes_mut(
                post_likes_registry,
                post_key
            );

            let post_liked = post_likes::has_post_likes(
                post_likes,
                ADMIN
            );

            assert!(post_liked, EPostNotLiked);

            let user_post_likes = post_likes::borrow_user_post_likes_mut(
                user_post_likes_registry,
                ADMIN
            );

            let post_liked = post_likes::has_user_likes(
                user_post_likes,
                post_key
            );

            assert!(post_liked, EPostNotLiked);
        };

        ts::next_tx(scenario, ADMIN);
        {
            ts::return_shared(clock);

            destroy_for_testing(
                channel_membership_registry_val,
                channel_posts_registry_val,
                channel_registry_val,
                post_comments_registry_val,
                post_likes_registry_val,
                post_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                user_post_likes_registry_val,
                user_posts_registry_val,
                user_registry_val,
                invite_config
            );
        };

        ts::end(scenario_val);
    }
}
