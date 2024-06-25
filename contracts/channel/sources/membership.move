module sage::channel_membership {
    use sui::event;
    use sui::{table::{Self, Table}};

    use sage::{
        admin::{AdminCap}
    };

    // --------------- Constants ---------------

    const CHANNEL_MEMBER_WALLET: u8 = 0;
    // const CHANNEL_MEMBER_KIOSK: u8 = 1;

    const CHANNEL_JOIN: u8 = 10;
    const CHANNEL_LEAVE: u8 = 11;

    // --------------- Errors ---------------

    const EChannelMemberExists: u64 = 0;
    const EchannelMemberDoesNotExist: u64 = 1;

    // --------------- Name Tag ---------------

    public struct ChannelMember has copy, store, drop {
        member_type: u8
    }

    public struct ChannelMembership has store {
        membership: Table<address, ChannelMember>
    }

    public struct ChannelMembershipRegistry has store {
        registry: Table<ID, ChannelMembership>
    }
    

    // --------------- Events ---------------

    public struct ChannelMembershipUpdate has copy, drop {
        channel_id: ID,
        message: u8,
        user: address
    }

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun create_channel_membership_registry(
        _: &AdminCap,
        ctx: &mut TxContext
    ): ChannelMembershipRegistry {
        ChannelMembershipRegistry {
            registry: table::new(ctx)
        }
    }

    public fun get_membership(
        channel_membership_registry: &mut ChannelMembershipRegistry,
        channel_id: ID
    ): &mut ChannelMembership {
        &mut channel_membership_registry.registry[channel_id]
    }

    public fun get_member_length(
        channel_membership: &ChannelMembership
    ): u64 {
        channel_membership.membership.length()
    }

    public fun join(
        channel_membership: &mut ChannelMembership,
        channel_id: ID,
        ctx: &mut TxContext
    ) {
        let user = tx_context::sender(ctx);

        join_channel(
            channel_membership,
            user
        );

        event::emit(ChannelMembershipUpdate {
            channel_id,
            message: CHANNEL_JOIN,
            user
        });
    }

    public fun leave(
        channel_membership: &mut ChannelMembership,
        channel_id: ID,
        ctx: &mut TxContext
    ) {
        let user = tx_context::sender(ctx);

        let is_member = is_member(
            channel_membership,
            user
        );

        assert!(is_member, EchannelMemberDoesNotExist);

        channel_membership.membership.remove(user);

        event::emit(ChannelMembershipUpdate {
            channel_id,
            message: CHANNEL_LEAVE,
            user
        });
    }

    public fun is_member(
        channel_membership: &ChannelMembership,
        user: address
    ): bool {
        channel_membership.membership.contains(user)
    }

    // --------------- Friend Functions ---------------

    public(package) fun create(
        channel_membership_registry: &mut ChannelMembershipRegistry,
        channel_id: ID,
        ctx: &mut TxContext
    ) {
        let mut channel_membership = ChannelMembership {
            membership: table::new(ctx)
        };

        let channel_membership_val = &mut channel_membership;
        let user = tx_context::sender(ctx);

        join_channel(
            channel_membership_val,
            user
        );

        channel_membership_registry.registry.add(channel_id, channel_membership);
    }

    // --------------- Internal Functions ---------------

    fun join_channel(
        channel_membership: &mut ChannelMembership,
        user: address
    ) {
        let is_member = is_member(
            channel_membership,
            user
        );

        assert!(!is_member, EChannelMemberExists);

        let channel_member = ChannelMember {
            member_type: CHANNEL_MEMBER_WALLET
        };

        channel_membership.membership.add(user, channel_member);
    }

    // --------------- Test Functions ---------------

    #[test_only]
    public fun destroy_for_testing(
        channel_membership_registry: ChannelMembershipRegistry
    ) {
        let ChannelMembershipRegistry {
            registry
        } = channel_membership_registry;

        registry.destroy_empty();
    }

}
