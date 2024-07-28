module sage_channel::channel {
    use std::string::{String};

    use sui::event;

    use sage_utils::{
        string_helpers::{Self}
    };

    // --------------- Constants ---------------

    const CHANNEL_NAME_MIN_LENGTH: u64 = 3;
    const CHANNEL_NAME_MAX_LENGTH: u64 = 20;

    // --------------- Errors ---------------

    const EInvalidChannelName: u64 = 370;

    // --------------- Name Tag ---------------

    public struct Channel has copy, drop, store {
        avatar_hash: String,
        banner_hash: String,
        created_at: u64,
        created_by: address,
        description: String,
        name: String
    }

    // --------------- Events ---------------

    public struct ChannelCreated has copy, drop {
        avatar_hash: String,
        banner_hash: String,
        channel_name: String,
        created_at: u64,
        created_by: address,
        description: String
    }

    public struct ChannelAvatarUpdated has copy, drop {
        channel_name: String,
        hash: String
    }

    public struct ChannelBannerUpdated has copy, drop {
        channel_name: String,
        hash: String
    }

    public struct ChannelDescriptionUpdated has copy, drop {
        channel_name: String,
        description: String
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

    public fun get_description(
        channel: Channel
    ): String {
        let Channel {
            description,
            ..
        } = channel;

        description
    }

    // --------------- Friend Functions ---------------

    public(package) fun create(
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

        let channel = Channel {
            avatar_hash,
            banner_hash,
            created_at,
            created_by,
            description,
            name: channel_name
        };

        event::emit(ChannelCreated {
            avatar_hash,
            banner_hash,
            channel_name,
            created_at,
            created_by,
            description
        });

        channel
    }

    public(package) fun update_avatar (
        channel_name: String,
        channel: &mut Channel,
        hash: String
    ) {
        channel.avatar_hash = hash;

        event::emit(ChannelAvatarUpdated {
            channel_name,
            hash
        });
    }

    public(package) fun update_banner (
        channel_name: String,
        channel: &mut Channel,
        hash: String
    ) {
        channel.banner_hash = hash;

        event::emit(ChannelBannerUpdated {
            channel_name,
            hash
        });
    }

    public(package) fun update_description (
        channel_name: String,
        channel: &mut Channel,
        description: String
    ) {
        channel.description = description;

        event::emit(ChannelDescriptionUpdated {
            channel_name,
            description
        });
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public fun create_for_testing(
        channel_name: String,
        avatar_hash: String,
        banner_hash: String,
        description: String,
        created_at: u64,
        created_by: address
    ): Channel {
        create(
            channel_name,
            avatar_hash,
            banner_hash,
            description,
            created_at,
            created_by
        )
    }
}
