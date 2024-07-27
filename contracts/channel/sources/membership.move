module sage_channel::channel_membership {
    use std::string::{String};

    use sui::event;
    use sui::{table::{Self, Table}};

    use sage_admin::{admin::{AdminCap}};
    
    use sage_channel::{channel::{Channel}};

    // --------------- Constants ---------------

    const CHANNEL_MEMBER_WALLET: u8 = 0;
    // const CHANNEL_MEMBER_KIOSK: u8 = 1;

    const CHANNEL_JOIN: u8 = 10;
    const CHANNEL_LEAVE: u8 = 11;

    // --------------- Errors ---------------

    const EChannelMemberExists: u64 = 370;
    const EChannelMemberDoesNotExist: u64 = 371;

    // --------------- Name Tag ---------------

    public struct ChannelMember has copy, store, drop {
        member_type: u8
    }

    public struct ChannelMembership has store {
        membership: Table<address, ChannelMember>
    }

    public struct ChannelMembershipRegistry has store {
        registry: Table<Channel, ChannelMembership>
    }
    

    // --------------- Events ---------------

    public struct ChannelMembershipUpdate has copy, drop {
        channel_name: String,
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

    public fun borrow_membership_mut(
        channel_membership_registry: &mut ChannelMembershipRegistry,
        channel: Channel
    ): &mut ChannelMembership {
        &mut channel_membership_registry.registry[channel]
    }

    public fun get_member_length(
        channel_membership: &ChannelMembership
    ): u64 {
        channel_membership.membership.length()
    }

    public fun is_member(
        channel_membership: &ChannelMembership,
        user: address
    ): bool {
        channel_membership.membership.contains(user)
    }

    public fun join(
        channel_membership: &mut ChannelMembership,
        channel_name: String,
        ctx: &mut TxContext
    ) {
        let user = tx_context::sender(ctx);

        join_channel(
            channel_membership,
            user
        );

        event::emit(ChannelMembershipUpdate {
            channel_name,
            message: CHANNEL_JOIN,
            user
        });
    }

    public fun leave(
        channel_membership: &mut ChannelMembership,
        channel_name: String,
        ctx: &mut TxContext
    ) {
        let user = tx_context::sender(ctx);

        let is_member = is_member(
            channel_membership,
            user
        );

        assert!(is_member, EChannelMemberDoesNotExist);

        channel_membership.membership.remove(user);

        event::emit(ChannelMembershipUpdate {
            channel_name,
            message: CHANNEL_LEAVE,
            user
        });
    }

    // --------------- Friend Functions ---------------

    public(package) fun create(
        channel_membership_registry: &mut ChannelMembershipRegistry,
        channel: Channel,
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

        channel_membership_registry.registry.add(channel, channel_membership);
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
