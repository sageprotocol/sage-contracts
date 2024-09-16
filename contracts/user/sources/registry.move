module sage_user::user_registry {
    use std::string::{String};

    use sui::{
        package::{claim_and_keep},
        table::{Self, Table}
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

    // --------------- Name Tag ---------------

    public struct UserRegistry has key, store {
        id: UID,
        address_registry: Table<address, String>,
        user_registry: Table<String, User>
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
            address_registry: table::new(ctx),
            user_registry: table::new(ctx)
        };

        transfer::share_object(user_registry);
    }

    // --------------- Public Functions ---------------

    public fun borrow_user(
        user_registry: &UserRegistry,
        name: String
    ): User {
        *user_registry.user_registry.borrow(name)
    }

    public fun borrow_username(
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
        user_registry.user_registry.contains(username)
    }

    // --------------- Friend Functions ---------------

    public(package) fun add(
        user_registry: &mut UserRegistry,
        username: String,
        address: address,
        user: User
    ) {
        let address_record_exists = user_registry.has_address_record(address);

        assert!(!address_record_exists, EAddressRecordExists);

        let lowercase_username = string_helpers::to_lowercase(
            &username
        );

        let username_record_exists = user_registry.has_username_record(lowercase_username);

        assert!(!username_record_exists, EUsernameRecordExists);

        user_registry.address_registry.add(address, lowercase_username);
        user_registry.user_registry.add(lowercase_username, user);
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(USER_REGISTRY {}, ctx);
    }
}
