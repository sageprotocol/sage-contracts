#[test_only]
module sage_post::test_post {
    use std::string::{utf8};

    use sui::{
        test_scenario::{Self as ts},
        test_utils::{destroy}
    };

    use sage_post::{
        post::{Self, Post}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    // --------------- Test Functions ---------------

    #[test]
    fun test_post_create() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        let timestamp: u64 = 999;

        ts::next_tx(scenario, ADMIN);
        let (
            post_address,
            self
        ) = {
            let (post_address, self) = post::create(
                ADMIN,
                utf8(b"data"),
                1,
                utf8(b"description"),
                timestamp,
                utf8(b"title"),
                ts::ctx(scenario)
            );

            (post_address, self)
        };

        ts::next_tx(scenario, ADMIN);
        {
            assert!(self == ADMIN);

            let post = ts::take_shared<Post>(scenario);

            let retrieved_app = post::get_app(&post);

            assert!(retrieved_app == ADMIN);

            let retrieved_author = post::get_author(&post);

            assert!(retrieved_author == ADMIN);

            let retrieved_address = post::get_address(&post);

            assert!(post_address == retrieved_address);

            let retrieved_comments = post::get_comments_count(&post);

            assert!(retrieved_comments == 0);

            let retrieved_created_at = post::get_created_at(&post);

            assert!(retrieved_created_at == timestamp);

            let retrieved_depth = post::get_depth(&post);

            assert!(retrieved_depth == 1);

            let retrieved_likes = post::get_likes_count(&post);

            assert!(retrieved_likes == 0);

            let retrieved_updated_at = post::get_updated_at(&post);

            assert!(retrieved_updated_at == timestamp);

            destroy(post);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_post_borrow_likes() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let timestamp: u64 = 999;

            let (_post_address, _self) = post::create(
                ADMIN,
                utf8(b"data"),
                1,
                utf8(b"description"),
                timestamp,
                utf8(b"title"),
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut post = ts::take_shared<Post>(scenario);

            let _likes = post::borrow_likes_mut(&mut post);

            destroy(post);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_post_borrow_posts() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let timestamp: u64 = 999;

            let (_post_address, _self) = post::create(
                ADMIN,
                utf8(b"data"),
                1,
                utf8(b"description"),
                timestamp,
                utf8(b"title"),
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut post = ts::take_shared<Post>(scenario);

            let _posts = post::borrow_posts_mut(&mut post);

            destroy(post);
        };

        ts::end(scenario_val);
    }
}
