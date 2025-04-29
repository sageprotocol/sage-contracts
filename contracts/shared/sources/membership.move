module sage_shared::membership {
    use sui::{
        table::{Self, Table}
    };

    // --------------- Constants ---------------

    const WALLET: u8 = 0;
    const OBJECT: u8 = 1;

    const MEMBER_ADD: u8 = 10;
    const MEMBER_REMOVE: u8 = 11;

    // --------------- Errors ---------------

    const EIsMember: u64 = 370;
    const EIsNotMember: u64 = 371;

    // --------------- Name Tag ---------------

    public struct Membership has store {
        current_followers: u64,
        membership: Table<address, Member>
    }

    public struct Member has store {
        count: u64,
        created_at: u64,
        is_following: bool,
        member_type: u8,
        updated_at: u64
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun assert_is_member(
        membership: &Membership,
        member_address: address
    ) {
        let is_member = is_member(
            membership,
            member_address
        );

        assert!(is_member, EIsNotMember);
    }

    public fun create(
        ctx: &mut TxContext
    ): Membership {
        let membership = Membership {
            current_followers: 0,
            membership: table::new(ctx)
        };

        membership
    }

    public fun get_count(
        membership: &Membership,
        member_address: address
    ): u64 {
        membership.membership[member_address].count
    }

    public fun get_created_at(
        membership: &Membership,
        member_address: address
    ): u64 {
        membership.membership[member_address].created_at
    }

    public fun get_member_length(
        membership: &Membership
    ): u64 {
        membership.current_followers
    }

    public fun get_type(
        membership: &Membership,
        member_address: address
    ): u8 {
        membership.membership[member_address].member_type
    }

    public fun get_updated_at(
        membership: &Membership,
        member_address: address
    ): u64 {
        membership.membership[member_address].updated_at
    }

    public fun is_member(
        membership: &Membership,
        member_address: address
    ): bool {
        membership.membership.contains(member_address) &&
        membership.membership[member_address].is_following
    }

    public fun object_join(
        membership: &mut Membership,
        obj_address: address,
        timestamp: u64
    ): (u8, u8, u64) {
        let count = join(
            membership,
            obj_address,
            OBJECT,
            timestamp
        );

        (MEMBER_ADD, OBJECT, count)
    }

    public fun object_leave(
        membership: &mut Membership,
        obj_address: address,
        timestamp: u64
    ): (u8, u8, u64) {
        let count = leave(
            membership,
            obj_address,
            timestamp
        );

        (MEMBER_REMOVE, OBJECT, count)
    }

    public fun wallet_join(
        membership: &mut Membership,
        user_address: address,
        timestamp: u64
    ): (u8, u8, u64) {
        let count = join(
            membership,
            user_address,
            WALLET,
            timestamp
        );

        (MEMBER_ADD, WALLET, count)
    }

    public fun wallet_leave(
        membership: &mut Membership,
        user_address: address,
        timestamp: u64
    ): (u8, u8, u64) {
        let count = leave(
            membership,
            user_address,
            timestamp
        );

        (MEMBER_REMOVE, WALLET, count)
    }

    // --------------- Friend Functions ---------------    

    // --------------- Internal Functions ---------------

    fun leave(
        membership: &mut Membership,
        member_address: address,
        timestamp: u64
    ): u64 {
        let member = membership.membership.borrow_mut(member_address);

        assert!(member.is_following, EIsNotMember);

        member.is_following = false;
        member.updated_at = timestamp;

        membership.current_followers = membership.current_followers - 1;

        member.count
    }

    fun join(
        membership: &mut Membership,
        member_address: address,
        member_type: u8,
        timestamp: u64
    ): u64 {
        let does_exist = membership.membership.contains(member_address);
        let mut member_count = 1;

        if (does_exist) {
            let member = membership.membership.borrow_mut(member_address);

            assert!(!member.is_following, EIsMember);

            member.count = member.count + 1;
            member.is_following = true;
            member.updated_at = timestamp;

            member_count = member.count
        } else {
            let member = Member {
                count: member_count,
                created_at: timestamp,
                is_following: true,
                member_type,
                updated_at: timestamp
            };

            membership.membership.add(member_address, member);
        };

        membership.current_followers = membership.current_followers + 1;

        member_count
    }

    // --------------- Test Functions ---------------
}
