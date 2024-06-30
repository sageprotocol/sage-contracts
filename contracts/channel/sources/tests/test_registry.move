#[test_only]
module sage::test_channel_registry {
    use std::string::{utf8};

    use sui::test_scenario::{Self as ts, Scenario};

    use sage::{
        admin::{Self, AdminCap},
        channel::{Self},
        channel_registry::{Self, ChannelRegistry}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @0xde1;

    // --------------- Errors ---------------

    const EChannelMismatch: u64 = 0;
    const EChannelNameMismatch: u64 = 1;
    const EChannelExistsMismatch: u64 = 2;

    // --------------- Test Functions ---------------

    #[test_only]
    fun setup_for_testing(): (Scenario, ChannelRegistry) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let channel_registry = {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            let channel_registry = channel_registry::create_channel_registry(
                &admin_cap,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, admin_cap);

            channel_registry
        };

        (scenario_val, channel_registry)
    }

    #[test]
    fun test_channel_registry_init() {
        let (
            mut scenario_val,
            channel_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            channel_registry::destroy_for_testing(channel_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_channel_registry_get_channel() {
        let (
            mut scenario_val,
            mut channel_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_registry = &mut channel_registry_val;

            let channel_name = utf8(b"channel-name");
            let created_at: u64 = 999;

            let channel = channel::create(
                channel_name,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                created_at,
                ADMIN
            );

            channel_registry::add(
                channel_registry,
                channel_name,
                channel
            );

            let retrieved_channel = channel_registry::get_channel(
                channel_registry,
                channel_name
            );

            assert!(retrieved_channel == channel, EChannelMismatch);

            channel_registry::destroy_for_testing(channel_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_channel_registry_get_channel_name() {
        let (
            mut scenario_val,
            mut channel_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_registry = &mut channel_registry_val;

            let channel_name = utf8(b"channel-name");
            let created_at: u64 = 999;

            let channel = channel::create(
                channel_name,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                created_at,
                ADMIN
            );

            channel_registry::add(
                channel_registry,
                channel_name,
                channel
            );

            let retrieved_channel_name = channel_registry::get_channel_name(
                channel_registry,
                channel
            );

            assert!(retrieved_channel_name == channel_name, EChannelNameMismatch);

            channel_registry::destroy_for_testing(channel_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_channel_has_record() {
        let (
            mut scenario_val,
            mut channel_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_registry = &mut channel_registry_val;

            let channel_name = utf8(b"channel-name");
            let created_at: u64 = 999;

            let channel = channel::create(
                channel_name,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                created_at,
                ADMIN
            );

            channel_registry::add(
                channel_registry,
                channel_name,
                channel
            );

            let has_record = channel_registry::has_record(
                channel_registry,
                channel_name
            );

            assert!(has_record, EChannelExistsMismatch);

            channel_registry::destroy_for_testing(channel_registry_val);
        };

        ts::end(scenario_val);
    }
}
