#[test_only]
module sage_channel::test_channel_registry {
    use std::string::{utf8};

    use sui::{
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy}
    };

    use sage_admin::{admin::{Self}};

    use sage_channel::{
        channel_registry::{
            Self,
            AppChannelRegistry,
            ChannelRegistry,
            EAppChannelRegistryMismatch
        }
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;
    const APP_ADDRESS: address = @0xCAFE;
    const CHANNEL_ADDRESS: address = @0xBABE;

    // --------------- Errors ---------------

    const ERecordMismatch: u64 = 0;

    // --------------- Test Functions ---------------

    #[test_only]
    fun create_registry(
        app_channel_registry: &mut AppChannelRegistry,
        app_address: address,
        scenario: &mut Scenario
    ): ChannelRegistry {
        ts::next_tx(scenario, ADMIN);
        let channel_registry = {
            let channel_registry = channel_registry::create(
                app_address,
                ts::ctx(scenario)
            );

            let channel_registry_address = object::id_address(&channel_registry);

            channel_registry::add_registry(
                app_channel_registry,
                app_address,
                channel_registry_address
            );

            channel_registry
        };

        channel_registry
    }

    #[test_only]
    fun setup_for_testing(): (Scenario, AppChannelRegistry) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
            channel_registry::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let app_channel_registry = {
            let app_channel_registry = scenario.take_shared<AppChannelRegistry>();

            app_channel_registry
        };

        (scenario_val, app_channel_registry)
    }

    #[test]
    fun test_init() {
        let (
            mut scenario_val,
            app_channel_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy(app_channel_registry);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_create_registry() {
        let (
            mut scenario_val,
            mut app_channel_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_registry = create_registry(
                &mut app_channel_registry,
                APP_ADDRESS,
                scenario
            );

            let has_registry = channel_registry::has_channel_registry(
                &app_channel_registry,
                APP_ADDRESS
            );

            assert!(has_registry);

            let channel_registry_address = object::id_address(&channel_registry);

            let retrieved_registry_address = channel_registry::borrow_channel_registry_address(
                &app_channel_registry,
                APP_ADDRESS
            );

            assert!(channel_registry_address == retrieved_registry_address);

            destroy(app_channel_registry);
            destroy(channel_registry);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_share_registry() {
        let (
            mut scenario_val,
            mut app_channel_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_registry = create_registry(
                &mut app_channel_registry,
                APP_ADDRESS,
                scenario
            );

            channel_registry::share_registry(
                channel_registry
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let channel_registry = ts::take_shared<ChannelRegistry>(scenario);

            destroy(app_channel_registry);
            destroy(channel_registry);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_create_assert_registry_match_pass() {
        let (
            mut scenario_val,
            mut app_channel_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_registry = create_registry(
                &mut app_channel_registry,
                APP_ADDRESS,
                scenario
            );

            channel_registry::assert_app_channel_registry_match(
                &channel_registry,
                APP_ADDRESS
            );

            destroy(app_channel_registry);
            destroy(channel_registry);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EAppChannelRegistryMismatch)]
    fun test_create_assert_registry_match_fail() {
        let (
            mut scenario_val,
            mut app_channel_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_registry = create_registry(
                &mut app_channel_registry,
                APP_ADDRESS,
                scenario
            );

            channel_registry::assert_app_channel_registry_match(
                &channel_registry,
                @0x111
            );

            destroy(app_channel_registry);
            destroy(channel_registry);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_create_add() {
        let (
            mut scenario_val,
            mut app_channel_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mut channel_registry = create_registry(
                &mut app_channel_registry,
                APP_ADDRESS,
                scenario
            );

            let channel_key = utf8(b"channel-name");

            channel_registry::add(
                &mut channel_registry,
                channel_key,
                CHANNEL_ADDRESS
            );

            destroy(app_channel_registry);
            destroy(channel_registry);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_borrow() {
        let (
            mut scenario_val,
            mut app_channel_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mut channel_registry = create_registry(
                &mut app_channel_registry,
                APP_ADDRESS,
                scenario
            );

            let channel_key = utf8(b"channel-name");

            channel_registry::add(
                &mut channel_registry,
                channel_key,
                CHANNEL_ADDRESS
            );

            let retrieved_address = channel_registry::borrow_channel_address(
                &channel_registry,
                channel_key
            );

            assert!(retrieved_address == CHANNEL_ADDRESS, ERecordMismatch);

            destroy(app_channel_registry);
            destroy(channel_registry);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_has_record() {
        let (
            mut scenario_val,
            mut app_channel_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mut channel_registry = create_registry(
                &mut app_channel_registry,
                APP_ADDRESS,
                scenario
            );

            let channel_key = utf8(b"channel-name");

            channel_registry::add(
                &mut channel_registry,
                channel_key,
                CHANNEL_ADDRESS
            );

            let has_record = channel_registry::has_record(
                &channel_registry,
                channel_key
            );

            assert!(has_record, ERecordMismatch);

            let has_record = channel_registry::has_record(
                &channel_registry,
                utf8(b"random-name")
            );

            assert!(!has_record, ERecordMismatch);

            destroy(app_channel_registry);
            destroy(channel_registry);
        };

        ts::end(scenario_val);
    }
}
