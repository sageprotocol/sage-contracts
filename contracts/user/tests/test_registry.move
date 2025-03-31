#[test_only]
module sage_user::test_user_registry {
    use std::string::{utf8};

    use sui::{
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy}
    };

    use sage_admin::{admin::{Self}};

    use sage_user::{
        user_registry::{
            Self,
            UserRegistry,
            EAddressRecordDoesNotExist,
            EUsernameRecordDoesNotExist
        }
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;
    const OWNED_USER: address = @0xBABE;
    const SHARED_USER: address = @0xCAFE;

    // --------------- Errors ---------------

    const EUserMismatch: u64 = 0;

    // --------------- Test Functions ---------------

    #[test_only]
    fun setup_for_testing(): (Scenario, UserRegistry) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
            user_registry::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let user_registry = {
            let user_registry = scenario.take_shared<UserRegistry>();

            user_registry
        };

        (scenario_val, user_registry)
    }

    #[test]
    fun test_user_registry_init() {
        let (
            mut scenario_val,
            user_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy(user_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_registry_add() {
        let (
            mut scenario_val,
            mut user_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let user_registry = &mut user_registry_val;

            let name = utf8(b"user-name");

            user_registry::add(
                user_registry,
                name,
                ADMIN,
                OWNED_USER,
                SHARED_USER
            );

            let owner_address = user_registry::get_owner_address_from_key(
                user_registry,
                name
            );

            assert!(owner_address == ADMIN, EUserMismatch);

            let owned_user_obj_address = user_registry::get_owned_user_address_from_key(
                user_registry,
                name
            );

            assert!(owned_user_obj_address == OWNED_USER, EUserMismatch);

            let shared_user_obj_address = user_registry::get_shared_user_address_from_key(
                user_registry,
                name
            );

            assert!(shared_user_obj_address == SHARED_USER, EUserMismatch);

            let user_key = user_registry::get_key_from_owner_address(
                user_registry,
                ADMIN
            );

            assert!(user_key == name, EUserMismatch);

            let user_key = user_registry::get_key_from_owned_user_address(
                user_registry,
                OWNED_USER
            );

            assert!(user_key == name, EUserMismatch);

            let user_key = user_registry::get_key_from_shared_user_address(
                user_registry,
                SHARED_USER
            );

            assert!(user_key == name, EUserMismatch);

            let has_address = user_registry::has_address_record(
                user_registry,
                ADMIN
            );

            assert!(has_address, EUserMismatch);

            let has_username = user_registry::has_username_record(
                user_registry,
                name
            );

            assert!(has_username, EUserMismatch);

            destroy(user_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_registry_assert_pass() {
        let (
            mut scenario_val,
            mut user_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let user_registry = &mut user_registry_val;

            let name = utf8(b"user-name");

            user_registry::add(
                user_registry,
                name,
                ADMIN,
                OWNED_USER,
                SHARED_USER
            );

            user_registry::assert_user_address_exists(
                user_registry,
                ADMIN
            );

            user_registry::assert_user_name_exists(
                user_registry,
                name
            );

            destroy(user_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EAddressRecordDoesNotExist)]
    fun test_user_registry_assert_address_fail() {
        let (
            mut scenario_val,
            user_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let user_registry = &user_registry_val;

            user_registry::assert_user_address_exists(
                user_registry,
                ADMIN
            );

            destroy(user_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EUsernameRecordDoesNotExist)]
    fun test_user_registry_assert_name_fail() {
        let (
            mut scenario_val,
            user_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let user_registry = &user_registry_val;

            user_registry::assert_user_name_exists(
                user_registry,
                utf8(b"user-name")
            );

            destroy(user_registry_val);
        };

        ts::end(scenario_val);
    }
}
