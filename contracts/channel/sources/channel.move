module sage_channel::channel {
    use std::string::{String};

    use sage_shared::{
        membership::{Membership},
        moderation::{Moderation},
        posts::{Posts}
    };

    use sage_utils::{
        string_helpers::{Self}
    };

    // --------------- Constants ---------------

    const CHANNEL_NAME_MIN_LENGTH: u64 = 3;
    const CHANNEL_NAME_MAX_LENGTH: u64 = 21;

    const DESCRIPTION_MAX_LENGTH: u64 = 370;

    // --------------- Errors ---------------

    const EInvalidChannelDescription: u64 = 370;
    const EInvalidChannelName: u64 = 371;

    // --------------- Name Tag ---------------

    public struct Channel has key {
        id: UID,
        avatar_hash: String,
        banner_hash: String,
        created_at: u64,
        created_by: address,
        description: String,
        follows: Membership,
        key: String,
        moderators: Moderation,
        name: String,
        posts: Posts,
        updated_at: u64
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

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

    public(package) fun borrow_posts_mut(
        channel: &mut Channel
    ): &mut Posts {
        &mut channel.posts
    }

    public(package) fun create(
        avatar_hash: String,
        banner_hash: String,
        description: String,
        created_at: u64,
        created_by: address,
        follows: Membership,
        key: String,
        moderators: Moderation,
        name: String,
        posts: Posts,
        ctx: &mut TxContext
    ): address {
        assert_channel_name(&name);
        assert_channel_description(&description);

        let channel = Channel {
            id: object::new(ctx),
            avatar_hash,
            banner_hash,
            created_at,
            created_by,
            description,
            follows,
            key,
            moderators,
            name,
            posts,
            updated_at: created_at
        };

        let channel_address = channel.id.to_address();

        transfer::share_object(channel);

        channel_address
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
