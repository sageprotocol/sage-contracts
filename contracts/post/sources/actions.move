module sage_post::post_actions {
    use std::string::{String};

    use sui::{
        clock::Clock,
        coin::{Coin},
        event,
        sui::{SUI}
    };

    use sage_admin::{
        apps::{Self, App},
        authentication::{Self, AuthenticationConfig},
        fees::{Self, Royalties}
    };

    use sage_post::{
        post::{Self, Post},
        post_fees::{Self, PostFees}
    };

    use sage_shared::{
        likes::{Self},
        posts::{Self, Posts}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    // --------------- Events ---------------

    public struct CommentCreated has copy, drop {
        id: address,
        app: String,
        created_at: u64,
        created_by: address,
        data: String,
        description: String,
        parent_post_id: address,
        title: String
    }

    public struct PostLiked has copy, drop {
        id: address,
        updated_at: u64,
        user: address
    }

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun comment<CoinType, UserOwnedType: key>(
        app: &App,
        authentication_config: &AuthenticationConfig,
        clock: &Clock,
        owned_user: &UserOwnedType,
        parent_post: &mut Post,
        post_fees: &PostFees,
        data: String,
        description: String,
        title: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ): (address, address, u64) {
        authentication::assert_authentication<UserOwnedType>(
            authentication_config,
            owned_user
        );
        
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

        let app_name = apps::get_name(app);
        let parent_post_address = post::get_address(parent_post);

        event::emit(CommentCreated {
            id: post_address,
            app: app_name,
            created_at: timestamp,
            created_by: self,
            data,
            description,
            parent_post_id: parent_post_address,
            title
        });

        (post_address, self, timestamp)
    }

    public fun create<UserOwnedType: key> (
        authentication_config: &AuthenticationConfig,
        clock: &Clock,
        owned_user: &UserOwnedType,
        posts: &mut Posts,
        data: String,
        description: String,
        title: String,
        ctx: &mut TxContext
    ): (address, address, u64) {
        authentication::assert_authentication<UserOwnedType>(
            authentication_config,
            owned_user
        );

        let timestamp = clock.timestamp_ms();

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

        (post_address, self, timestamp)
    }

    public fun like<CoinType, UserOwnedType: key> (
        authentication_config: &AuthenticationConfig,
        clock: &Clock,
        owned_user: &UserOwnedType,
        post: &mut Post,
        post_fees: &PostFees,
        royalties: &Royalties,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        authentication::assert_authentication<UserOwnedType>(
            authentication_config,
            owned_user
        );

        let self = tx_context::sender(ctx);

        let (
            custom_payment,
            sui_payment
        ) = post_fees::assert_like_post_payment<CoinType>(
            post_fees,
            custom_payment,
            sui_payment
        );

        let likes = post::borrow_likes_mut(post);

        likes::add(
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

        let post_address = post::get_address(post);

        let timestamp = clock.timestamp_ms();

        event::emit(PostLiked {
            id: post_address,
            updated_at: timestamp,
            user: self
        });
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
