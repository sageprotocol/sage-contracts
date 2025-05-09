module sage_channel::channel {
    use sui::{
        dynamic_field::{Self as df},
        dynamic_object_field::{Self as dof}
    };

    use std::string::{String};

    use sage_admin::{
        access::{ChannelWitnessConfig}
    };

    use sage_analytics::{
        analytics::{Analytics},
        analytics_actions::{Self}
    };

    use sage_channel::{
        channel_witness::{Self}
    };

    use sage_shared::{
        membership::{Membership},
        moderation::{Moderation},
        posts::{Self, Posts}
    };

    use sage_utils::{
        string_helpers::{Self}
    };

    // --------------- Constants ---------------

    const CHANNEL_NAME_MIN_LENGTH: u64 = 3;
    const CHANNEL_NAME_MAX_LENGTH: u64 = 21;

    const DESCRIPTION_MAX_LENGTH: u64 = 370;

    // --------------- Errors ---------------

    const EAppChannelMismatch: u64 = 370;
    const EInvalidChannelDescription: u64 = 371;
    const EInvalidChannelName: u64 = 372;

    // --------------- Name Tag ---------------

    public struct AnalyticsKey has copy, drop, store {
        app: address,
        epoch: u64
    }

    public struct Channel has key {
        id: UID,
        app: address,
        avatar_hash: String,
        banner_hash: String,
        created_at: u64,
        created_by: address,
        description: String,
        follows: Membership,
        key: String,
        moderators: Moderation,
        name: String,
        updated_at: u64
    }

    public struct PostsKey has copy, drop, store {
        app: address
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun assert_app_channel_match(
        channel: &Channel,
        app_address: address
    ) {
        assert!(channel.app == app_address, EAppChannelMismatch);
    }

    public fun assert_channel_description(
        description: &String
    ) {
        let is_valid_description = is_valid_description(description);

        assert!(is_valid_description, EInvalidChannelDescription);
    }

    public fun assert_channel_name(
        name: &String
    ) {
        let is_valid_name = string_helpers::is_valid_name(
            name,
            CHANNEL_NAME_MIN_LENGTH,
            CHANNEL_NAME_MAX_LENGTH
        );

        assert!(is_valid_name, EInvalidChannelName);
    }

    public fun get_avatar(
        channel: &Channel
    ): String {
        channel.avatar_hash
    }

    public fun get_banner(
        channel: &Channel
    ): String {
        channel.banner_hash
    }

    public fun get_created_by(
        channel: &Channel
    ): address {
        channel.created_by
    }

    public fun get_description(
        channel: &Channel
    ): String {
        channel.description
    }

    public fun get_key(
        channel: &Channel
    ): String {
        channel.key
    }

    public fun get_name(
        channel: &Channel
    ): String {
        channel.name
    }

    // --------------- Friend Functions ---------------

    public(package) fun borrow_analytics_mut(
        channel: &mut Channel,
        channel_witness_config: &ChannelWitnessConfig,
        app_address: address,
        epoch: u64,
        ctx: &mut TxContext
    ): &mut Analytics {
        let analytics_key = AnalyticsKey {
            app: app_address,
            epoch
        };

        let does_exist = dof::exists_with_type<AnalyticsKey, Analytics>(
            &channel.id,
            analytics_key
        );

        if (!does_exist) {
            let channel_witness = channel_witness::create_witness();

            let analytics = analytics_actions::create_analytics_for_channel(
                &channel_witness,
                channel_witness_config,
                ctx
            );

            dof::add(
                &mut channel.id,
                analytics_key,
                analytics
            );
        };

        dof::borrow_mut<AnalyticsKey, Analytics>(
            &mut channel.id,
            analytics_key
        )
    }

    public(package) fun borrow_follows_mut(
        channel: &mut Channel
    ): &mut Membership {
        &mut channel.follows
    }

    public(package) fun borrow_moderators_mut(
        channel: &mut Channel
    ): &mut Moderation {
        &mut channel.moderators
    }

    public(package) fun create(
        app_address: address,
        avatar_hash: String,
        banner_hash: String,
        description: String,
        created_at: u64,
        created_by: address,
        follows: Membership,
        key: String,
        moderators: Moderation,
        name: String,
        ctx: &mut TxContext
    ): address {
        assert_channel_name(&name);
        assert_channel_description(&description);

        let channel = Channel {
            id: object::new(ctx),
            app: app_address,
            avatar_hash,
            banner_hash,
            created_at,
            created_by,
            description,
            follows,
            key,
            moderators,
            name,
            updated_at: created_at
        };

        let channel_address = channel.id.to_address();

        transfer::share_object(channel);

        channel_address
    }

    public(package) fun return_posts(
        channel: &mut Channel,
        app_address: address,
        posts: Posts
    ) {
        let posts_key = PostsKey {
            app: app_address
        };

        df::add(
            &mut channel.id,
            posts_key,
            posts
        );
    }

    public(package) fun take_posts(
        channel: &mut Channel,
        app_address: address,
        ctx: &mut TxContext
    ): Posts {
        let posts_key = PostsKey {
            app: app_address
        };

        let does_exist = df::exists_with_type<PostsKey, Posts>(
            &channel.id,
            posts_key
        );

        if (does_exist) {
            df::remove(
                &mut channel.id,
                posts_key
            )
        } else {
            posts::create(ctx)
        }
    }

    public(package) fun update(
        channel: &mut Channel,
        avatar_hash: String,
        banner_hash: String,
        description: String,
        name: String,
        updated_at: u64
    ) {
        assert_channel_description(&description);

        channel.avatar_hash = avatar_hash;
        channel.banner_hash = banner_hash;
        channel.description = description;
        channel.name = name;
        channel.updated_at = updated_at;
    }

    // --------------- Internal Functions ---------------

    fun is_valid_description(
        description: &String
    ): bool {
        let len = description.length();

        if (len > DESCRIPTION_MAX_LENGTH) {
            return false
        };

        true
    }

    // --------------- Test Functions ---------------

    #[test_only]
    public fun is_valid_description_for_testing(
        name: &String
    ): bool {
        is_valid_description(name)
    }
}
