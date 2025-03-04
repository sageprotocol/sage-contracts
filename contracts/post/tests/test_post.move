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

    const EAuthorMismatch: u64 = 0;
    const EPostMismatch: u64 = 1;

    // --------------- Test Functions ---------------

    #[test]
    fun test_post_create() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        let (
            post_address,
            self
        ) = {
            let timestamp: u64 = 999;

            let (post_address, self) = post::create(
                utf8(b"data"),
                utf8(b"description"),
                timestamp,
                utf8(b"title"),
                ts::ctx(scenario)
            );

            (post_address, self)
        };

        ts::next_tx(scenario, ADMIN);
        {
            assert!(self == ADMIN, EAuthorMismatch);

            let post = ts::take_shared<Post>(scenario);

            let retrieved_author = post::get_author(&post);

            assert!(retrieved_author == ADMIN, EAuthorMismatch);

            let retrieved_address = post::get_address(&post);

            assert!(post_address == retrieved_address, EPostMismatch);

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
                utf8(b"data"),
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
                utf8(b"data"),
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
