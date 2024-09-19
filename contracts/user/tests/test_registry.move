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
        user_registry::{Self, UserRegistry, EUserRecordDoesNotExist}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    const EAddressExistsMismatch: u64 = 0;
    const EUserExistsMismatch: u64 = 1;
    const EUserMismatch: u64 = 2;
    const EUsernameExistsMismatch: u64 = 3;
    const EUsernameMismatch: u64 = 4;

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
            let invited_by = option::none();

            let user = user::create(
                ADMIN,
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                created_at,
                utf8(b"description"),
                invited_by,
                name,
                name
            );

            user_registry::add(
                user_registry,
                name,
                ADMIN,
                user
            );

            let retrieved_user = user_registry::borrow_user(
                user_registry,
                name
            );

            assert!(retrieved_user == user, EUserMismatch);

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
            let invited_by = option::none();

            let user = user::create(
                ADMIN,
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                created_at,
                utf8(b"description"),
                invited_by,
                user_name,
                user_key
            );

            user_registry::add(
                user_registry,
                user_key,
                ADMIN,
                user
            );

            let retrieved_user = user_registry::borrow_user(
                user_registry,
                user_key
            );

            assert!(retrieved_user == user, EUserMismatch);

            destroy(user_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_registry_get_user_key() {
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
            let invited_by = option::none();

            let user = user::create(
                ADMIN,
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                created_at,
                utf8(b"description"),
                invited_by,
                name,
                name
            );

            user_registry::add(
                user_registry,
                name,
                ADMIN,
                user
            );

            let retrieved_user_key = user_registry::borrow_user_key(
                user_registry,
                ADMIN
            );

            assert!(retrieved_user_key == name, EUsernameMismatch);

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
            let invited_by = option::none();

            let user = user::create(
                ADMIN,
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                created_at,
                utf8(b"description"),
                invited_by,
                name,
                name
            );

            user_registry::add(
                user_registry,
                name,
                ADMIN,
                user
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
            let invited_by = option::none();

            let user = user::create(
                ADMIN,
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                created_at,
                utf8(b"description"),
                invited_by,
                name,
                name
            );

            user_registry::add(
                user_registry,
                name,
                ADMIN,
                user
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
            let invited_by = option::none();

            let user_key = utf8(b"all-caps");
            let user_name = utf8(b"ALL-CAPS");

            let user = user::create(
                ADMIN,
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                created_at,
                utf8(b"description"),
                invited_by,
                user_name,
                user_key
            );

            user_registry::add(
                user_registry,
                user_key,
                ADMIN,
                user
            );

            let has_username_record = user_registry::has_username_record(
                user_registry,
                user_key
            );

            assert!(has_username_record, EUsernameExistsMismatch);

            destroy(user_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_registry_replace() {
        let (
            mut scenario_val,
            mut user_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let user_registry = &mut user_registry_val;

            let user_key = utf8(b"user-name");
            let invited_by = option::none();
            let name = utf8(b"user-name");

            let created_at: u64 = 999;

            let user = user::create(
                ADMIN,
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                created_at,
                utf8(b"description"),
                invited_by,
                name,
                name
            );

            user_registry::add(
                user_registry,
                name,
                ADMIN,
                user
            );

            let new_user_name = utf8(b"USER-NAME");

            let user = user::create(
                ADMIN,
                utf8(b"new-avatar-hash"),
                utf8(b"new-banner-hash"),
                created_at,
                utf8(b"new-description"),
                invited_by,
                new_user_name,
                user_key
            );

            user_registry::replace(
                user_registry,
                user_key,
                user
            );

            let has_record = user_registry::has_username_record(
                user_registry,
                user_key
            );

            assert!(has_record, EUserExistsMismatch);

            let user = user_registry::borrow_user(
                user_registry,
                user_key
            );

            let retrieved_name = user::get_name(user);

            assert!(new_user_name == retrieved_name, EUsernameMismatch);

            destroy(user_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EUserRecordDoesNotExist)]
    fun test_user_registry_replace_fail() {
        let (
            mut scenario_val,
            mut user_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let user_registry = &mut user_registry_val;

            let user_key = utf8(b"user-name");
            let invited_by = option::none();
            let name = utf8(b"USER-NAME");

            let created_at: u64 = 999;

            let user = user::create(
                ADMIN,
                utf8(b"new-avatar-hash"),
                utf8(b"new-banner-hash"),
                created_at,
                utf8(b"new-description"),
                invited_by,
                name,
                name
            );

            user_registry::replace(
                user_registry,
                user_key,
                user
            );

            destroy(user_registry_val);
        };

        ts::end(scenario_val);
    }
}
