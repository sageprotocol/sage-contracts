#[test_only]
module sage_user::test_user_membership {
    use std::string::{utf8};

    use sui::{
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy}
    };

    use sage_admin::{admin::{Self}};

    use sage_user::{
        user::{Self},
        user_membership::{Self, UserMembershipRegistry, EUserMemberDoesNotExist}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;
    const OTHER: address = @0xbabe;

    // --------------- Errors ---------------

    const EUserMembershipCountMismatch: u64 = 0;
    const EUserNotMember: u64 = 1;

    // --------------- Test Functions ---------------

    #[test_only]
    public fun setup_for_testing(): (Scenario, UserMembershipRegistry) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
            user_membership::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let user_membership_registry = {
            let user_membership_registry = scenario.take_shared<UserMembershipRegistry>();

            user_membership_registry
        };

        (scenario_val, user_membership_registry)
    }

    #[test]
    fun test_user_membership_registry_init() {
        let (
            mut scenario_val,
            user_membership_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy(user_membership_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_membership_create() {
        let (
            mut scenario_val,
            mut user_membership_registry_val,
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let user_membership_registry = &mut user_membership_registry_val;

            let created_at: u64 = 999;

            let user = user::create(
                ADMIN,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                created_at,
                utf8(b"description"),
                utf8(b"user-name")
            );

            user_membership::create(
                user_membership_registry,
                user,
                ts::ctx(scenario)
            );

            let user_membership = user_membership::borrow_membership_mut(
                user_membership_registry,
                user
            );

            let user_member_count = user_membership::get_member_length(
                user_membership
            );

            assert!(user_member_count == 0, EUserMembershipCountMismatch);

            let is_member = user_membership::is_member(
                user_membership,
                ADMIN
            );

            assert!(!is_member, EUserNotMember);

            destroy(user_membership_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_join() {
        let (
            mut scenario_val,
            mut user_membership_registry_val,
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let user_membership_registry = &mut user_membership_registry_val;

        ts::next_tx(scenario, OTHER);
        let other_user = {
            let other_username = utf8(b"other-name");
            let created_at: u64 = 999;

            let other_user = user::create(
                ADMIN,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                created_at,
                utf8(b"description"),
                other_username
            );

            user_membership::create(
                user_membership_registry,
                other_user,
                ts::ctx(scenario)
            );

            other_user
        };

        ts::next_tx(scenario, ADMIN);
        {
            let username = utf8(b"user-name");
            let created_at: u64 = 999;

            let user = user::create(
                ADMIN,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                created_at,
                utf8(b"description"),
                username
            );

            user_membership::create(
                user_membership_registry,
                user,
                ts::ctx(scenario)
            );

            let user_membership = user_membership::borrow_membership_mut(
                user_membership_registry,
                other_user
            );

            user_membership::join(
                user_membership,
                ADMIN,
                ts::ctx(scenario)
            );

            let is_member = user_membership::is_member(
                user_membership,
                ADMIN
            );

            assert!(is_member, EUserNotMember);

            let member_length = user_membership::get_member_length(
                user_membership
            );

            assert!(member_length == 1, EUserMembershipCountMismatch);

            destroy(user_membership_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EUserMemberDoesNotExist)]
    fun test_user_leave() {
        let (
            mut scenario_val,
            mut user_membership_registry_val,
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let user_membership_registry = &mut user_membership_registry_val;

            let username = utf8(b"user-name");
            let created_at: u64 = 999;

            let user = user::create(
                ADMIN,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                created_at,
                utf8(b"description"),
                username
            );

            user_membership::create(
                user_membership_registry,
                user,
                ts::ctx(scenario)
            );

            let user_membership = user_membership::borrow_membership_mut(
                user_membership_registry,
                user
            );

            user_membership::leave(
                user_membership,
                ADMIN,
                ts::ctx(scenario)
            );

            let user_member_count_leave = user_membership::get_member_length(
                user_membership
            );

            assert!(user_member_count_leave == 0, EUserMembershipCountMismatch);

            user_membership::join(
                user_membership,
                ADMIN,
                ts::ctx(scenario)
            );

            let user_member_count_join = user_membership::get_member_length(
                user_membership
            );

            assert!(user_member_count_join == 1, EUserMembershipCountMismatch);

            destroy(user_membership_registry_val);
        };

        ts::end(scenario_val);
    }
}
