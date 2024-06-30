module sage::test_channel_posts {
    use std::string::{utf8};

    use sui::test_scenario::{Self as ts, Scenario};

    use sage::{
        admin::{Self, AdminCap},
        channel::{Self},
        channel_posts::{Self, ChannelPostsRegistry},
        post::{Self}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @0xde1;

    // --------------- Errors ---------------

    const EChannelPostsExists: u64 = 0;
    const EChannelPostsDoesNotExist: u64 = 1;
    const EChannelPostMismatch: u64 = 3;

    // --------------- Test Functions ---------------

    #[test_only]
    fun setup_for_testing(): (Scenario, ChannelPostsRegistry) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let channel_posts_registry = {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            let channel_posts_registry = channel_posts::create_channel_posts_registry(
                &admin_cap,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, admin_cap);

            channel_posts_registry
        };

        (scenario_val, channel_posts_registry)
    }

    #[test]
    fun test_channel_posts_init() {
        let (
            mut scenario_val,
            channel_posts_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            channel_posts::destroy_for_testing(channel_posts_registry_val);
        };

        ts::end(scenario_val);
    }

     #[test]
    fun test_channel_posts_create() {
        let (
            mut scenario_val,
            mut channel_posts_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let created_at: u64 = 999;

            let channel = channel::create_for_testing(
                utf8(b"channel-name"),
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                created_at,
                ADMIN
            );

            let channel_posts_registry = &mut channel_posts_registry_val;

            let has_record = channel_posts::has_record(
                channel_posts_registry,
                channel
            );

            assert!(!has_record, EChannelPostsExists);

            channel_posts::create(
                channel_posts_registry,
                channel,
                ts::ctx(scenario)
            );

            let has_record = channel_posts::has_record(
                channel_posts_registry,
                channel
            );

            assert!(has_record, EChannelPostsDoesNotExist);

            channel_posts::destroy_for_testing(channel_posts_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_channel_posts_add() {
        let (
            mut scenario_val,
            mut channel_posts_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let created_at: u64 = 999;

            let channel = channel::create_for_testing(
                utf8(b"channel-name"),
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                created_at,
                ADMIN
            );

            let channel_posts_registry = &mut channel_posts_registry_val;

            channel_posts::create(
                channel_posts_registry,
                channel,
                ts::ctx(scenario)
            );

            let channel_posts = channel_posts::get_channel_posts(
                channel_posts_registry,
                channel
            );

            let timestamp: u64 = 999;
            let user: address = @0xaaa;

            let (post, post_id) = post::create(
                user,
                utf8(b"data"),
                utf8(b"description"),
                utf8(b"title"),
                timestamp,
                ts::ctx(scenario)
            );

            channel_posts::add(
                channel_posts,
                post_id,
                post
            );

            let has_post = channel_posts::has_post(
                channel_posts,
                post_id
            );

            assert!(has_post, EChannelPostMismatch);

            channel_posts::destroy_for_testing(channel_posts_registry_val);
        };

        ts::end(scenario_val);
    }
}
