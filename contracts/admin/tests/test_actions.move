#[test_only]
module sage_admin::test_actions {
    use std::{
        string::{utf8}
    };

    use sui::{
        sui::{SUI},
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy}
    };

    use sage_admin::{
        access::{
            Self,
            UserOwnedConfig,
            ValidType
        },
        admin::{
            Self,
            AdminCap,
            FeeCap
        },
        admin_actions::{Self},
        apps::{Self, AppRegistry},
        fees::{Royalties}
    };

    #[test_only]
    public struct FAKE_FEE_COIN has drop {}

    // --------------- Constants ---------------

    const ADMIN: address = @admin;
    const TREASURY: address = @treasury;

    // --------------- Errors ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    fun setup_for_testing(): (
        Scenario,
        AppRegistry
    ) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
            apps::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let app_registry= {
            scenario.take_shared<AppRegistry>()
        };

        (
            scenario_val,
            app_registry
        )
    }

    #[test]
    fun test_init() {
        let (
            mut scenario_val,
            app_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy(app_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun create_app() {
        let (
            mut scenario_val,
            mut app_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            access::create_owned_user_config<ValidType>(
                &admin_cap,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, admin_cap);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let owned_user_config = scenario.take_shared<UserOwnedConfig>();
            let valid_type = access::create_valid_type_for_testing(ts::ctx(scenario));

            let _app_address = admin_actions::create_app<ValidType>(
                &mut app_registry,
                utf8(b"sage"),
                &valid_type,
                &owned_user_config,
                ts::ctx(scenario)
            );
            
            ts::return_shared(owned_user_config);

            destroy(app_registry);
            destroy(valid_type);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun create_app_as_admin() {
        let (
            mut scenario_val,
            mut app_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            let _app_address = admin_actions::create_app_as_admin(
                &admin_cap,
                &mut app_registry,
                utf8(b"sage"),
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, admin_cap);

            destroy(app_registry);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun create_royalties() {
        let (
            mut scenario_val,
            app_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mut app = apps::create_for_testing(
                utf8(b"sage"),
                ts::ctx(scenario)
            );

            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            admin_actions::create_royalties<SUI>(
                &fee_cap,
                &mut app,
                1,
                TREASURY,
                1,
                TREASURY,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, fee_cap);

            destroy(app);
            destroy(app_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun update_royalties() {
        let (
            mut scenario_val,
            app_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let fee_cap = ts::take_from_sender<FeeCap>(scenario);

        ts::next_tx(scenario, ADMIN);
        {
            let mut app = apps::create_for_testing(
                utf8(b"sage"),
                ts::ctx(scenario)
            );

            admin_actions::create_royalties<SUI>(
                &fee_cap,
                &mut app,
                1,
                TREASURY,
                1,
                TREASURY,
                ts::ctx(scenario)
            );

            destroy(app);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut royalties = ts::take_shared<Royalties>(scenario);

            admin_actions::update_royalties<SUI>(
                &fee_cap,
                &mut royalties,
                2,
                ADMIN,
                2,
                ADMIN
            );

            ts::return_shared(royalties);

            ts::return_to_sender(scenario, fee_cap);

            destroy(app_registry_val);
        };

        ts::end(scenario_val);
    }
}
