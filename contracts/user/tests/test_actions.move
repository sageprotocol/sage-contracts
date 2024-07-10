#[test_only]
module sage_user::test_user_actions {
    use sui::clock::{Self, Clock};

    use std::string::{utf8};

    use sui::test_scenario::{Self as ts, Scenario};

    use sage_admin::{
        admin::{Self, AdminCap}
    };

    use sage_user::{
        user_actions::{Self},
        user_registry::{Self, UserRegistry},
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    const EHasMember: u64 = 0;

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
    fun test_user_actions_init() {
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
    fun test_user_actions_create() {
        let (
            mut scenario_val,
            mut user_registry_val
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

            let name = utf8(b"user-name");    

            let _user = user_actions::create(
                &clock,
                user_registry,
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
        };

        ts::end(scenario_val);
    }
}
