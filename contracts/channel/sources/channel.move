module sage_channel::channel {
    use std::string::{String};

    use sui::event;

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
            banner_hash: _,
            created_at: _,
            created_by: _,
            description: _,
            name: _
        } = channel;

        avatar_hash
    }

    public fun get_banner(
        channel: Channel
    ): String {
        let Channel {
            avatar_hash: _,
            banner_hash,
            created_at: _,
            created_by: _,
            description: _,
            name: _
        } = channel;

        banner_hash
    }

    public fun get_description(
        channel: Channel
    ): String {
        let Channel {
            avatar_hash: _,
            banner_hash: _,
            created_at: _,
            created_by: _,
            description,
            name: _
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
        let is_valid_name = is_valid_channel_name(&channel_name);

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

    fun is_valid_channel_name(
        name: &String
    ): bool {
        let len = name.length();
        let name_bytes = name.as_bytes();
        let mut index = 0;

        if (!(len >= CHANNEL_NAME_MIN_LENGTH && len <= CHANNEL_NAME_MAX_LENGTH)) {
            return false
        };

        while (index < len) {
            let character = name_bytes[index];
            let is_valid_character =
                (0x61 <= character && character <= 0x7A)                   // a-z
                || (0x30 <= character && character <= 0x39)                // 0-9
                || (character == 0x2D && index != 0 && index != len - 1);  // '-' not at beginning or end

            if (!is_valid_character) {
                return false
            };

            index = index + 1;
        };

        true
    }

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

    #[test_only]
    public fun is_valid_channel_name_for_testing(
        name: &String
    ): bool {
        is_valid_channel_name(name)
    }
}
