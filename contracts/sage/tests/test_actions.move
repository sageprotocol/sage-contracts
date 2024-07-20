#[test_only]
module sage::test_sage_actions {
    use std::string::{utf8};

    use sui::test_scenario::{Self as ts};

    use sui::clock::{Self, Clock};

    use sage::{
        actions::{Self},
        test_common::{Self}
    };

    use sage_admin::{
        admin::{Self, NotificationCap}
    };

    use sage_channel::{
        channel_registry::{Self}
    };

    use sage_notification::{
        notification_registry::{Self}
    };

    use sage_post::{
        channel_posts::{Self},
        post_comments::{Self},
        post_likes::{Self},
        user_posts::{Self}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;
    const NOTIFICATION: address = @notification;

    // --------------- Errors ---------------

    const EChannelNotCreated: u64 = 0;
    const EChannelPostNotCreated: u64 = 1;
    const EPostCommentNotCreated: u64 = 2;
    const EPostLikeNotCreated: u64 = 3;
    const EUserNotificationsMismatch: u64 = 4;
    const EUserPostNotCreated: u64 = 5;

    // --------------- Test Functions ---------------

    #[test]
    fun test_create_channel() {
        let (
            mut scenario_val,
            mut sage_channel,
            mut sage_channel_membership,
            sage_channel_posts,
            sage_notification,
            sage_post_comments,
            sage_post_likes,
            sage_user_membership,
            sage_user_post_likes,
            sage_user_posts,
            sage_users
        ) = test_common::setup_for_testing();

        let scenario = &mut scenario_val;

        let channel_name = utf8(b"channel-name");

        ts::next_tx(scenario, ADMIN);
        {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let clock: Clock = ts::take_shared(scenario);

            let channel = actions::create_channel(
                &clock,
                &mut sage_channel,
                &mut sage_channel_membership,
                channel_name,
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                utf8(b"description"),
                ts::ctx(scenario)
            );

            let channel_registry = actions::borrow_channel_registry_for_testing(
                &mut sage_channel
            );

            let retrieved_channel_name = channel_registry::get_channel_name(
                channel_registry,
                channel
            );

            assert!(channel_name == retrieved_channel_name, EChannelNotCreated);

            actions::destroy_channel_for_testing(sage_channel);
            actions::destroy_channel_membership_for_testing(sage_channel_membership);
            actions::destroy_channel_posts_for_testing(sage_channel_posts);
            actions::destroy_notification_for_testing(sage_notification);
            actions::destroy_post_comments_for_testing(sage_post_comments);
            actions::destroy_post_likes_for_testing(sage_post_likes);
            actions::destroy_user_membership_for_testing(sage_user_membership);
            actions::destroy_user_post_likes_for_testing(sage_user_post_likes);
            actions::destroy_user_posts_for_testing(sage_user_posts);
            actions::destroy_users_for_testing(sage_users);

            ts::return_shared(clock);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_create_notification() {
        let (
            mut scenario_val,
            sage_channel,
            sage_channel_membership,
            sage_channel_posts,
            mut sage_notification,
            sage_post_comments,
            sage_post_likes,
            sage_user_membership,
            sage_user_post_likes,
            sage_user_posts,
            sage_users
        ) = test_common::setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            admin::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, NOTIFICATION);
        let notification_cap = {
            let notification_cap = ts::take_from_sender<NotificationCap>(scenario);

            notification_cap
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let clock: Clock = ts::take_shared(scenario);

            let reward_amount: u64 = 5;
            let user: address = @0xaaa;

            let _notification = actions::create_notification(
                &notification_cap,
                &clock,
                &mut sage_notification,
                user,
                utf8(b"message"),
                reward_amount
            );

            let notification_registry = actions::borrow_notification_registry_for_testing(
                &mut sage_notification
            );

            let user_notifications = notification_registry::borrow_user_notifications(
                notification_registry,
                user
            );

            let notifications_count = notification_registry::get_user_notifications_count(
                user_notifications
            );

            assert!(notifications_count == 1, EUserNotificationsMismatch);

            actions::destroy_channel_for_testing(sage_channel);
            actions::destroy_channel_membership_for_testing(sage_channel_membership);
            actions::destroy_channel_posts_for_testing(sage_channel_posts);
            actions::destroy_notification_for_testing(sage_notification);
            actions::destroy_post_comments_for_testing(sage_post_comments);
            actions::destroy_post_likes_for_testing(sage_post_likes);
            actions::destroy_user_membership_for_testing(sage_user_membership);
            actions::destroy_user_post_likes_for_testing(sage_user_post_likes);
            actions::destroy_user_posts_for_testing(sage_user_posts);
            actions::destroy_users_for_testing(sage_users);

            ts::return_shared(clock);
        };

        ts::next_tx(scenario, NOTIFICATION);
        {
            ts::return_to_sender(scenario, notification_cap);
        };

        ts::end(scenario_val);
    }

    // Untestable?
    //
    // #[test]
    // fun test_join_channel() {}
    //
    // #[test]
    // fun test_leave_channel() {}
    //
    // #[test]
    // fun test_join_user() {}
    //
    // #[test]
    // fun test_leave_user() {}

    #[test]
    fun test_post_from_channel() {
        let (
            mut scenario_val,
            mut sage_channel,
            mut sage_channel_membership,
            mut sage_channel_posts,
            sage_notification,
            mut sage_post_comments,
            mut sage_post_likes,
            sage_user_membership,
            sage_user_post_likes,
            sage_user_posts,
            sage_users
        ) = test_common::setup_for_testing();

        let scenario = &mut scenario_val;

        let channel_name = utf8(b"channel-name");

        ts::next_tx(scenario, ADMIN);
        {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let clock: Clock = ts::take_shared(scenario);

            let channel = actions::create_channel(
                &clock,
                &mut sage_channel,
                &mut sage_channel_membership,
                channel_name,
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                utf8(b"description"),
                ts::ctx(scenario)
            );

            // create a post
            let post_id = actions::post_from_channel(
                &clock,
                &mut sage_channel,
                &mut sage_channel_membership,
                &mut sage_channel_posts,
                &mut sage_post_comments,
                &mut sage_post_likes,
                channel_name,
                utf8(b"data"),
                utf8(b"description"),
                utf8(b"title"),
                ts::ctx(scenario)
            );

            let channel_posts_registry = actions::borrow_channel_posts_registry_for_testing(
                &mut sage_channel_posts
            );

            let channel_posts = channel_posts::get_channel_posts(
                channel_posts_registry,
                channel
            );

            let has_post = channel_posts::has_post(
                channel_posts,
                post_id
            );

            assert!(has_post, EChannelPostNotCreated);

            // create another post
            let post_id = actions::post_from_channel(
                &clock,
                &mut sage_channel,
                &mut sage_channel_membership,
                &mut sage_channel_posts,
                &mut sage_post_comments,
                &mut sage_post_likes,
                channel_name,
                utf8(b"data"),
                utf8(b"description"),
                utf8(b"title"),
                ts::ctx(scenario)
            );

            let channel_posts_registry = actions::borrow_channel_posts_registry_for_testing(
                &mut sage_channel_posts
            );

            let channel_posts = channel_posts::get_channel_posts(
                channel_posts_registry,
                channel
            );

            let has_post = channel_posts::has_post(
                channel_posts,
                post_id
            );

            assert!(has_post, EChannelPostNotCreated);

            actions::destroy_channel_for_testing(sage_channel);
            actions::destroy_channel_membership_for_testing(sage_channel_membership);
            actions::destroy_channel_posts_for_testing(sage_channel_posts);
            actions::destroy_notification_for_testing(sage_notification);
            actions::destroy_post_comments_for_testing(sage_post_comments);
            actions::destroy_post_likes_for_testing(sage_post_likes);
            actions::destroy_user_membership_for_testing(sage_user_membership);
            actions::destroy_user_post_likes_for_testing(sage_user_post_likes);
            actions::destroy_user_posts_for_testing(sage_user_posts);
            actions::destroy_users_for_testing(sage_users);

            ts::return_shared(clock);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_post_from_post() {
        let (
            mut scenario_val,
            mut sage_channel,
            mut sage_channel_membership,
            mut sage_channel_posts,
            sage_notification,
            mut sage_post_comments,
            mut sage_post_likes,
            sage_user_membership,
            sage_user_post_likes,
            sage_user_posts,
            sage_users
        ) = test_common::setup_for_testing();

        let scenario = &mut scenario_val;

        let channel_name = utf8(b"channel-name");

        ts::next_tx(scenario, ADMIN);
        {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let clock: Clock = ts::take_shared(scenario);

            let channel = actions::create_channel(
                &clock,
                &mut sage_channel,
                &mut sage_channel_membership,
                channel_name,
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                utf8(b"description"),
                ts::ctx(scenario)
            );

            let parent_post_id = actions::post_from_channel(
                &clock,
                &mut sage_channel,
                &mut sage_channel_membership,
                &mut sage_channel_posts,
                &mut sage_post_comments,
                &mut sage_post_likes,
                channel_name,
                utf8(b"data"),
                utf8(b"description"),
                utf8(b"title"),
                ts::ctx(scenario)
            );

            let channel_posts_registry = actions::borrow_channel_posts_registry_for_testing(
                &mut sage_channel_posts
            );

            let channel_posts = channel_posts::get_channel_posts(
                channel_posts_registry,
                channel
            );

            let parent_post = channel_posts::borrow_post(
                channel_posts,
                parent_post_id
            );

            let post_id = actions::post_from_post(
                &clock,
                &mut sage_post_comments,
                &mut sage_post_likes,
                parent_post,
                utf8(b"data"),
                utf8(b"description"),
                utf8(b"title"),
                ts::ctx(scenario)
            );

            let post_comments_registry = actions::borrow_posts_comments_registry_for_testing(
                &mut sage_post_comments
            );

            let post_comments = post_comments::get_post_comments(
                post_comments_registry,
                parent_post_id
            );

            let has_post = post_comments::has_post(
                post_comments,
                post_id
            );

            assert!(has_post, EPostCommentNotCreated);

            actions::destroy_channel_for_testing(sage_channel);
            actions::destroy_channel_membership_for_testing(sage_channel_membership);
            actions::destroy_channel_posts_for_testing(sage_channel_posts);
            actions::destroy_notification_for_testing(sage_notification);
            actions::destroy_post_comments_for_testing(sage_post_comments);
            actions::destroy_post_likes_for_testing(sage_post_likes);
            actions::destroy_user_membership_for_testing(sage_user_membership);
            actions::destroy_user_post_likes_for_testing(sage_user_post_likes);
            actions::destroy_user_posts_for_testing(sage_user_posts);
            actions::destroy_users_for_testing(sage_users);

            ts::return_shared(clock);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_post_from_user() {
        let (
            mut scenario_val,
            sage_channel,
            sage_channel_membership,
            sage_channel_posts,
            sage_notification,
            mut sage_post_comments,
            mut sage_post_likes,
            sage_user_membership,
            sage_user_post_likes,
            mut sage_user_posts,
            mut sage_users
        ) = test_common::setup_for_testing();

        let scenario = &mut scenario_val;

        let username = utf8(b"user-name");

        ts::next_tx(scenario, ADMIN);
        {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let clock: Clock = ts::take_shared(scenario);

            let user = actions::create_user(
                &clock,
                &mut sage_users,
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                utf8(b"description"),
                username,
                ts::ctx(scenario)
            );

            let post_id = actions::post_from_user(
                &clock,
                &mut sage_post_comments,
                &mut sage_post_likes,
                &mut sage_user_posts,
                &mut sage_users,
                utf8(b"data"),
                utf8(b"description"),
                utf8(b"title"),
                ts::ctx(scenario)
            );

            let user_posts_registry = actions::borrow_user_posts_registry_for_testing(
                &mut sage_user_posts
            );

            let user_posts = user_posts::get_user_posts(
                user_posts_registry,
                user
            );

            let has_post = user_posts::has_post(
                user_posts,
                post_id
            );

            assert!(has_post, EUserPostNotCreated);

            actions::destroy_channel_for_testing(sage_channel);
            actions::destroy_channel_membership_for_testing(sage_channel_membership);
            actions::destroy_channel_posts_for_testing(sage_channel_posts);
            actions::destroy_notification_for_testing(sage_notification);
            actions::destroy_post_comments_for_testing(sage_post_comments);
            actions::destroy_post_likes_for_testing(sage_post_likes);
            actions::destroy_user_membership_for_testing(sage_user_membership);
            actions::destroy_user_post_likes_for_testing(sage_user_post_likes);
            actions::destroy_user_posts_for_testing(sage_user_posts);
            actions::destroy_users_for_testing(sage_users);

            ts::return_shared(clock);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_like_post() {
        let (
            mut scenario_val,
            mut sage_channel,
            mut sage_channel_membership,
            mut sage_channel_posts,
            sage_notification,
            mut sage_post_comments,
            mut sage_post_likes,
            sage_user_membership,
            mut sage_user_post_likes,
            sage_user_posts,
            sage_users
        ) = test_common::setup_for_testing();

        let scenario = &mut scenario_val;

        let channel_name = utf8(b"channel-name");

        ts::next_tx(scenario, ADMIN);
        {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let clock: Clock = ts::take_shared(scenario);

            let channel = actions::create_channel(
                &clock,
                &mut sage_channel,
                &mut sage_channel_membership,
                channel_name,
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                utf8(b"description"),
                ts::ctx(scenario)
            );

            let post_id = actions::post_from_channel(
                &clock,
                &mut sage_channel,
                &mut sage_channel_membership,
                &mut sage_channel_posts,
                &mut sage_post_comments,
                &mut sage_post_likes,
                channel_name,
                utf8(b"data"),
                utf8(b"description"),
                utf8(b"title"),
                ts::ctx(scenario)
            );

            let channel_posts_registry = actions::borrow_channel_posts_registry_for_testing(
                &mut sage_channel_posts
            );
            let channel_posts = channel_posts::get_channel_posts(
                channel_posts_registry,
                channel
            );

            let post = channel_posts::borrow_post(
                channel_posts,
                post_id
            );

            actions::like_post(
                &mut sage_post_likes,
                &mut sage_user_post_likes,
                post,
                ts::ctx(scenario)
            );

            let post_likes_registry = actions::borrow_posts_likes_registry_for_testing(
                &mut sage_post_likes
            );
            let user_post_likes_registry = actions::borrow_user_posts_likes_registry_for_testing(
                &mut sage_user_post_likes
            );

            let post_likes = post_likes::get_post_likes(
                post_likes_registry,
                post_id
            );
            let user_post_likes = post_likes::get_user_post_likes(
                user_post_likes_registry,
                ADMIN
            );

            let has_post_like_record = post_likes::has_post_likes(
                post_likes,
                ADMIN
            );
            let has_user_like_record = post_likes::has_user_likes(
                user_post_likes,
                post_id
            );

            assert!(has_post_like_record, EPostLikeNotCreated);
            assert!(has_user_like_record, EPostLikeNotCreated);

            actions::destroy_channel_for_testing(sage_channel);
            actions::destroy_channel_membership_for_testing(sage_channel_membership);
            actions::destroy_channel_posts_for_testing(sage_channel_posts);
            actions::destroy_notification_for_testing(sage_notification);
            actions::destroy_post_comments_for_testing(sage_post_comments);
            actions::destroy_post_likes_for_testing(sage_post_likes);
            actions::destroy_user_membership_for_testing(sage_user_membership);
            actions::destroy_user_post_likes_for_testing(sage_user_post_likes);
            actions::destroy_user_posts_for_testing(sage_user_posts);
            actions::destroy_users_for_testing(sage_users);

            ts::return_shared(clock);
        };

        ts::end(scenario_val);
    }
}
