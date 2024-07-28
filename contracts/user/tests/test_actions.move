#[test_only]
module sage_user::test_user_actions {
    use std::string::{utf8};

    use sui::clock::{Self, Clock};
    use sui::test_scenario::{Self as ts, Scenario};
    use sui::{table::{ETableNotEmpty}};

    use sage_admin::{
        admin::{Self, AdminCap}
    };

    use sage_user::{
        user_actions::{Self},
        user_membership::{Self, UserMembershipRegistry},
        user_registry::{Self, UserRegistry},
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;
    const OTHER: address = @0xbabe;

    // --------------- Errors ---------------

    const EHasMember: u64 = 0;
    const EUserMembershipCountMismatch: u64 = 1;
    const EUserNotMember: u64 = 2;

    // --------------- Test Functions ---------------

    #[test_only]
    fun setup_for_testing(): (Scenario, UserRegistry, UserMembershipRegistry) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let (user_registry, user_membership_registry) = {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            let user_registry = user_registry::create_user_registry(
                &admin_cap,
                ts::ctx(scenario)
            );
             let user_membership_registry = user_membership::create_user_membership_registry(
                &admin_cap,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, admin_cap);

            (user_registry, user_membership_registry)
        };

        (scenario_val, user_registry, user_membership_registry)
    }

    #[test]
    fun test_user_actions_init() {
        let (
            mut scenario_val,
            user_registry_val,
            user_membership_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            user_registry::destroy_for_testing(user_registry_val);
            user_membership::destroy_for_testing(user_membership_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ETableNotEmpty)]
    fun test_user_actions_create() {
        let (
            mut scenario_val,
            mut user_registry_val,
            mut user_membership_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let clock: Clock = ts::take_shared(scenario);

            let user_registry = &mut user_registry_val;
            let user_membership_registry = &mut user_membership_registry_val;

            let name = utf8(b"user-name");    

            let _user = user_actions::create(
                &clock,
                user_registry,
                user_membership_registry,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                name,
                ts::ctx(scenario)
            );

            let has_member = user_registry::has_address_record(
                user_registry,
                ADMIN
            );

            assert!(has_member, EHasMember);

            let has_member = user_registry::has_username_record(
                user_registry,
                name
            );

            assert!(has_member, EHasMember);

            ts::return_shared(clock);

            user_registry::destroy_for_testing(user_registry_val);
            user_membership::destroy_for_testing(user_membership_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ETableNotEmpty)]
    fun test_user_actions_join() {
        let (
            mut scenario_val,
            mut user_registry_val,
            mut user_membership_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let other_name = utf8(b"other-name");

        ts::next_tx(scenario, OTHER);
        let (other_user, user_registry, user_membership_registry) = {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            let user_registry = &mut user_registry_val;
            let user_membership_registry = &mut user_membership_registry_val;

            let other_user = user_actions::create(
                &clock,
                user_registry,
                user_membership_registry,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                other_name,
                ts::ctx(scenario)
            );

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);

            (other_user, user_registry, user_membership_registry)
        };

        ts::next_tx(scenario, ADMIN);
        {
            let clock: Clock = ts::take_shared(scenario);

            let name = utf8(b"user-name");    

            let _user = user_actions::create(
                &clock,
                user_registry,
                user_membership_registry,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                name,
                ts::ctx(scenario)
            );

            user_actions::join(
                user_registry,
                user_membership_registry,
                other_name,
                ts::ctx(scenario)
            );

            let user_membership = user_membership::borrow_membership_mut(
                user_membership_registry,
                other_user
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

            ts::return_shared(clock);

            user_registry::destroy_for_testing(user_registry_val);
            user_membership::destroy_for_testing(user_membership_registry_val);
        };

        ts::end(scenario_val);
    }
}
