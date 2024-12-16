module sage_channel::channel {
    use std::string::{String};

    use sui::event;

    use sage_utils::{
        string_helpers::{Self}
    };

    // --------------- Constants ---------------

    const CHANNEL_NAME_MIN_LENGTH: u64 = 3;
    const CHANNEL_NAME_MAX_LENGTH: u64 = 20;

    const DESCRIPTION_MAX_LENGTH: u64 = 370;

    // --------------- Errors ---------------

    const EInvalidChannelDescription: u64 = 370;
    const EInvalidChannelName: u64 = 371;

    // --------------- Name Tag ---------------

    public struct Channel has copy, drop, store {
        avatar_hash: String,
        banner_hash: String,
        created_at: u64,
        created_by: address,
        description: String,
        name: String,
        updated_at: u64
    }

    // --------------- Events ---------------

    public struct ChannelCreated has copy, drop {
        avatar_hash: String,
        banner_hash: String,
        channel_key: String,
        channel_name: String,
        created_at: u64,
        created_by: address,
        description: String,
    }

    public struct ChannelUpdated has copy, drop {
        avatar_hash: String,
        banner_hash: String,
        channel_key: String,
        channel_name: String,
        description: String,
        updated_at: u64
    }

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun get_avatar(
        channel: Channel
    ): String {
        let Channel {
            avatar_hash,
            ..
        } = channel;

        avatar_hash
    }

    public fun get_banner(
        channel: Channel
    ): String {
        let Channel {
            banner_hash,
            ..
        } = channel;

        banner_hash
    }

    public fun get_created_by(
        channel: Channel
    ): address {
        let Channel {
            created_by,
            ..
        } = channel;

        created_by
    }

    public fun get_description(
        channel: Channel
    ): String {
        let Channel {
            description,
            ..
        } = channel;

        description
    }

    public fun get_name(
        channel: Channel
    ): String {
        let Channel {
            name,
            ..
        } = channel;

        name
    }

    // --------------- Friend Functions ---------------

    public(package) fun create(
        channel_key: String,
        channel_name: String,
        avatar_hash: String,
        banner_hash: String,
        description: String,
        created_at: u64,
        created_by: address
    ): Channel {
        let is_valid_name = string_helpers::is_valid_name(
            &channel_name,
            CHANNEL_NAME_MIN_LENGTH,
            CHANNEL_NAME_MAX_LENGTH
        );

        assert!(is_valid_name, EInvalidChannelName);

        let is_valid_description = is_valid_description(&description);

        assert!(is_valid_description, EInvalidChannelDescription);

        let channel = Channel {
            avatar_hash,
            banner_hash,
            created_at,
            created_by,
            description,
            name: channel_name,
            updated_at: created_at
        };

        event::emit(ChannelCreated {
            avatar_hash,
            banner_hash,
            channel_key,
            channel_name,
            created_at,
            created_by,
            description
        });

        channel
    }

    public(package) fun update (
        channel: &mut Channel,
        channel_key: String,
        channel_name: String,
        avatar_hash: String,
        banner_hash: String,
        description: String,
        updated_at: u64
    ): Channel {
        channel.avatar_hash = avatar_hash;
        channel.banner_hash = banner_hash;
        channel.description = description;
        channel.name = channel_name;
        channel.updated_at = updated_at;

        let Channel {
            banner_hash,
            description,
            name,
            ..
        } = channel;

        event::emit(ChannelUpdated {
            avatar_hash,
            banner_hash: *banner_hash,
            channel_key,
            channel_name: *name,
            description: *description,
            updated_at
        });

        *channel
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
    public fun create_for_testing(
        channel_key: String,
        channel_name: String,
        avatar_hash: String,
        banner_hash: String,
        description: String,
        created_at: u64,
        created_by: address
    ): Channel {
        create(
            channel_key,
            channel_name,
            avatar_hash,
            banner_hash,
            description,
            created_at,
            created_by
        )
    }

    #[test_only]
    public fun is_valid_description_for_testing(
        name: &String
    ): bool {
        is_valid_description(name)
    }
}
