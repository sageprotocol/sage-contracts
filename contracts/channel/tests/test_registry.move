#[test_only]
module sage_channel::test_channel_registry {
    use std::string::{utf8};

    use sui::{
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy}
    };

    use sage_admin::{admin::{Self}};

    use sage_channel::{
        channel_registry::{Self, ChannelRegistry}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;
    const CHANNEL_ADDRESS: address = @0xBABE;

    // --------------- Errors ---------------

    const ERecordMismatch: u64 = 0;

    // --------------- Test Functions ---------------

    #[test_only]
    fun setup_for_testing(): (Scenario, ChannelRegistry) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
            channel_registry::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let channel_registry = {
            let channel_registry = scenario.take_shared<ChannelRegistry>();

            channel_registry
        };

        (scenario_val, channel_registry)
    }

    #[test]
    fun test_init() {
        let (
            mut scenario_val,
            channel_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy(channel_registry);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_add() {
        let (
            mut scenario_val,
            mut channel_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_key = utf8(b"channel-name");

            channel_registry::add(
                &mut channel_registry,
                channel_key,
                CHANNEL_ADDRESS
            );

            destroy(channel_registry);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_borrow() {
        let (
            mut scenario_val,
            mut channel_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
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

            destroy(channel_registry);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_has_record() {
        let (
            mut scenario_val,
            mut channel_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
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

            destroy(channel_registry);
        };

        ts::end(scenario_val);
    }
}
