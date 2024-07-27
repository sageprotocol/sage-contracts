#[test_only]
module sage_post::test_post_actions {
    use std::string::{utf8};

    use sui::test_scenario::{Self as ts, Scenario};

    use sui::clock::{Self, Clock};
    use sui::{table::{ETableNotEmpty}};

    use sage_admin::{admin::{Self, AdminCap}};

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
        user_registry::{Self, UserRegistry}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    const EChannelPostFailure: u64 = 0;
    const EPostCommentFailure: u64 = 1;
    const EPostNotCreated: u64 = 2;
    const EPostNotLiked: u64 = 3;
    const EUserPostFailure: u64 = 4;

    // --------------- Test Functions ---------------

    #[test_only]
    fun setup_for_testing(): (
        Scenario,
        ChannelMembershipRegistry,
        ChannelPostsRegistry,
        ChannelRegistry,
        PostCommentsRegistry,
        PostLikesRegistry,
        PostRegistry,
        UserPostLikesRegistry,
        UserPostsRegistry,
        UserRegistry
    ) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let (
            channel_membership_registry,
            channel_posts_registry,
            channel_registry,
            post_comments_registry,
            post_likes_registry,
            post_registry,
            user_post_likes_registry,
            user_posts_registry,
            user_registry
        ) = {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            let channel_membership_registry = channel_membership::create_channel_membership_registry(
                &admin_cap,
                ts::ctx(scenario)
            );
            let channel_posts_registry = channel_posts::create_channel_posts_registry(
                &admin_cap,
                ts::ctx(scenario)
            );
            let channel_registry = channel_registry::create_channel_registry(
                &admin_cap,
                ts::ctx(scenario)
            );
            let post_comments_registry = post_comments::create_post_comments_registry(
                &admin_cap,
                ts::ctx(scenario)
            );
            let post_likes_registry = post_likes::create_post_likes_registry(
                &admin_cap,
                ts::ctx(scenario)
            );
            let post_registry = post_registry::create_post_registry(
                &admin_cap,
                ts::ctx(scenario)
            );
            let user_post_likes_registry = post_likes::create_user_post_likes_registry(
                &admin_cap,
                ts::ctx(scenario)
            );
            let user_posts_registry = user_posts::create_user_posts_registry(
                &admin_cap,
                ts::ctx(scenario)
            );
            let user_registry = user_registry::create_user_registry(
                &admin_cap,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, admin_cap);

            (
                channel_membership_registry,
                channel_posts_registry,
                channel_registry,
                post_comments_registry,
                post_likes_registry,
                post_registry,
                user_post_likes_registry,
                user_posts_registry,
                user_registry
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
            user_post_likes_registry,
            user_posts_registry,
            user_registry
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
            user_post_likes_registry_val,
            user_posts_registry_val,
            user_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            channel_membership::destroy_for_testing(channel_membership_registry_val);
            channel_posts::destroy_for_testing(channel_posts_registry_val);
            channel_registry::destroy_for_testing(channel_registry_val);
            post_comments::destroy_for_testing(post_comments_registry_val);
            post_likes::destroy_for_testing(post_likes_registry_val, user_post_likes_registry_val);
            post_registry::destroy_for_testing(post_registry_val);
            user_posts::destroy_for_testing(user_posts_registry_val);
            user_registry::destroy_for_testing(user_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ETableNotEmpty)]
    fun test_post_from_channel() {
        let (
            mut scenario_val,
            mut channel_membership_registry_val,
            mut channel_posts_registry_val,
            mut channel_registry_val,
            post_comments_registry_val,
            post_likes_registry_val,
            mut post_registry_val,
            user_post_likes_registry_val,
            user_posts_registry_val,
            user_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let channel_registry = &mut channel_registry_val;
        let channel_membership_registry = &mut channel_membership_registry_val;
        let channel_posts_registry = &mut channel_posts_registry_val;
        let post_registry = &mut post_registry_val;

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

            let _channel = channel_actions::create(
                &clock,
                channel_registry,
                channel_membership_registry,
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

            let channel = channel_registry::get_channel(
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

            channel_membership::destroy_for_testing(channel_membership_registry_val);
            channel_posts::destroy_for_testing(channel_posts_registry_val);
            channel_registry::destroy_for_testing(channel_registry_val);
            post_comments::destroy_for_testing(post_comments_registry_val);
            post_likes::destroy_for_testing(post_likes_registry_val, user_post_likes_registry_val);
            post_registry::destroy_for_testing(post_registry_val);
            user_posts::destroy_for_testing(user_posts_registry_val);
            user_registry::destroy_for_testing(user_registry_val);
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
            user_post_likes_registry_val,
            user_posts_registry_val,
            user_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let channel_registry = &mut channel_registry_val;
        let channel_membership_registry = &mut channel_membership_registry_val;
        let channel_posts_registry = &mut channel_posts_registry_val;
        let post_registry = &mut post_registry_val;

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

        ts::next_tx(scenario, ADMIN);
        {
            let channel = channel_actions::create(
                &clock,
                channel_registry,
                channel_membership_registry,
                channel_name,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                ts::ctx(scenario)
            );

            let channel_membership = channel_membership::borrow_membership_mut(
                channel_membership_registry,
                channel
            );

            channel_membership::leave(
                channel_membership,
                channel_name,
                ts::ctx(scenario)
            );

            post_actions::post_from_channel(
                &clock,
                channel_registry,
                channel_membership_registry,
                channel_posts_registry,
                post_registry,
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

            channel_membership::destroy_for_testing(channel_membership_registry_val);
            channel_posts::destroy_for_testing(channel_posts_registry_val);
            channel_registry::destroy_for_testing(channel_registry_val);
            post_comments::destroy_for_testing(post_comments_registry_val);
            post_likes::destroy_for_testing(post_likes_registry_val, user_post_likes_registry_val);
            post_registry::destroy_for_testing(post_registry_val);
            user_posts::destroy_for_testing(user_posts_registry_val);
            user_registry::destroy_for_testing(user_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ETableNotEmpty)]
    fun test_post_from_post() {
        let (
            mut scenario_val,
            mut channel_membership_registry_val,
            mut channel_posts_registry_val,
            mut channel_registry_val,
            mut post_comments_registry_val,
            post_likes_registry_val,
            mut post_registry_val,
            user_post_likes_registry_val,
            user_posts_registry_val,
            user_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;
        
        let channel_registry = &mut channel_registry_val;
        let channel_membership_registry = &mut channel_membership_registry_val;
        let channel_posts_registry = &mut channel_posts_registry_val;
        let post_comments_registry = &mut post_comments_registry_val;
        let post_registry = &mut post_registry_val;

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

            let _channel = channel_actions::create(
                &clock,
                channel_registry,
                channel_membership_registry,
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

            channel_membership::destroy_for_testing(channel_membership_registry_val);
            channel_posts::destroy_for_testing(channel_posts_registry_val);
            channel_registry::destroy_for_testing(channel_registry_val);
            post_comments::destroy_for_testing(post_comments_registry_val);
            post_likes::destroy_for_testing(post_likes_registry_val, user_post_likes_registry_val);
            post_registry::destroy_for_testing(post_registry_val);
            user_posts::destroy_for_testing(user_posts_registry_val);
            user_registry::destroy_for_testing(user_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_post_from_user() {
        let (
            mut scenario_val,
            channel_membership_registry_val,
            channel_posts_registry_val,
            channel_registry_val,
            post_comments_registry_val,
            post_likes_registry_val,
            mut post_registry_val,
            user_post_likes_registry_val,
            mut user_posts_registry_val,
            mut user_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let post_registry = &mut post_registry_val;
        let user_posts_registry = &mut user_posts_registry_val;
        let user_registry = &mut user_registry_val;

        let username = utf8(b"user-name");

        ts::next_tx(scenario, ADMIN);
        {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);
        };

        ts::next_tx(scenario, ADMIN);
        let clock = {
            let clock: Clock = ts::take_shared(scenario);

            let _user = user_actions::create(
                &clock,
                user_registry,
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
                ts::ctx(scenario)
            );

            let has_record = post_registry::has_record(
                post_registry,
                post_key
            );

            assert!(has_record, EPostNotCreated);

            let username = user_registry::get_username(
                user_registry,
                ADMIN
            );

            let user = user_registry::get_user(
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

            channel_membership::destroy_for_testing(channel_membership_registry_val);
            channel_posts::destroy_for_testing(channel_posts_registry_val);
            channel_registry::destroy_for_testing(channel_registry_val);
            post_comments::destroy_for_testing(post_comments_registry_val);
            post_likes::destroy_for_testing(post_likes_registry_val, user_post_likes_registry_val);
            post_registry::destroy_for_testing(post_registry_val);
            user_posts::destroy_for_testing(user_posts_registry_val);
            user_registry::destroy_for_testing(user_registry_val);
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
            mut user_post_likes_registry_val,
            mut user_posts_registry_val,
            mut user_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let post_likes_registry = &mut post_likes_registry_val;
        let post_registry = &mut post_registry_val;
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

        ts::next_tx(scenario, ADMIN);
        let clock = {
            let clock: Clock = ts::take_shared(scenario);

            let _user = user_actions::create(
                &clock,
                user_registry,
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
                ts::ctx(scenario)
            );

            post_actions::like(
                post_registry,
                post_likes_registry,
                user_post_likes_registry,
                post_key,
                ts::ctx(scenario)
            );

            let post_likes = post_likes::borrow_post_likes(
                post_likes_registry,
                post_key
            );

            let post_liked = post_likes::has_post_likes(
                post_likes,
                ADMIN
            );

            assert!(post_liked, EPostNotLiked);

            let user_post_likes = post_likes::borrow_user_post_likes(
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

            channel_membership::destroy_for_testing(channel_membership_registry_val);
            channel_posts::destroy_for_testing(channel_posts_registry_val);
            channel_registry::destroy_for_testing(channel_registry_val);
            post_comments::destroy_for_testing(post_comments_registry_val);
            post_likes::destroy_for_testing(post_likes_registry_val, user_post_likes_registry_val);
            post_registry::destroy_for_testing(post_registry_val);
            user_posts::destroy_for_testing(user_posts_registry_val);
            user_registry::destroy_for_testing(user_registry_val);
        };

        ts::end(scenario_val);
    }
}
