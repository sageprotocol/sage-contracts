module sage_user::user_registry {
    use std::string::{String};

    use sui::{
        package::{claim_and_keep}
    };
    
    use sage_immutable::{
        immutable_table::{Self, Table}
    };

    use sage_utils::{
        string_helpers::{Self}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EAddressRecordExists: u64 = 370;
    const EUsernameRecordExists: u64 = 371;

    // --------------- Name Tag ---------------

    // address: wallet/kiosk <-> user key
    // user: user key <-> user object
    public struct UserRegistry has key, store {
        id: UID,
        address_registry: Table<address, String>,
        address_reverse_registry: Table<String, address>,
        user_registry: Table<String, address>,
        user_reverse_registry: Table<address, String>
    }

    public struct USER_REGISTRY has drop {}

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    fun init (
        otw: USER_REGISTRY,
        ctx: &mut TxContext
    ) {
        claim_and_keep(otw, ctx);

        let user_registry = UserRegistry {
            id: object::new(ctx),
            address_registry: immutable_table::new(ctx),
            address_reverse_registry: immutable_table::new(ctx),
            user_registry: immutable_table::new(ctx),
            user_reverse_registry: immutable_table::new(ctx)
        };

        transfer::share_object(user_registry);
    }

    // --------------- Public Functions ---------------

    public fun get_owner_address_from_key (
        user_registry: &UserRegistry,
        user_key: String
    ): address {
        *user_registry.address_reverse_registry.borrow(user_key)
    }

    public fun get_user_address_from_key (
        user_registry: &UserRegistry,
        user_key: String
    ): address {
        *user_registry.user_registry.borrow(user_key)
    }

    // from wallet/kiosk
    public fun get_user_key_from_owner (
        user_registry: &UserRegistry,
        address: address
    ): String {
        *user_registry.address_registry.borrow(address)
    }

    // from user object
    public fun get_user_key_from_user (
        user_registry: &UserRegistry,
        address: address
    ): String {
        *user_registry.user_reverse_registry.borrow(address)
    }

    public fun has_address_record (
        user_registry: &UserRegistry,
        address: address
    ): bool {
        user_registry.address_registry.contains(address)
    }

    public fun has_username_record (
        user_registry: &UserRegistry,
        username: String
    ): bool {
        let user_key = string_helpers::to_lowercase(
            &username
        );

        user_registry.user_registry.contains(user_key)
    }

    // --------------- Friend Functions ---------------

    public(package) fun add (
        user_registry: &mut UserRegistry,
        user_key: String,
        self_address: address,
        user_address: address
    ) {
        let address_record_exists = user_registry.has_address_record(self_address);

        assert!(!address_record_exists, EAddressRecordExists);

        let username_record_exists = user_registry.has_username_record(user_key);

        assert!(!username_record_exists, EUsernameRecordExists);

        user_registry.address_registry.add(self_address, user_key);
        user_registry.user_registry.add(user_key, user_address);

        user_registry.address_reverse_registry.add(user_key, self_address);
        user_registry.user_reverse_registry.add(user_address, user_key);
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(USER_REGISTRY {}, ctx);
    }
}
