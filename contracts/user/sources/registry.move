module sage_user::user_registry {
    use std::string::{String};

    use sui::{
        package::{claim_and_keep},
        table::{Self, Table}
    };

    use sage_utils::{
        string_helpers::{Self}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EAddressRecordDoesNotExist: u64 = 370;
    const EUsernameRecordDoesNotExist: u64 = 371;

    // --------------- Name Tag ---------------

    // address: wallet/kiosk <-> user key
    // user: user key <-> user object
    public struct UserRegistry has key {
        id: UID,
        address_registry: Table<address, String>,
        address_reverse_registry: Table<String, address>,
        user_owned_registry: Table<String, address>,
        user_owned_reverse_registry: Table<address, String>,
        user_shared_registry: Table<String, address>,
        user_shared_reverse_registry: Table<address, String>
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
            address_registry: table::new(ctx),
            address_reverse_registry: table::new(ctx),
            user_owned_registry: table::new(ctx),
            user_owned_reverse_registry: table::new(ctx),
            user_shared_registry: table::new(ctx),
            user_shared_reverse_registry: table::new(ctx)
        };

        transfer::share_object(user_registry);
    }

    // --------------- Public Functions ---------------

    public fun assert_user_address_exists(
        user_registry: &UserRegistry,
        wallet_address: address
    ) {
        let is_user = has_address_record(
            user_registry,
            wallet_address
        );

        assert!(is_user, EAddressRecordDoesNotExist);
    }

    public fun assert_user_name_exists(
        user_registry: &UserRegistry,
        username: String
    ) {
        let is_user = has_username_record(
            user_registry,
            username
        );

        assert!(is_user, EUsernameRecordDoesNotExist);
    }

    public fun get_owner_address_from_key (
        user_registry: &UserRegistry,
        user_key: String
    ): address {
        *user_registry.address_reverse_registry.borrow(user_key)
    }

    public fun get_owned_user_address_from_key (
        user_registry: &UserRegistry,
        user_key: String
    ): address {
        *user_registry.user_owned_registry.borrow(user_key)
    }

    public fun get_shared_user_address_from_key (
        user_registry: &UserRegistry,
        user_key: String
    ): address {
        *user_registry.user_shared_registry.borrow(user_key)
    }

    // from wallet/kiosk
    public fun get_key_from_owner_address (
        user_registry: &UserRegistry,
        user_address: address
    ): String {
        *user_registry.address_registry.borrow(user_address)
    }

    // from owned user object
    public fun get_key_from_owned_user_address (
        user_registry: &UserRegistry,
        user_address: address
    ): String {
        *user_registry.user_owned_reverse_registry.borrow(user_address)
    }

    // from shared user object
    public fun get_key_from_shared_user_address (
        user_registry: &UserRegistry,
        user_address: address
    ): String {
        *user_registry.user_shared_reverse_registry.borrow(user_address)
    }

    public fun has_address_record (
        user_registry: &UserRegistry,
        wallet_address: address
    ): bool {
        user_registry.address_registry.contains(wallet_address)
    }

    public fun has_username_record (
        user_registry: &UserRegistry,
        username: String
    ): bool {
        let user_key = string_helpers::to_lowercase(
            &username
        );

        user_registry.user_owned_registry.contains(user_key) &&
        user_registry.user_shared_registry.contains(user_key)
    }

    // --------------- Friend Functions ---------------

    public(package) fun add (
        user_registry: &mut UserRegistry,
        user_key: String,
        self_address: address,
        owned_user_address: address,
        shared_user_address: address
    ) {
        user_registry.address_registry.add(self_address, user_key);
        user_registry.user_owned_registry.add(user_key, owned_user_address);
        user_registry.user_shared_registry.add(user_key, shared_user_address);

        user_registry.address_reverse_registry.add(user_key, self_address);
        user_registry.user_owned_reverse_registry.add(owned_user_address, user_key);
        user_registry.user_shared_reverse_registry.add(shared_user_address, user_key);
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(USER_REGISTRY {}, ctx);
    }
}
