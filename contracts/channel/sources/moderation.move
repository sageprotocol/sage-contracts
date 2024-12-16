module sage_channel::channel_moderation {
    use std::string::{String};

    use sui::{
        package::{claim_and_keep},
        table::{Self, Table}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EChannelModerationRecordDoesNotExist: u64 = 370;
    const EChannelModerationRecordExists: u64 = 371;

    // --------------- Name Tag ---------------

    public struct ChannelModerationRegistry has key, store {
        id: UID,
        registry: Table<String, vector<address>>
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

    public fun borrow_moderators(
        channel_moderation_registry: &ChannelModerationRegistry,
        channel_key: String
    ): vector<address> {
        let has_record = has_record(
            channel_moderation_registry,
            channel_key
        );

        assert!(has_record, EChannelModerationRecordDoesNotExist);

        *channel_moderation_registry.registry.borrow(channel_key)
    }

    public fun get_moderator_length(
        channel_moderation_registry: &ChannelModerationRegistry,
        channel_key: String
    ): u64 {
        let channel_moderators = borrow_moderators(
            channel_moderation_registry,
            channel_key
        );

        channel_moderators.length()
    }

    public fun has_record(
        channel_moderation_registry: &ChannelModerationRegistry,
        channel_key: String
    ): bool {
        channel_moderation_registry.registry.contains(channel_key)
    }

    public fun is_moderator(
        channel_moderation_registry: &ChannelModerationRegistry,
        channel_key: String,
        address: address
    ): bool {
        let channel_moderators = borrow_moderators(
            channel_moderation_registry,
            channel_key
        );

        channel_moderators.contains(&address)
    }

    // --------------- Friend Functions ---------------

    public(package) fun borrow_moderators_mut(
        channel_moderation_registry: &mut ChannelModerationRegistry,
        channel_key: String
    ): &mut vector<address> {
        let has_record = has_record(
            channel_moderation_registry,
            channel_key
        );

        assert!(has_record, EChannelModerationRecordDoesNotExist);

        &mut channel_moderation_registry.registry[channel_key]
    }

    public(package) fun create(
        channel_moderation_registry: &mut ChannelModerationRegistry,
        channel_key: String,
        ctx: &TxContext
    ) {
        let has_record = channel_moderation_registry.has_record(channel_key);

        assert!(!has_record, EChannelModerationRecordExists);

        let self = tx_context::sender(ctx);

        let mut channel_moderators = vector::empty<address>();
        channel_moderators.push_back(self);

        channel_moderation_registry.registry.add(channel_key, channel_moderators);
    }

    public(package) fun replace(
        channel_moderation_registry: &mut ChannelModerationRegistry,
        channel_key: String,
        channel_moderators: vector<address>
    ) {
        let has_record = channel_moderation_registry.has_record(channel_key);

        assert!(has_record, EChannelModerationRecordDoesNotExist);

        channel_moderation_registry.registry.remove(channel_key);
        channel_moderation_registry.registry.add(channel_key, channel_moderators);
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(CHANNEL_MODERATION {}, ctx);
    }
}
