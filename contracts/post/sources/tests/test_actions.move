#[test_only]
module sage::test_actions {
    use std::string::{utf8};

    use sui::test_scenario::{Self as ts, Scenario};

    use sui::clock::{Self, Clock};
    // use sui::{table::{ETableNotEmpty}};

    use sage::{
        actions::{Self},
        admin::{Self, AdminCap},
        channel::{Self},
        channel_membership::{Self, ChannelMembershipRegistry},
        channel_posts::{Self, ChannelPostsRegistry},
        channel_registry::{Self, ChannelRegistry},
        post_comments::{Self, PostCommentsRegistry},
        post_likes::{Self, PostLikesRegistry}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @0xde1;

    // --------------- Errors ---------------

    // const EPostNotLiked: u64 = 0;

    // --------------- Test Functions ---------------

    #[test_only]
    fun setup_for_testing(): (Scenario, ChannelMembershipRegistry, ChannelPostsRegistry, ChannelRegistry, PostCommentsRegistry, PostLikesRegistry) {
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
            post_likes_registry
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

            ts::return_to_sender(scenario, admin_cap);

            (channel_membership_registry, channel_posts_registry, channel_registry, post_comments_registry, post_likes_registry)
        };

        (scenario_val, channel_membership_registry, channel_posts_registry, channel_registry, post_comments_registry, post_likes_registry)
    }

    #[test]
    fun test_post_actions_init() {
        let (
            mut scenario_val,
            channel_membership_registry_val,
            channel_posts_registry_val,
            channel_registry_val,
            post_comments_registry_val,
            post_likes_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            channel_membership::destroy_for_testing(channel_membership_registry_val);
            channel_posts::destroy_for_testing(channel_posts_registry_val);
            channel_registry::destroy_for_testing(channel_registry_val);
            post_comments::destroy_for_testing(post_comments_registry_val);
            post_likes::destroy_for_testing(post_likes_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    // #[expected_failure(abort_code = ETableNotEmpty)]
    fun test_post_from_channel() {
        let (
            mut scenario_val,
            mut channel_membership_registry_val,
            mut channel_posts_registry_val,
            mut channel_registry_val,
            mut post_comments_registry_val,
            mut post_likes_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let channel_registry = &mut channel_registry_val;
        let channel_membership_registry = &mut channel_membership_registry_val;
        let channel_posts_registry = &mut channel_posts_registry_val;
        let post_comments_registry = &mut post_comments_registry_val;
        let post_likes_registry = &mut post_likes_registry_val;

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

            let _channel_id = channel::create(
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
            actions::post_from_channel(
                &clock,
                channel_registry,
                channel_posts_registry,
                post_comments_registry,
                post_likes_registry,
                channel_name,
                utf8(b"data"),
                utf8(b"description"),
                utf8(b"title"),
                ts::ctx(scenario)
            );

            // let post = 

            // let (uid, _id) = post::get_id(post);

            // object::delete(uid);
        };

        ts::next_tx(scenario, ADMIN);
        {
            ts::return_shared(clock);

            channel_membership::destroy_for_testing(channel_membership_registry_val);
            channel_posts::destroy_for_testing(channel_posts_registry_val);
            channel_registry::destroy_for_testing(channel_registry_val);
            post_comments::destroy_for_testing(post_comments_registry_val);
            post_likes::destroy_for_testing(post_likes_registry_val);
        };

        ts::end(scenario_val);
    }

    // #[test]
    // #[expected_failure(abort_code = ETableNotEmpty)]
    // fun test_post_from_postl() {
    //     let (
    //         mut scenario_val,
    //         mut channel_membership_registry_val,
    //         mut channel_posts_registry_val,
    //         mut channel_registry_val,
    //         mut post_comments_registry_val,
    //         mut post_likes_registry_val
    //     ) = setup_for_testing();

    //     let scenario = &mut scenario_val;

    //     ts::next_tx(scenario, ADMIN);
    //     {
    //         let mut clock = clock::create_for_testing(ts::ctx(scenario));

    //         clock::set_for_testing(&mut clock, 0);
    //         clock::share_for_testing(clock);
    //     };

    //     ts::next_tx(scenario, ADMIN);
    //     let clock = {
    //         let clock: Clock = ts::take_shared(scenario);

    //         let post_comments_registry = &mut post_comments_registry_val;
    //         let post_likes_registry = &mut post_likes_registry_val;

    //         let post = post_actions::create(
    //             &clock,
    //             post_comments_registry,
    //             post_likes_registry,
    //             utf8(b"data"),
    //             utf8(b"description"),
    //             utf8(b"title"),
    //             ts::ctx(scenario)
    //         );

    //         let (uid, _id) = post::get_id(post);

    //         object::delete(uid);

    //         clock
    //     };

    //     ts::next_tx(scenario, ADMIN);
    //     {
    //         ts::return_shared(clock);

    //         channel_membership::destroy_for_testing(channel_membership_registry_val);
    //         channel_posts::destroy_for_testing(channel_posts_registry_val);
    //         channel_registry::destroy_for_testing(channel_registry_val);
    //         post_comments::destroy_for_testing(post_comments_registry_val);
    //         post_likes::destroy_for_testing(post_likes_registry_val);
    //     };

    //     ts::end(scenario_val);
    // }

    // #[test]
    // #[expected_failure(abort_code = ETableNotEmpty)]
    // fun test_post_like() {
    //     let (
    //         mut scenario_val,
    //         mut channel_membership_registry_val,
    //         mut channel_posts_registry_val,
    //         mut channel_registry_val,
    //         mut post_comments_registry_val,
    //         mut post_likes_registry_val
    //     ) = setup_for_testing();

    //     let scenario = &mut scenario_val;

    //     ts::next_tx(scenario, ADMIN);
    //     {
    //         let mut clock = clock::create_for_testing(ts::ctx(scenario));

    //         clock::set_for_testing(&mut clock, 0);
    //         clock::share_for_testing(clock);
    //     };

    //     ts::next_tx(scenario, ADMIN);
    //     let clock = {
    //         let clock: Clock = ts::take_shared(scenario);

    //         let post_comments_registry = &mut post_comments_registry_val;
    //         let post_likes_registry = &mut post_likes_registry_val;

    //         let post = post_actions::create(
    //             &clock,
    //             post_comments_registry,
    //             post_likes_registry,
    //             utf8(b"data"),
    //             utf8(b"description"),
    //             utf8(b"title"),
    //             ts::ctx(scenario)
    //         );

    //         let (uid, post_id) = post::get_id(post);

    //         post_actions::like(
    //             post_likes_registry,
    //             post_id,
    //             ts::ctx(scenario)
    //         );

    //         let post_likes = post_likes::get(
    //             post_likes_registry,
    //             post_id
    //         );

    //         let post_liked = post_likes::has_record(
    //             post_likes,
    //             ADMIN
    //         );

    //         assert!(post_liked, EPostNotLiked);

    //         object::delete(uid);

    //         clock
    //     };

    //     ts::next_tx(scenario, ADMIN);
    //     {
    //         ts::return_shared(clock);

    //         channel_membership::destroy_for_testing(channel_membership_registry_val);
    //         channel_posts::destroy_for_testing(channel_posts_registry_val);
    //         channel_registry::destroy_for_testing(channel_registry_val);
    //         post_comments::destroy_for_testing(post_comments_registry_val);
    //         post_likes::destroy_for_testing(post_likes_registry_val);
    //     };

    //     ts::end(scenario_val);
    // }
}
