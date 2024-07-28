#[test_only]
module sage_user::test_user_registry {
    use std::string::{utf8};

    use sui::test_scenario::{Self as ts, Scenario};

    use sage_admin::{admin::{Self, AdminCap}};

    use sage_user::{
        user::{Self},
        user_registry::{Self, UserRegistry}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    const EAddressExistsMismatch: u64 = 0;
    const EUserMismatch: u64 = 1;
    const EUsernameExistsMismatch: u64 = 2;
    const EUsernameMismatch: u64 = 3;

    // --------------- Test Functions ---------------

    #[test_only]
    fun setup_for_testing(): (Scenario, UserRegistry) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let user_registry = {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            let user_registry = user_registry::create_user_registry(
                &admin_cap,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, admin_cap);

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
            user_registry::destroy_for_testing(user_registry_val);
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

            let user = user::create(
                ADMIN,
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                created_at,
                utf8(b"description"),
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

            user_registry::destroy_for_testing(user_registry_val);
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

            let lower_name = utf8(b"all-caps");
            let upper_name = utf8(b"ALL-CAPS");

            let user = user::create(
                ADMIN,
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                created_at,
                utf8(b"description"),
                upper_name
            );

            user_registry::add(
                user_registry,
                upper_name,
                ADMIN,
                user
            );

            let retrieved_user = user_registry::borrow_user(
                user_registry,
                lower_name
            );

            assert!(retrieved_user == user, EUserMismatch);

            user_registry::destroy_for_testing(user_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_registry_get_username() {
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

            let user = user::create(
                ADMIN,
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                created_at,
                utf8(b"description"),
                name
            );

            user_registry::add(
                user_registry,
                name,
                ADMIN,
                user
            );

            let retrieved_username = user_registry::borrow_username(
                user_registry,
                ADMIN
            );

            assert!(retrieved_username == name, EUsernameMismatch);

            user_registry::destroy_for_testing(user_registry_val);
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

            let user = user::create(
                ADMIN,
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                created_at,
                utf8(b"description"),
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

            user_registry::destroy_for_testing(user_registry_val);
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

            let user = user::create(
                ADMIN,
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                created_at,
                utf8(b"description"),
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

            user_registry::destroy_for_testing(user_registry_val);
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

            let lower_name = utf8(b"all-caps");
            let upper_name = utf8(b"ALL-CAPS");

            let user = user::create(
                ADMIN,
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                created_at,
                utf8(b"description"),
                upper_name
            );

            user_registry::add(
                user_registry,
                upper_name,
                ADMIN,
                user
            );

            let has_username_record = user_registry::has_username_record(
                user_registry,
                lower_name
            );

            assert!(has_username_record, EUsernameExistsMismatch);

            user_registry::destroy_for_testing(user_registry_val);
        };

        ts::end(scenario_val);
    }
}
