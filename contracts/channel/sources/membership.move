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

    #[test_only]
    public fun destroy_for_testing(
        channel_membership_registry: ChannelMembershipRegistry
    ) {
        let ChannelMembershipRegistry {
            registry
        } = channel_membership_registry;

        registry.destroy_empty();
    }

    public fun join (
        self: &mut ChannelMembership,
        channel_id: ID,
        ctx: &mut TxContext
    ) {
        let user = tx_context::sender(ctx);

        let is_member = is_member(
            self,
            user
        );

        assert!(!is_member, EChannelMemberExists);

        let channel_member = ChannelMember {
            member_type: CHANNEL_MEMBER_WALLET
        };

        self.membership.add(user, channel_member);

        event::emit(ChannelMembershipUpdate {
            channel_id,
            message: CHANNEL_JOIN,
            user
        });
    }

    public fun leave (
        self: &mut ChannelMembership,
        channel_id: ID,
        ctx: &mut TxContext
    ) {
        let user = tx_context::sender(ctx);

        let is_member = is_member(
            self,
            user
        );

        assert!(is_member, EchannelMemberDoesNotExist);

        self.membership.remove(user);

        event::emit(ChannelMembershipUpdate {
            channel_id,
            message: CHANNEL_LEAVE,
            user
        });
    }

    public fun is_member(
        self: &ChannelMembership,
        user: address
    ): bool {
        self.membership.contains(user)
    }

    // --------------- Friend Functions ---------------

    public(package) fun create(
        self: &mut ChannelMembershipRegistry,
        channel_id: ID,
        ctx: &mut TxContext
    ) {
        let channel_membership = ChannelMembership {
            membership: table::new(ctx)
        };

        self.registry.add(channel_id, channel_membership);
    }

    // --------------- Internal Functions ---------------

}
