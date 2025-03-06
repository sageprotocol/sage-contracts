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

    const EIsNotMember: u64 = 370;

    // --------------- Name Tag ---------------

    public struct Membership has store {
        membership: Table<address, u8>
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun assert_is_member(
        membership: &Membership,
        user_address: address
    ) {
        let is_member = is_member(
            membership,
            user_address
        );

        assert!(is_member, EIsNotMember);
    }

    public fun create(
        ctx: &mut TxContext
    ): Membership {
        let membership = Membership {
            membership: table::new(ctx)
        };

        membership
    }

    public fun get_length(
        membership: &Membership
    ): u64 {
        membership.membership.length()
    }

    public fun get_type(
        membership: &Membership,
        user_address: address
    ): u8 {
        membership.membership[user_address]
    }

    public fun is_member(
        membership: &Membership,
        user_address: address
    ): bool {
        membership.membership.contains(user_address)
    }

    public fun object_join(
        membership: &mut Membership,
        obj_address: address
    ): (u8, u8) {
        membership.membership.add(obj_address, OBJECT);

        (MEMBER_ADD, OBJECT)
    }

    public fun object_leave(
        membership: &mut Membership,
        user_address: address
    ): (u8, u8) {
        membership.membership.remove(user_address);

        (MEMBER_REMOVE, OBJECT)
    }

    public fun wallet_join(
        membership: &mut Membership,
        user_address: address
    ): (u8, u8) {
        membership.membership.add(user_address, WALLET);

        (MEMBER_ADD, WALLET)
    }

    public fun wallet_leave(
        membership: &mut Membership,
        user_address: address
    ): (u8, u8) {
        membership.membership.remove(user_address);

        (MEMBER_REMOVE, WALLET)
    }

    // --------------- Friend Functions ---------------    

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
