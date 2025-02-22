module sage_post::post_actions {
    use std::string::{String};

    use sui::{
        clock::Clock,
        coin::{Coin},
        event,
        sui::{SUI}
    };

    use sage_admin::{
        fees::{Self, Royalties}
    };

    use sage_post::{
        post::{Self, Post},
        posts::{Self, Posts},
        post_fees::{Self, PostFees},
        post_likes::{Self, Likes},
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    // --------------- Events ---------------

    public struct CommentCreated has copy, drop {
        id: address,
        created_at: u64,
        created_by: address,
        data: String,
        description: String,
        parent_post_id: address,
        title: String,
        updated_at: u64
    }

    // public struct UserPostCreated has copy, drop {
    //     created_at: u64,
    //     created_by: address,
    //     data: String,
    //     description: String,
    //     post_key: String,
    //     title: String,
    //     updated_at: u64,
    //     user_key: String
    // }

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun comment<CoinType>(
        clock: &Clock,
        parent_post: &mut Post,
        post_fees: &PostFees,
        // user_registry: &UserRegistry,
        data: String,
        description: String,
        title: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ): address {
        // user_registry::assert_user_address_exists(
        //     user_registry,
        //     self
        // );
        
        let (
            custom_payment,
            sui_payment
        ) = post_fees::assert_post_from_post_payment<CoinType>(
            post_fees,
            custom_payment,
            sui_payment
        );

        let timestamp = clock.timestamp_ms();

        let posts = post::borrow_posts_mut(parent_post);

        let (post_address, self) = post::create(
            data,
            description,
            timestamp,
            title,
            ctx
        );

        posts::add(
            posts,
            timestamp,
            post_address
        );

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );

        let parent_post_address = post::get_address(parent_post);

        event::emit(CommentCreated {
            id: post_address,
            created_at: timestamp,
            created_by: self,
            data,
            description,
            parent_post_id: parent_post_address,
            title,
            updated_at: timestamp
        });

        post_address
    }

    public fun create(
        clock: &Clock,
        posts: &mut Posts,
        data: String,
        description: String,
        title: String,
        ctx: &mut TxContext
    ): (address, u64) {
        let timestamp = clock.timestamp_ms();

        let (post_address, _self) = post::create(
            data,
            description,
            timestamp,
            title,
            ctx
        );

        posts::add(
            posts,
            timestamp,
            post_address
        );

        (post_address, timestamp)
    }

    public fun like<CoinType> (
        post: &mut Post,
        post_fees: &PostFees,
        royalties: &Royalties,
        // user_registry: &UserRegistry,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let self = tx_context::sender(ctx);

        // user_registry::assert_user_address_exists(
        //     user_registry,
        //     self
        // );

        let (
            custom_payment,
            sui_payment
        ) = post_fees::assert_like_post_payment<CoinType>(
            post_fees,
            custom_payment,
            sui_payment
        );

        let likes = post::borrow_likes_mut(post);

        post_likes::add(
            likes,
            self
        );

        let recipient = post::get_author(post);

        fees::distribute_payment<CoinType>(
            royalties,
            custom_payment,
            sui_payment,
            recipient,
            ctx
        );
    }

    // public fun post_from_user<CoinType> (
    //     clock: &Clock,
    //     posts: &mut Posts,
    //     user_posts_registry: &mut UserPostsRegistry,
    //     user_registry: &mut UserRegistry,
    //     post_fees: &PostFees,
    //     data: String,
    //     description: String,
    //     title: String,
    //     user_key: String,
    //     custom_payment: Coin<CoinType>,
    //     sui_payment: Coin<SUI>,
    //     ctx: &mut TxContext
    // ): String {
    //     let (
    //         custom_payment,
    //         sui_payment
    //     ) = post_fees::assert_post_from_user_payment<CoinType>(
    //         post_fees,
    //         custom_payment,
    //         sui_payment
    //     );

    //     fees::collect_payment<CoinType>(
    //         custom_payment,
    //         sui_payment
    //     );

    //     let self = tx_context::sender(ctx);

    //     let self_exists = user_registry::has_address_record(
    //         user_registry,
    //         self
    //     );

    //     assert!(self_exists, EUserDoesNotExist);

    //     let user_exists = user_registry::has_username_record(
    //         user_registry,
    //         user_key
    //     );

    //     assert!(user_exists, EUserDoesNotExist);

    //     let timestamp = clock.timestamp_ms();

    //     let (post, post_key) = post::create(
    //         self,
    //         data,
    //         description,
    //         title,
    //         timestamp,
    //         ctx
    //     );

    //     posts::add(
    //         posts,
    //         post_key,
    //         post
    //     );

    //     user_posts::add(
    //         user_posts_registry,
    //         user_key,
    //         post_key
    //     );

    //     event::emit(UserPostCreated {
    //         created_at: timestamp,
    //         created_by: self,
    //         data,
    //         description,
    //         post_key,
    //         title,
    //         updated_at: timestamp,
    //         user_key
    //     });

    //     post_key
    // }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
