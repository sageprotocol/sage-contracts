#[test_only]
module sage_user::test_user_registry {
    use std::string::{utf8};

    use sui::{
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy}
    };

    use sage_admin::{admin::{Self}};

    use sage_user::{
        user::{Self},
        user_registry::{
            Self,
            UserRegistry,
            EAddressRecordExists
        }
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    const EAddressExistsMismatch: u64 = 0;
    const EUserMismatch: u64 = 1;
    const EUsernameExistsMismatch: u64 = 2;

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
    fun test_user_registry_get_user_lower() {
        let (
            mut scenario_val,
            mut user_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let user_registry = &mut user_registry_val;

            let name = utf8(b"user-name");
            let created_at: u64 = 999;

            let user_address = user::create(
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                created_at,
                utf8(b"description"),
                ADMIN,
                name,
                ts::ctx(scenario)
            );

            user_registry::add(
                user_registry,
                name,
                ADMIN,
                user_address
            );

            let owner_address = user_registry::get_owner_address_from_key(
                user_registry,
                name
            );

            assert!(owner_address == ADMIN, EUserMismatch);

            let user_obj_address = user_registry::get_user_address_from_key(
                user_registry,
                name
            );

            assert!(user_obj_address == user_address, EUserMismatch);

            let user_key = user_registry::get_user_key_from_owner(
                user_registry,
                ADMIN
            );

            assert!(user_key == name, EUserMismatch);

            let user_key = user_registry::get_user_key_from_user(
                user_registry,
                user_address
            );

            assert!(user_key == name, EUserMismatch);

            destroy(user_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_registry_get_user_upper() {
        let (
            mut scenario_val,
            mut user_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let user_registry = &mut user_registry_val;

            let created_at: u64 = 999;

            let user_key = utf8(b"all-caps");
            let user_name = utf8(b"ALL-CAPS");

            let user_address = user::create(
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                created_at,
                utf8(b"description"),
                ADMIN,
                user_name,
                ts::ctx(scenario)
            );

            user_registry::add(
                user_registry,
                user_key,
                ADMIN,
                user_address
            );

            let owner_address = user_registry::get_owner_address_from_key(
                user_registry,
                user_key
            );

            assert!(owner_address == ADMIN, EUserMismatch);

            let user_obj_address = user_registry::get_user_address_from_key(
                user_registry,
                user_key
            );

            assert!(user_obj_address == user_address, EUserMismatch);

            let key = user_registry::get_user_key_from_owner(
                user_registry,
                ADMIN
            );

            assert!(key == user_key, EUserMismatch);

            let key = user_registry::get_user_key_from_user(
                user_registry,
                user_address
            );

            assert!(key == user_key, EUserMismatch);

            destroy(user_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_registry_has_address_record() {
        let (
            mut scenario_val,
            mut user_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let user_registry = &mut user_registry_val;

            let name = utf8(b"user-name");
            let created_at: u64 = 999;

            let user_address = user::create(
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                created_at,
                utf8(b"description"),
                ADMIN,
                name,
                ts::ctx(scenario)
            );

            user_registry::add(
                user_registry,
                name,
                ADMIN,
                user_address
            );

            let has_address_record = user_registry::has_address_record(
                user_registry,
                ADMIN
            );

            assert!(has_address_record, EAddressExistsMismatch);

            destroy(user_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_registry_has_username_record_lower() {
        let (
            mut scenario_val,
            mut user_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let user_registry = &mut user_registry_val;

            let name = utf8(b"user-name");
            let created_at: u64 = 999;

            let user_address = user::create(
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                created_at,
                utf8(b"description"),
                ADMIN,
                name,
                ts::ctx(scenario)
            );

            user_registry::add(
                user_registry,
                name,
                ADMIN,
                user_address
            );

            let has_username_record = user_registry::has_username_record(
                user_registry,
                name
            );

            assert!(has_username_record, EUsernameExistsMismatch);

            destroy(user_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_registry_has_username_record_upper() {
        let (
            mut scenario_val,
            mut user_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let user_registry = &mut user_registry_val;

            let created_at: u64 = 999;

            let user_key = utf8(b"all-caps");
            let user_name = utf8(b"ALL-CAPS");

            let user_address = user::create(
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                created_at,
                utf8(b"description"),
                ADMIN,
                user_name,
                ts::ctx(scenario)
            );

            user_registry::add(
                user_registry,
                user_key,
                ADMIN,
                user_address
            );

            let has_username_record = user_registry::has_username_record(
                user_registry,
                user_name
            );

            assert!(has_username_record, EUsernameExistsMismatch);

            destroy(user_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
     #[expected_failure(abort_code = EAddressRecordExists)]
    fun test_user_registry_add_record_exists() {
        let (
            mut scenario_val,
            mut user_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let user_registry = &mut user_registry_val;

            let name = utf8(b"user-name");
            let created_at: u64 = 999;

            let user_address = user::create(
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                created_at,
                utf8(b"description"),
                ADMIN,
                name,
                ts::ctx(scenario)
            );

            user_registry::add(
                user_registry,
                name,
                ADMIN,
                user_address
            );

            user_registry::add(
                user_registry,
                name,
                ADMIN,
                user_address
            );

            destroy(user_registry_val);
        };

        ts::end(scenario_val);
    }
}
