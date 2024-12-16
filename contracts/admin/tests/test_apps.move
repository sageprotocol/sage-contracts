#[test_only]
module sage_admin::test_apps {
    use std::string::{utf8};

    use sui::{
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy}
    };

    use sage_admin::{
        admin::{
            Self,
            FeeCap,
        },
        apps::{Self, App, AppRegistry}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;
    const SHARED_OBJECT: address = @0xBABE;

    // --------------- Errors ---------------

    const EAppAddressMismatch: u64 = 0;
    const EMissingAppRecord: u64 = 1;

    // --------------- Test Functions ---------------

    #[test_only]
    fun destroy_for_testing(
        app: App,
        app_registry: AppRegistry
    ) {
        destroy(app);
        destroy(app_registry);
    }

    #[test_only]
    fun setup_for_testing(): (
        Scenario,
        App,
        AppRegistry
    ) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
            apps::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let (
            app,
            app_registry
        ) = {
            let app = apps::create_for_testing(
                utf8(b"sage"),
                ts::ctx(scenario)
            );

            let app_registry = scenario.take_shared<AppRegistry>();

            (
                app,
                app_registry
            )
        };

        (
            scenario_val,
            app,
            app_registry
        )
    }

    #[test]
    fun test_init() {
        let (
            mut scenario_val,
            app,
            app_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                app,
                app_registry_val
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun create() {
        let (
            mut scenario_val,
            app,
            mut app_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let app_registry = &mut app_registry_val;

        ts::next_tx(scenario, ADMIN);
        let (
            app_address,
            app_name
         ) = {
            let app_name = utf8(b"new-app");

            let app_address = apps::create(
                app_registry,
                app_name,
                ts::ctx(scenario)
            );

            (
                app_address,
                app_name
            )
        };

        ts::next_tx(scenario, ADMIN);
        {
            let has_record = apps::has_record(
                app_registry,
                app_name
            );

            assert!(has_record, EMissingAppRecord);

            let new_app = ts::take_shared<App>(
                scenario
            );

            let retrieved_address = apps::get_address(&new_app);

            assert!(app_address == retrieved_address, EAppAddressMismatch);

            destroy(new_app);

            destroy_for_testing(
                app,
                app_registry_val
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun add_fee_config() {
        let (
            mut scenario_val,
            mut app,
            mut app_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let app_registry = &mut app_registry_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            let app_name = utf8(b"new-app");

            let _app_address = apps::create(
                app_registry,
                app_name,
                ts::ctx(scenario)
            );

            apps::add_fee_config(
                &fee_cap,
                &mut app,
                utf8(b"shared-object"),
                SHARED_OBJECT
            );

            destroy(fee_cap);

            destroy_for_testing(
                app,
                app_registry_val
            );
        };

        ts::end(scenario_val);
    }
}
