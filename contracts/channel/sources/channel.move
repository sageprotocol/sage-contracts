module sage::channel {
    use std::string::{String};

    use sui::clock::Clock;
    use sui::event;

    use sage::{
        admin::{AdminCap},
        channel_membership::{Self, ChannelMembershipRegistry},
        channel_registry::{Self, ChannelRegistry}
    };

    // --------------- Constants ---------------

    const CHANNEL_NAME_MIN_LENGTH: u64 = 3;
    const CHANNEL_NAME_MAX_LENGTH: u64 = 20;

    // --------------- Errors ---------------

    const EInvalidChannelName: u64 = 0;

    // --------------- Name Tag ---------------

    public struct Channel has key, store {
        id: UID,
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
        channel_id: ID,
        channel_name: String,
        created_by: address,
        description: String
    }

    public struct ChannelAvatarUpdated has copy, drop {
        channel_id: ID,
        hash: String
    }

    public struct ChannelBannerUpdated has copy, drop {
        channel_id: ID,
        hash: String
    }

    public struct ChannelDescriptionUpdated has copy, drop {
        channel_id: ID,
        description: String
    }

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun create(
        clock: &Clock,
        channel_registry: &mut ChannelRegistry,
        channel_membership_registry: &mut ChannelMembershipRegistry,
        name: String,
        avatar_hash: String,
        banner_hash: String,
        description: String,
        ctx: &mut TxContext,
    ): ID {
        let is_valid_name = is_valid_channel_name(&name);

        assert!(is_valid_name, EInvalidChannelName);

        let created_by = tx_context::sender(ctx);
        let uid = object::new(ctx);

        let channel_id = object::uid_to_inner(&uid);

        channel_registry::add_record(
            channel_registry,
            name,
            channel_id
        );

        let channel = Channel {
            id: uid,
            avatar_hash,
            banner_hash,
            created_at: clock.timestamp_ms(),
            created_by,
            description,
            name,
        };

        channel_membership::create(
            channel_membership_registry,
            channel_id,
            ctx
        );
        
        transfer::share_object(channel);

        event::emit(ChannelCreated {
            avatar_hash,
            banner_hash,
            channel_id,
            channel_name: name,
            created_by,
            description
        });

        channel_id
    }

    public fun update_avatar (
        _admin_cap: &AdminCap,
        channel: &mut Channel,
        hash: String
    ): bool {
        channel.avatar_hash = hash;

        event::emit(ChannelAvatarUpdated {
            channel_id: object::uid_to_inner(&channel.id),
            hash
        });

        true
    }

    public fun update_banner (
        _admin_cap: &AdminCap,
        channel: &mut Channel,
        hash: String
    ): bool {
        channel.banner_hash = hash;

        event::emit(ChannelBannerUpdated {
            channel_id: object::uid_to_inner(&channel.id),
            hash
        });

        true
    }

    public fun update_description (
        _admin_cap: &AdminCap,
        channel: &mut Channel,
        description: String
    ): bool {
        channel.description = description;

        event::emit(ChannelDescriptionUpdated {
            channel_id: object::uid_to_inner(&channel.id),
            description
        });

        true
    }

    // --------------- Internal Functions ---------------

    fun is_valid_channel_name(name: &String): bool {
        let len = name.length();
        let name_bytes = name.bytes();
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
}
