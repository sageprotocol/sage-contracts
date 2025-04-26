module sage_post::post_actions {
    use std::string::{String};

    use sui::{
        clock::Clock,
        coin::{Coin},
        event,
        sui::{SUI}
    };

    use sage_admin::{
        access::{
            Self,
            ChannelWitnessConfig,
            GroupWitnessConfig,
            UserWitnessConfig
        },
        apps::{App},
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

    const EAppMismatch: u64 = 370;

    // --------------- Name Tag ---------------

    // --------------- Events ---------------

    public struct CommentCreated has copy, drop {
        id: address,
        app: address,
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

    public fun comment_for_user<CoinType, UserWitnessType: drop> (
        app: &App,
        clock: &Clock,
        parent_post: &mut Post,
        post_fees: &PostFees,
        user_witness: &UserWitnessType,
        user_witness_config: &UserWitnessConfig,
        data: String,
        description: String,
        title: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ): (address, address, u64) {
        access::assert_user_witness(
            user_witness_config,
            user_witness
        );

        let app_address = object::id_address(app);
        let parent_app_address = post::get_app(parent_post);

        assert!(app_address == parent_app_address, EAppMismatch);
        
        let (
            custom_payment,
            sui_payment
        ) = post_fees::assert_post_from_post_payment<CoinType>(
            post_fees,
            custom_payment,
            sui_payment
        );

        let timestamp = clock.timestamp_ms();

        let parent_depth = post::get_depth(parent_post);
        let posts = post::borrow_posts_mut(parent_post);

        let (post_address, self) = post::create(
            app_address,
            data,
            parent_depth + 1,
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
            app: app_address,
            created_at: timestamp,
            created_by: self,
            data,
            description,
            parent_post_id: parent_post_address,
            title
        });

        (post_address, self, timestamp)
    }

    public fun create_for_channel<ChannelWitnessType: drop> (
        app: &App,
        channel_witness: &ChannelWitnessType,
        channel_witness_config: &ChannelWitnessConfig,
        clock: &Clock,
        posts: &mut Posts,
        data: String,
        description: String,
        title: String,
        ctx: &mut TxContext
    ): (address, address, u64) {
        access::assert_channel_witness(
            channel_witness_config,
            channel_witness
        );

        let app_address = object::id_address(app);

        create(
            app_address,
            clock,
            posts,
            data,
            1,
            description,
            title,
            ctx
        )
    }

    public fun create_for_group<GroupWitnessType: drop> (
        app: &App,
        clock: &Clock,
        group_witness: &GroupWitnessType,
        group_witness_config: &GroupWitnessConfig,
        posts: &mut Posts,
        data: String,
        description: String,
        title: String,
        ctx: &mut TxContext
    ): (address, address, u64) {
        access::assert_group_witness(
            group_witness_config,
            group_witness
        );

        let app_address = object::id_address(app);

        create(
            app_address,
            clock,
            posts,
            data,
            1,
            description,
            title,
            ctx
        )
    }

    public fun create_for_user<UserWitnessType: drop> (
        app: &App,
        clock: &Clock,
        posts: &mut Posts,
        user_witness: &UserWitnessType,
        user_witness_config: &UserWitnessConfig,
        data: String,
        description: String,
        title: String,
        ctx: &mut TxContext
    ): (address, address, u64) {
        access::assert_user_witness(
            user_witness_config,
            user_witness
        );

        let app_address = object::id_address(app);

        create(
            app_address,
            clock,
            posts,
            data,
            1,
            description,
            title,
            ctx
        )
    }

    public fun like_for_user<CoinType, UserWitnessType: drop> (
        clock: &Clock,
        post: &mut Post,
        post_fees: &PostFees,
        royalties: &Royalties,
        user_witness: &UserWitnessType,
        user_witness_config: &UserWitnessConfig,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        access::assert_user_witness(
            user_witness_config,
            user_witness
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

    fun create (
        app: address,
        clock: &Clock,
        posts: &mut Posts,
        data: String,
        depth: u64,
        description: String,
        title: String,
        ctx: &mut TxContext
    ): (address, address, u64) {
        let timestamp = clock.timestamp_ms();

        let (post_address, self) = post::create(
            app,
            data,
            depth,
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

    // --------------- Test Functions ---------------
}
