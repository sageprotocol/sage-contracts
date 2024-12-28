module sage_channel::channel_moderation {
    use std::string::{String};

    use sui::{
        package::{claim_and_keep},
        table::{Self, Table}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EAlreadyChannelModerator: u64 = 370;
    const EChannelModerationRecordExists: u64 = 371;
    const ENotChannelModerator: u64 = 372;

    // --------------- Name Tag ---------------

    // user addresses
    public struct ChannelModeration has key {
        id: UID,
        moderators: vector<address>
    }

    // channel key <-> channel moderation
    public struct ChannelModerationRegistry has key {
        id: UID,
        registry: Table<String, address>
    }

    public struct CHANNEL_MODERATION has drop {}

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    fun init(
        otw: CHANNEL_MODERATION,
        ctx: &mut TxContext
    ) {
        claim_and_keep(otw, ctx);

        let channel_moderation_registry = ChannelModerationRegistry {
            id: object::new(ctx),
            registry: table::new(ctx)
        };

        transfer::share_object(channel_moderation_registry);
    }

    // --------------- Public Functions ---------------

    public fun borrow_moderation_address(
        channel_moderation_registry: &ChannelModerationRegistry,
        channel_key: String
    ): address {
        *channel_moderation_registry.registry.borrow(channel_key)
    }

    public fun get_address(
        channel_moderation: &ChannelModeration
    ): address {
        channel_moderation.id.to_address()
    }

    public fun get_moderator_length(
        channel_moderation: &ChannelModeration
    ): u64 {
        channel_moderation.moderators.length()
    }

    public fun has_record(
        channel_moderation_registry: &ChannelModerationRegistry,
        channel_key: String
    ): bool {
        channel_moderation_registry.registry.contains(channel_key)
    }

    public fun is_moderator(
        channel_moderation: &ChannelModeration,
        address: address
    ): bool {
        channel_moderation.moderators.contains(&address)
    }

    // --------------- Friend Functions ---------------

    public(package) fun add(
        channel_moderation: &mut ChannelModeration,
        user_address: address
    ) {
        let is_moderator = is_moderator(
            channel_moderation,
            user_address
        );

        assert!(!is_moderator, EAlreadyChannelModerator);

        channel_moderation.moderators.push_back(
            user_address
        );
    }

    public(package) fun create(
        channel_moderation_registry: &mut ChannelModerationRegistry,
        channel_key: String,
        ctx: &mut TxContext
    ): address {
        let has_record = channel_moderation_registry.has_record(channel_key);

        assert!(!has_record, EChannelModerationRecordExists);

        let self = tx_context::sender(ctx);

        let mut channel_moderators = vector::empty<address>();
        channel_moderators.push_back(self);

        let channel_moderation = ChannelModeration {
            id: object::new(ctx),
            moderators: channel_moderators
        };

        let channel_moderation_address = channel_moderation.id.to_address();

        transfer::share_object(channel_moderation);

        channel_moderation_registry.registry.add(
            channel_key,
            channel_moderation_address
        );

        channel_moderation_address
    }

    public(package) fun remove(
        channel_moderation: &mut ChannelModeration,
        channel_moderator: address
    ) {
        let (is_moderator, index) = channel_moderation.moderators.index_of(
            &channel_moderator
        );

        assert!(is_moderator, ENotChannelModerator);

        channel_moderation.moderators.remove(index);
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(CHANNEL_MODERATION {}, ctx);
    }
}
