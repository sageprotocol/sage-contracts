module sage_user::user_registry {
    use std::string::{String};

    use sui::{
        package::{claim_and_keep}
    };
    
    use sage_immutable::{
        immutable_table::{Self, ImmutableTable}
    };

    use sage_user::{
        user::{User}
    };

    use sage_utils::{
        string_helpers::{Self}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EAddressRecordExists: u64 = 370;
    const EUsernameRecordExists: u64 = 371;
    const EUserRecordDoesNotExist: u64 = 372;

    // --------------- Name Tag ---------------

    public struct UserRegistry has key, store {
        id: UID,
        address_registry: ImmutableTable<address, String>,
        user_registry: ImmutableTable<String, User>
    }

    public struct USER_REGISTRY has drop {}

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    fun init(
        otw: USER_REGISTRY,
        ctx: &mut TxContext
    ) {
        claim_and_keep(otw, ctx);

        let user_registry = UserRegistry {
            id: object::new(ctx),
            address_registry: immutable_table::new(ctx),
            user_registry: immutable_table::new(ctx)
        };

        transfer::share_object(user_registry);
    }

    // --------------- Public Functions ---------------

    public fun borrow_user(
        user_registry: &UserRegistry,
        username: String
    ): User {
        let user_key = string_helpers::to_lowercase(
            &username
        );

        *user_registry.user_registry.borrow(user_key)
    }

    public fun borrow_user_key(
        user_registry: &mut UserRegistry,
        address: address
    ): String {
        *user_registry.address_registry.borrow(address)
    }

    public fun has_address_record(
        user_registry: &UserRegistry,
        address: address
    ): bool {
        user_registry.address_registry.contains(address)
    }

    public fun has_username_record(
        user_registry: &UserRegistry,
        username: String
    ): bool {
        let user_key = string_helpers::to_lowercase(
            &username
        );

        user_registry.user_registry.contains(user_key)
    }

    // --------------- Friend Functions ---------------

    public(package) fun add(
        user_registry: &mut UserRegistry,
        user_key: String,
        address: address,
        user: User
    ) {
        let address_record_exists = user_registry.has_address_record(address);

        assert!(!address_record_exists, EAddressRecordExists);

        let username_record_exists = user_registry.has_username_record(user_key);

        assert!(!username_record_exists, EUsernameRecordExists);

        user_registry.address_registry.add(address, user_key);
        user_registry.user_registry.add(user_key, user);
    }

    public(package) fun borrow_user_mut(
        user_registry: &mut UserRegistry,
        username: String
    ): &mut User {
        let user_key = string_helpers::to_lowercase(
            &username
        );

        user_registry.user_registry.borrow_mut(user_key)
    }

    public(package) fun replace(
        user_registry: &mut UserRegistry,
        user_key: String,
        user: User
    ) {
        let record_exists = user_registry.has_username_record(user_key);

        assert!(record_exists, EUserRecordDoesNotExist);

        user_registry.user_registry.replace(user_key, user);
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(USER_REGISTRY {}, ctx);
    }
}
