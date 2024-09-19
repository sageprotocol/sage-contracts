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
        channel_registry::{Self, ChannelRegistry, EChannelRecordDoesNotExist}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    const EChannelMismatch: u64 = 0;
    const EChannelExistsMismatch: u64 = 1;
    const EChannelNameMismatch: u64 = 2;

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

            let channel_key = utf8(b"channel-name");
            let channel_name = utf8(b"CHANNEL-NAME");

            let created_at: u64 = 999;

            let channel = channel::create(
                channel_key,
                channel_name,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                created_at,
                ADMIN
            );

            channel_registry::add(
                channel_registry,
                channel_key,
                channel
            );

            let retrieved_channel = channel_registry::borrow_channel(
                channel_registry,
                channel_key
            );

            assert!(retrieved_channel == channel, EChannelMismatch);

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

            let channel_key = utf8(b"channel-name");
            let channel_name = utf8(b"CHANNEL-NAME");

            let created_at: u64 = 999;

            let channel = channel::create(
                channel_key,
                channel_name,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                created_at,
                ADMIN
            );

            channel_registry::add(
                channel_registry,
                channel_key,
                channel
            );

            let has_record = channel_registry::has_record(
                channel_registry,
                channel_key
            );

            assert!(has_record, EChannelExistsMismatch);

            destroy(channel_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_channel_replace() {
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
                channel_key,
                channel_name,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                created_at,
                ADMIN
            );

            channel_registry::add(
                channel_registry,
                channel_key,
                channel
            );

            let new_channel_name = utf8(b"NEW-CHANNEL");

            let channel = channel::create(
                channel_key,
                new_channel_name,
                utf8(b"new_avatar_hash"),
                utf8(b"new_banner_hash"),
                utf8(b"new_description"),
                created_at,
                ADMIN
            );

            channel_registry::replace(
                channel_registry,
                channel_key,
                channel
            );

            let has_record = channel_registry::has_record(
                channel_registry,
                channel_key
            );

            assert!(has_record, EChannelExistsMismatch);

            let channel = channel_registry::borrow_channel(
                channel_registry,
                channel_key
            );

            let retrieved_name = channel::get_name(channel);

            assert!(new_channel_name == retrieved_name, EChannelNameMismatch);

            destroy(channel_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EChannelRecordDoesNotExist)]
    fun test_channel_replace_fail() {
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
                channel_key,
                channel_name,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                created_at,
                ADMIN
            );

            channel_registry::replace(
                channel_registry,
                channel_key,
                channel
            );

            destroy(channel_registry_val);
        };

        ts::end(scenario_val);
    }
}
