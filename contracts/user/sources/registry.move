module sage_user::user_registry {
    use std::string::{String};

    use sui::table::{Self, Table};

    use sage_admin::{
        admin::{AdminCap}
    };

    use sage_user::{
        user::{User}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EAddressRecordExists: u64 = 0;
    const EUsernameRecordExists: u64 = 1;

    // --------------- Name Tag ---------------

    public struct UserRegistry has store {
        address_registry: Table<address, String>,
        user_registry: Table<String, User>
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun create_user_registry(
        _: &AdminCap,
        ctx: &mut TxContext
    ): UserRegistry {
        UserRegistry {
            address_registry: table::new(ctx),
            user_registry: table::new(ctx)
        }
    }

    public fun get_user(
        user_registry: &mut UserRegistry,
        name: String
    ): User {
        *user_registry.user_registry.borrow(name)
    }

    public fun get_username(
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

        let username_record_exists = user_registry.has_username_record(username);

        assert!(!username_record_exists, EUsernameRecordExists);

        user_registry.address_registry.add(address, username);
        user_registry.user_registry.add(username, user);
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public fun destroy_for_testing(
        user_registry: UserRegistry
    ) {
        let UserRegistry {
            address_registry,
            user_registry
        } = user_registry;

        address_registry.drop();
        user_registry.drop();
    }
}
