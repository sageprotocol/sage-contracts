module sage_channel::channel_membership {
    use sui::{
        table::{Self, Table}
    };

    // --------------- Constants ---------------

    const CHANNEL_MEMBER_WALLET: u8 = 0;
    // const CHANNEL_MEMBER_KIOSK: u8 = 1;

    const CHANNEL_JOIN: u8 = 10;
    const CHANNEL_LEAVE: u8 = 11;

    // --------------- Errors ---------------

    const EChannelMemberExists: u64 = 370;
    const EUserIsNotMember: u64 = 371;

    // --------------- Name Tag ---------------

    public struct ChannelMembership has store {
        membership: Table<address, u8>
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun assert_is_member(
        channel_membership: &ChannelMembership,
        user: address
    ) {
        let is_member = is_member(
            channel_membership,
            user
        );

        assert!(is_member, EUserIsNotMember);
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

    // --------------- Friend Functions ---------------

    public(package) fun create(
        ctx: &mut TxContext
    ): (ChannelMembership, u8, u8) {
        let self = tx_context::sender(ctx);

        let mut channel_membership = ChannelMembership {
            membership: table::new(ctx)
        };

        join_channel(
            &mut channel_membership,
            self
        );

        (channel_membership, CHANNEL_JOIN, CHANNEL_MEMBER_WALLET)
    }

    public(package) fun join(
        channel_membership: &mut ChannelMembership,
        user_address: address
    ): (u8, u8) {
        join_channel(
            channel_membership,
            user_address
        );

        (CHANNEL_JOIN, CHANNEL_MEMBER_WALLET)
    }

    public(package) fun leave(
        channel_membership: &mut ChannelMembership,
        user_address: address
    ): (u8, u8) {
        channel_membership.membership.remove(user_address);

        (CHANNEL_LEAVE, CHANNEL_MEMBER_WALLET)
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

        channel_membership.membership.add(user, CHANNEL_MEMBER_WALLET);
    }

    // --------------- Test Functions ---------------
}
