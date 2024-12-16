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

    use sage_channel::{
        channel_membership::{Self, ChannelMembershipRegistry},
        channel_registry::{Self, ChannelRegistry}
    };

    use sage_post::{
        channel_posts::{Self, ChannelPostsRegistry},
        post::{Self},
        post_comments::{Self, PostCommentsRegistry},
        post_fees::{Self, PostFees},
        post_likes::{Self, PostLikesRegistry, UserPostLikesRegistry},
        post_registry::{Self, PostRegistry},
        user_posts::{Self, UserPostsRegistry}
    };

    use sage_user::{
        user_registry::{Self, UserRegistry}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EChannelDoesNotExist: u64 = 370;
    const EParentPostDoesNotExist: u64 = 371;
    const EPostDoesNotExist: u64 = 372;
    const EUserDoesNotExist: u64 = 373;
    const EUserNotChannelMember: u64 = 374;

    // --------------- Name Tag ---------------

    // --------------- Events ---------------

    public struct ChannelPostCreated has copy, drop {
        channel_key: String,
        created_at: u64,
        created_by: address,
        data: String,
        description: String,
        post_key: String,
        title: String,
        updated_at: u64
    }

    public struct CommentCreated has copy, drop {
        created_at: u64,
        created_by: address,
        data: String,
        description: String,
        parent_post_key: String,
        post_key: String,
        title: String,
        updated_at: u64
    }

    public struct UserPostCreated has copy, drop {
        created_at: u64,
        created_by: address,
        data: String,
        description: String,
        post_key: String,
        title: String,
        updated_at: u64,
        user_key: String
    }

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun like<CoinType> (
        post_registry: &PostRegistry,
        post_likes_registry: &mut PostLikesRegistry,
        user_registry: &UserRegistry,
        user_post_likes_registry: &mut UserPostLikesRegistry,
        post_fees: &PostFees,
        royalties: &Royalties,
        post_key: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let self = tx_context::sender(ctx);

        let user_exists = user_registry::has_address_record(
            user_registry,
            self
        );

        assert!(user_exists, EUserDoesNotExist);

        let has_record = post_registry::has_record(
            post_registry,
            post_key
        );

        assert!(has_record, EPostDoesNotExist);

        let (
            custom_payment,
            sui_payment
        ) = post_fees::assert_like_post_payment<CoinType>(
            post_fees,
            custom_payment,
            sui_payment
        );

        let post = post_registry::borrow_post(
            post_registry,
            post_key
        );

        let recipient = post::get_author(post);

        fees::distribute_payment<CoinType>(
            royalties,
            custom_payment,
            sui_payment,
            recipient,
            ctx
        );

        let user = tx_context::sender(ctx);

        post_likes::add(
            post_likes_registry,
            user_post_likes_registry,
            post_key,
            user
        );
    }

    public fun post_from_channel<CoinType>(
        clock: &Clock,
        channel_registry: &ChannelRegistry,
        channel_membership_registry: &mut ChannelMembershipRegistry,
        channel_posts_registry: &mut ChannelPostsRegistry,
        post_registry: &mut PostRegistry,
        user_registry: &UserRegistry,
        post_fees: &PostFees,
        channel_key: String,
        data: String,
        description: String,
        title: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ): String {
        let (
            custom_payment,
            sui_payment
        ) = post_fees::assert_post_from_channel_payment<CoinType>(
            post_fees,
            custom_payment,
            sui_payment
        );

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );

        let self = tx_context::sender(ctx);

        let user_exists = user_registry::has_address_record(
            user_registry,
            self
        );

        assert!(user_exists, EUserDoesNotExist);

        let has_record = channel_registry::has_record(
            channel_registry,
            channel_key
        );

        assert!(has_record, EChannelDoesNotExist);

        let user = tx_context::sender(ctx);

        let channel = channel_registry::borrow_channel(
            channel_registry,
            channel_key
        );

        let is_member = channel_membership::is_channel_member(
            channel_membership_registry,
            channel_key,
            user
        );

        assert!(is_member, EUserNotChannelMember);

        let timestamp = clock.timestamp_ms();

        let (post, post_key) = post::create(
            user,
            data,
            description,
            title,
            timestamp,
            ctx
        );

        post_registry::add(
            post_registry,
            post_key,
            post
        );

        channel_posts::add(
            channel_posts_registry,
            channel,
            post_key
        );

        event::emit(ChannelPostCreated {
            channel_key,
            created_at: timestamp,
            created_by: user,
            data,
            description,
            post_key,
            title,
            updated_at: timestamp
        });

        post_key
    }

    public fun post_from_post<CoinType> (
        clock: &Clock,
        post_registry: &mut PostRegistry,
        post_comments_registry: &mut PostCommentsRegistry,
        user_registry: &mut UserRegistry,
        post_fees: &PostFees,
        parent_key: String,
        data: String,
        description: String,
        title: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ): String {
        let (
            custom_payment,
            sui_payment
        ) = post_fees::assert_post_from_post_payment<CoinType>(
            post_fees,
            custom_payment,
            sui_payment
        );

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );

        let self = tx_context::sender(ctx);
        let timestamp = clock.timestamp_ms();

        let user_exists = user_registry::has_address_record(
            user_registry,
            self
        );

        assert!(user_exists, EUserDoesNotExist);

        let has_record = post_registry::has_record(
            post_registry,
            parent_key
        );

        assert!(has_record, EParentPostDoesNotExist);

        let (post, post_key) = post::create(
            self,
            data,
            description,
            title,
            timestamp,
            ctx
        );

        post_registry::add(
            post_registry,
            post_key,
            post
        );

        post_comments::add(
            post_comments_registry,
            parent_key,
            post_key
        );

        event::emit(CommentCreated {
            created_at: timestamp,
            created_by: self,
            data,
            description,
            parent_post_key: parent_key,
            post_key,
            title,
            updated_at: timestamp
        });

        post_key
    }

    public fun post_from_user<CoinType> (
        clock: &Clock,
        post_registry: &mut PostRegistry,
        user_posts_registry: &mut UserPostsRegistry,
        user_registry: &mut UserRegistry,
        post_fees: &PostFees,
        data: String,
        description: String,
        title: String,
        user_key: String,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        ctx: &mut TxContext
    ): String {
        let (
            custom_payment,
            sui_payment
        ) = post_fees::assert_post_from_user_payment<CoinType>(
            post_fees,
            custom_payment,
            sui_payment
        );

        fees::collect_payment<CoinType>(
            custom_payment,
            sui_payment
        );

        let self = tx_context::sender(ctx);

        let self_exists = user_registry::has_address_record(
            user_registry,
            self
        );

        assert!(self_exists, EUserDoesNotExist);

        let user_exists = user_registry::has_username_record(
            user_registry,
            user_key
        );

        assert!(user_exists, EUserDoesNotExist);

        let timestamp = clock.timestamp_ms();

        let (post, post_key) = post::create(
            self,
            data,
            description,
            title,
            timestamp,
            ctx
        );

        post_registry::add(
            post_registry,
            post_key,
            post
        );

        user_posts::add(
            user_posts_registry,
            user_key,
            post_key
        );

        event::emit(UserPostCreated {
            created_at: timestamp,
            created_by: self,
            data,
            description,
            post_key,
            title,
            updated_at: timestamp,
            user_key
        });

        post_key
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
