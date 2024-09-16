#[test_only]
module sage_channel::test_channel_registry {
    use std::string::{utf8};

    use sui::{
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy}
    };

    use sage_admin::{admin::{Self}};

    use sage_channel::{
        channel::{Self},
        channel_registry::{Self, ChannelRegistry}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

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
    fun test_channel_registry_init() {
        let (
            mut scenario_val,
            channel_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy(channel_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_channel_registry_get_channel_lower() {
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

            let retrieved_channel = channel_registry::borrow_channel(
                channel_registry,
                channel_name
            );

            assert!(retrieved_channel == channel, EChannelMismatch);

            destroy(channel_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_channel_registry_get_channel_upper() {
        let (
            mut scenario_val,
            mut channel_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_registry = &mut channel_registry_val;

            let lower_name = utf8(b"channel-name");
            let upper_name = utf8(b"CHANNEL-NAME");

            let created_at: u64 = 999;

            let channel = channel::create(
                upper_name,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                created_at,
                ADMIN
            );

            channel_registry::add(
                channel_registry,
                upper_name,
                channel
            );

            let retrieved_channel = channel_registry::borrow_channel(
                channel_registry,
                lower_name
            );

            assert!(retrieved_channel == channel, EChannelMismatch);

            destroy(channel_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_channel_registry_get_channel_name_lower() {
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

            let channel_key = channel_registry::borrow_channel_key(
                channel_registry,
                channel
            );

            assert!(channel_key == channel_name, EChannelNameMismatch);

            destroy(channel_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_channel_registry_get_channel_name_upper() {
        let (
            mut scenario_val,
            mut channel_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_registry = &mut channel_registry_val;

            let channel_key = utf8(b"channel-name");
            let channel_name = utf8(b"CHANNEL-NAME");

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

            let retrieved_channel_key = channel_registry::borrow_channel_key(
                channel_registry,
                channel
            );

            assert!(retrieved_channel_key == channel_key, EChannelNameMismatch);

            destroy(channel_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_channel_has_record_lower() {
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

            destroy(channel_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_channel_has_record_upper() {
        let (
            mut scenario_val,
            mut channel_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_registry = &mut channel_registry_val;

            let lower_name = utf8(b"channel-name");
            let upper_name = utf8(b"CHANNEL-NAME");

            let created_at: u64 = 999;

            let channel = channel::create(
                upper_name,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                created_at,
                ADMIN
            );

            channel_registry::add(
                channel_registry,
                upper_name,
                channel
            );

            let has_record = channel_registry::has_record(
                channel_registry,
                lower_name
            );

            assert!(has_record, EChannelExistsMismatch);

            destroy(channel_registry_val);
        };

        ts::end(scenario_val);
    }
}
