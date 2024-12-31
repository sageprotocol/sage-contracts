module sage_user::user_membership {
    use std::string::{String};

    use sui::{
        event,
        package::{claim_and_keep},
        table::{Self, Table}
    };

    // --------------- Constants ---------------

    const USER_MEMBER_WALLET: u8 = 0;
    // const USER_MEMBER_KIOSK: u8 = 1;

    const USER_JOIN: u8 = 10;
    const USER_LEAVE: u8 = 11;

    // --------------- Errors ---------------

    const EUserMemberExists: u64 = 370;
    const EUserMemberDoesNotExist: u64 = 371;

    // --------------- Name Tag ---------------

    public struct UserMember has store, copy, drop {
        member_type: u8
    }

    public struct UserMembership has key {
        id: UID,
        membership: Table<address, UserMember>
    }

    // user key <-> user membership object
    public struct UserMembershipRegistry has key {
        id: UID,
        registry: Table<String, address>
    }
    
    public struct USER_MEMBERSHIP has drop {}

    // --------------- Events ---------------

    public struct UserMembershipUpdate has copy, drop {
        followed_user: address,
        message: u8,
        user: address
    }

    // --------------- Constructor ---------------

    fun init(
        otw: USER_MEMBERSHIP,
        ctx: &mut TxContext
    ) {
        claim_and_keep(otw, ctx);

        let user_membership_registry = UserMembershipRegistry {
            id: object::new(ctx),
            registry: table::new(ctx)
        };

        transfer::share_object(user_membership_registry);
    }

    // --------------- Public Functions ---------------

    public fun borrow_membership_address(
        user_membership_registry: &UserMembershipRegistry,
        user_key: String
    ): address {
        user_membership_registry.registry[user_key]
    }

    public fun get_address(
        user_membership: &UserMembership
    ): address {
        user_membership.id.to_address()
    }

    public fun get_member_length(
        user_membership: &UserMembership
    ): u64 {
        user_membership.membership.length()
    }

    public fun is_member(
        user_membership: &UserMembership,
        user_address: address
    ): bool {
        user_membership.membership.contains(user_address)
    }

    // --------------- Friend Functions ---------------

    public(package) fun create(
        user_membership_registry: &mut UserMembershipRegistry,
        user_key: String,
        ctx: &mut TxContext
    ): address {
        let user_membership = UserMembership {
            id: object::new(ctx),
            membership: table::new(ctx)
        };

        let user_membership_address = user_membership.id.to_address();

        transfer::share_object(user_membership);

        user_membership_registry.registry.add(user_key, user_membership_address);

        user_membership_address
    }

    public(package) fun join(
        user_membership: &mut UserMembership,
        followed_user: address,
        self: address
    ) {
        join_user(
            user_membership,
            self
        );

        event::emit(UserMembershipUpdate {
            followed_user,
            message: USER_JOIN,
            user: self
        });
    }

    public(package) fun leave(
        user_membership: &mut UserMembership,
        followed_user: address,
        self: address
    ) {
        let is_member = is_member(
            user_membership,
            self
        );

        assert!(is_member, EUserMemberDoesNotExist);

        user_membership.membership.remove(self);

        event::emit(UserMembershipUpdate {
            followed_user,
            message: USER_LEAVE,
            user: self
        });
    }

    // --------------- Internal Functions ---------------

    fun join_user(
        user_membership: &mut UserMembership,
        user: address
    ) {
        let is_member = is_member(
            user_membership,
            user
        );

        assert!(!is_member, EUserMemberExists);

        let user_member = UserMember {
            member_type: USER_MEMBER_WALLET
        };

        user_membership.membership.add(user, user_member);
    }

    // --------------- Test Functions ---------------

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(USER_MEMBERSHIP {}, ctx);
    }
}
