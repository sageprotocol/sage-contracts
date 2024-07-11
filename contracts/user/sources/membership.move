module sage_user::user_membership {
    use sui::event;
    use sui::{table::{Self, Table}};

    use sage_admin::{admin::{AdminCap}};
    
    use sage_user::{user::{User}};

    // --------------- Constants ---------------

    const USER_MEMBER_WALLET: u8 = 0;
    // const USER_MEMBER_KIOSK: u8 = 1;

    const USER_JOIN: u8 = 10;
    const USER_LEAVE: u8 = 11;

    // --------------- Errors ---------------

    const EUserMemberExists: u64 = 0;
    const EUserMemberDoesNotExist: u64 = 1;

    // --------------- Name Tag ---------------

    public struct UserMember has copy, store, drop {
        member_type: u8
    }

    public struct UserMembership has store {
        membership: Table<address, UserMember>
    }

    public struct UserMembershipRegistry has store {
        registry: Table<User, UserMembership>
    }
    

    // --------------- Events ---------------

    public struct UserMembershipUpdate has copy, drop {
        followed_user: address,
        message: u8,
        user: address
    }

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun create_user_membership_registry(
        _: &AdminCap,
        ctx: &mut TxContext
    ): UserMembershipRegistry {
        UserMembershipRegistry {
            registry: table::new(ctx)
        }
    }

    public fun borrow_membership_mut(
        user_membership_registry: &mut UserMembershipRegistry,
        user: User
    ): &mut UserMembership {
        &mut user_membership_registry.registry[user]
    }

    public fun get_member_length(
        user_membership: &UserMembership
    ): u64 {
        user_membership.membership.length()
    }

    public fun is_member(
        user_membership: &UserMembership,
        user: address
    ): bool {
        user_membership.membership.contains(user)
    }

    public fun join(
        user_membership: &mut UserMembership,
        followed_user: address,
        ctx: &mut TxContext
    ) {
        let user = tx_context::sender(ctx);

        join_user(
            user_membership,
            user
        );

        event::emit(UserMembershipUpdate {
            followed_user,
            message: USER_JOIN,
            user
        });
    }

    public fun leave(
        user_membership: &mut UserMembership,
        followed_user: address,
        ctx: &mut TxContext
    ) {
        let user = tx_context::sender(ctx);

        let is_member = is_member(
            user_membership,
            user
        );

        assert!(is_member, EUserMemberDoesNotExist);

        user_membership.membership.remove(user);

        event::emit(UserMembershipUpdate {
            followed_user,
            message: USER_LEAVE,
            user
        });
    }

    // --------------- Friend Functions ---------------

    public(package) fun create(
        user_membership_registry: &mut UserMembershipRegistry,
        user: User,
        ctx: &mut TxContext
    ) {
        let user_membership = UserMembership {
            membership: table::new(ctx)
        };

        user_membership_registry.registry.add(user, user_membership);
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
    public fun destroy_for_testing(
        user_membership_registry: UserMembershipRegistry
    ) {
        let UserMembershipRegistry {
            registry
        } = user_membership_registry;

        registry.destroy_empty();
    }

}
