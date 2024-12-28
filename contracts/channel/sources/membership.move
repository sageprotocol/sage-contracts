module sage_channel::channel_membership {
    use std::string::{String};

    use sui::{
        package::{claim_and_keep},
        table::{Self, Table}
    };

    // --------------- Constants ---------------

    const CHANNEL_MEMBER_WALLET: u8 = 0;
    // const CHANNEL_MEMBER_KIOSK: u8 = 1;

    // --------------- Errors ---------------

    const EChannelMemberExists: u64 = 370;
    const EChannelMemberDoesNotExist: u64 = 371;

    // --------------- Name Tag ---------------

    public struct ChannelMember has key {
        id: UID,
        member_type: u8
    }

    // user wallet address <-> channel member address
    public struct ChannelMembership has key {
        id: UID,
        membership: Table<address, address>
    }

    // channel key <-> channel membership address
    public struct ChannelMembershipRegistry has key {
        id: UID,
        registry: Table<String, address>
    }
    
    public struct CHANNEL_MEMBERSHIP has drop {}

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    fun init(
        otw: CHANNEL_MEMBERSHIP,
        ctx: &mut TxContext
    ) {
        claim_and_keep(otw, ctx);

        let channel_membership_registry = ChannelMembershipRegistry {
            id: object::new(ctx),
            registry: table::new(ctx)
        };

        transfer::share_object(channel_membership_registry);
    }

    // --------------- Public Functions ---------------

    public fun borrow_membership_address(
        channel_membership_registry: &ChannelMembershipRegistry,
        channel_key: String
    ): address {
        channel_membership_registry.registry[channel_key]
    }

    public fun get_address(
        channel_membership: &ChannelMembership
    ): address {
        channel_membership.id.to_address()
    }

    public fun get_member_length(
        channel_membership: &ChannelMembership
    ): u64 {
        channel_membership.membership.length()
    }

    public fun is_member(
        channel_membership: &ChannelMembership,
        user_address: address
    ): bool {
        channel_membership.membership.contains(user_address)
    }

    // --------------- Friend Functions ---------------

    public(package) fun create(
        channel_membership_registry: &mut ChannelMembershipRegistry,
        channel_key: String,
        ctx: &mut TxContext
    ): address {
        let mut channel_membership = ChannelMembership {
            id: object::new(ctx),
            membership: table::new(ctx)
        };

        let user_address = tx_context::sender(ctx);

        join_channel(
            &mut channel_membership,
            user_address,
            ctx
        );

        let channel_membership_address = channel_membership.id.to_address();

        channel_membership_registry.registry.add(
            channel_key,
            channel_membership.id.to_address()
        );

        transfer::share_object(channel_membership);

        channel_membership_address
    }

    public(package) fun join(
        channel_membership: &mut ChannelMembership,
        user_address: address,
        ctx: &mut TxContext
    ) {
        join_channel(
            channel_membership,
            user_address,
            ctx
        );
    }

    public(package) fun leave(
        channel_membership: &mut ChannelMembership,
        user_address: address
    ) {
        let is_member = is_member(
            channel_membership,
            user_address
        );

        assert!(is_member, EChannelMemberDoesNotExist);

        channel_membership.membership.remove(user_address);
    }

    // --------------- Internal Functions ---------------

    fun join_channel(
        channel_membership: &mut ChannelMembership,
        user_address: address,
        ctx: &mut TxContext
    ) {
        let is_member = is_member(
            channel_membership,
            user_address
        );

        assert!(!is_member, EChannelMemberExists);

        let channel_member = ChannelMember {
            id: object::new(ctx),
            member_type: CHANNEL_MEMBER_WALLET
        };

        channel_membership.membership.add(
            user_address,
            channel_member.id.to_address()
        );

        transfer::share_object(channel_member);
    }

    // --------------- Test Functions ---------------

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(CHANNEL_MEMBERSHIP {}, ctx);
    }
}
