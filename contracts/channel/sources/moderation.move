module sage_channel::channel_moderation {
    use sui::{
        table::{Self, Table}
    };

    // --------------- Constants ---------------

    const CHANNEL_OWNER: u8 = 0;
    const CHANNEL_MODERATOR: u8 = 1;

    const MODERATOR_ADD: u8 = 10;
    const MODERATOR_REMOVE: u8 = 11;

    // --------------- Errors ---------------

    const EChannelModerationRecordDoesNotExist: u64 = 370;
    const EIsOwner: u64 = 371;
    const EIsNotModerator: u64 = 372;
    const EIsNotOwner: u64 = 373;

    // --------------- Name Tag ---------------

    public struct ChannelModeration has store {
        moderation: Table<address, u8>
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun assert_is_moderator(
        channel_moderation: &ChannelModeration,
        user: address
    ) {
        let is_moderator = is_moderator(
            channel_moderation,
            user
        );

        assert!(is_moderator, EIsNotModerator);
    }

    public fun assert_is_owner(
        channel_moderation: &ChannelModeration,
        user: address
    ) {
        let is_owner = is_owner(
            channel_moderation,
            user
        );

        assert!(is_owner, EIsNotOwner);
    }

    public fun get_moderator_length(
        channel_moderation: &ChannelModeration
    ): u64 {
        channel_moderation.moderation.length()
    }

    public fun is_moderator(
        channel_moderation: &ChannelModeration,
        user: address
    ): bool {
        channel_moderation.moderation.contains(user)
    }

    public fun is_owner(
        channel_moderation: &ChannelModeration,
        user: address
    ): bool {
        let does_exist = channel_moderation.moderation.contains(user);

        if (!does_exist) {
            false
        } else {
            channel_moderation.moderation[user] == CHANNEL_OWNER
        }
    }

    // --------------- Friend Functions ---------------

    public(package) fun create(
        ctx: &mut TxContext
    ): (ChannelModeration, u8, u8) {
        let self = tx_context::sender(ctx);

        let mut channel_moderation = ChannelModeration {
            moderation: table::new(ctx)
        };

        make_owner(
            &mut channel_moderation,
            self
        );

        (channel_moderation, MODERATOR_ADD, CHANNEL_OWNER)
    }

    public(package) fun make_moderator(
        channel_moderation: &mut ChannelModeration,
        user: address
    ): (u8, u8) {
        channel_moderation.moderation.add(
            user,
            CHANNEL_MODERATOR
        );

        (MODERATOR_ADD, CHANNEL_MODERATOR)
    }

    public(package) fun make_owner(
        channel_moderation: &mut ChannelModeration,
        user: address
    ): (u8, u8) {
        channel_moderation.moderation.add(
            user,
            CHANNEL_OWNER
        );

        (MODERATOR_ADD, CHANNEL_OWNER)
    }

    public(package) fun remove_moderator(
        channel_moderation: &mut ChannelModeration,
        user: address
    ): (u8, u8) {
        let is_owner = is_owner(
            channel_moderation,
            user
        );

        assert!(!is_owner, EIsOwner);

        channel_moderation.moderation.remove(user);

        (MODERATOR_REMOVE, CHANNEL_MODERATOR)
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
