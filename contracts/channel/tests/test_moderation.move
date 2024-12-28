#[test_only]
module sage_channel::test_channel_moderation {
    use std::string::{utf8};

    use sui::{
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy}
    };

    use sage_admin::{admin::{Self}};

    use sage_channel::{
        channel_moderation::{
            Self,
            ChannelModeration,
            ChannelModerationRegistry,
            EAlreadyChannelModerator,
            EChannelModerationRecordExists,
            ENotChannelModerator
        }
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;
    const SERVER: address = @server;

    // --------------- Errors ---------------

    const EChannelModerationAddressMismatch: u64 = 0;
    const EChannelModerationDoesNotExist: u64 = 1;
    const EChannelModerationLengthMismatch: u64 = 2;
    const EIsModerator: u64 = 2;
    const EIsNotModerator: u64 = 3;

    // --------------- Test Functions ---------------

    #[test_only]
    fun setup_for_testing(): (Scenario, ChannelModerationRegistry) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
            channel_moderation::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let channel_moderation_registry = {
            let channel_moderation_registry = scenario.take_shared<ChannelModerationRegistry>();

            channel_moderation_registry
        };

        (scenario_val, channel_moderation_registry)
    }

    #[test]
    fun test_init() {
        let (
            mut scenario_val,
            channel_moderation_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy(channel_moderation_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun create() {
        let (
            mut scenario_val,
            mut channel_moderation_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let channel_moderation_registry = &mut channel_moderation_registry_val;

        let channel_key = utf8(b"channel-name");

        ts::next_tx(scenario, ADMIN);
        {
            let _channel_moderation_address = channel_moderation::create(
                channel_moderation_registry,
                channel_key,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let has_record = channel_moderation::has_record(
                channel_moderation_registry,
                channel_key
            );

            assert!(has_record, EChannelModerationDoesNotExist);

            let channel_moderation = ts::take_shared<ChannelModeration>(
                scenario
            );

            let is_moderator = channel_moderation::is_moderator(
                &channel_moderation,
                ADMIN
            );

            assert!(is_moderator, EIsNotModerator);

            ts::return_shared(channel_moderation);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy(channel_moderation_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EChannelModerationRecordExists)]
    fun create_fail() {
        let (
            mut scenario_val,
            mut channel_moderation_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let channel_moderation_registry = &mut channel_moderation_registry_val;

        let channel_key = utf8(b"channel-name");

        ts::next_tx(scenario, ADMIN);
        {
            let _channel_moderation_address = channel_moderation::create(
                channel_moderation_registry,
                channel_key,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let _channel_moderation_address = channel_moderation::create(
                channel_moderation_registry,
                channel_key,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy(channel_moderation_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun borrow_moderation_address() {
        let (
            mut scenario_val,
            mut channel_moderation_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let channel_moderation_registry = &mut channel_moderation_registry_val;

            let channel_key = utf8(b"channel-name");

        ts::next_tx(scenario, ADMIN);
        let channel_moderation_address = {
            channel_moderation::create(
                channel_moderation_registry,
                channel_key,
                ts::ctx(scenario)
            )
        };

        ts::next_tx(scenario, ADMIN);
        {
            let channel_moderation = ts::take_shared<ChannelModeration>(
                scenario
            );

            let borrowed_moderation_address = channel_moderation::borrow_moderation_address(
                channel_moderation_registry,
                channel_key
            );

            assert!(channel_moderation_address == borrowed_moderation_address, EChannelModerationAddressMismatch);

            ts::return_shared(channel_moderation);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy(channel_moderation_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun get_moderator_length() {
        let (
            mut scenario_val,
            mut channel_moderation_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_moderation_registry = &mut channel_moderation_registry_val;

            let channel_key = utf8(b"channel-name");

            let _channel_moderation_address = channel_moderation::create(
                channel_moderation_registry,
                channel_key,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let channel_moderation = ts::take_shared<ChannelModeration>(
                scenario
            );

            let length = channel_moderation.get_moderator_length();

            assert!(length == 1, EChannelModerationLengthMismatch);

            ts::return_shared(channel_moderation);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy(channel_moderation_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun is_moderator() {
        let (
            mut scenario_val,
            mut channel_moderation_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_moderation_registry = &mut channel_moderation_registry_val;

            let channel_key = utf8(b"channel-name");

            let _channel_moderation_address = channel_moderation::create(
                channel_moderation_registry,
                channel_key,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let channel_moderation = ts::take_shared<ChannelModeration>(
                scenario
            );

            let is_moderator = channel_moderation::is_moderator(
                &channel_moderation,
                ADMIN
            );

            assert!(is_moderator, EIsNotModerator);

            ts::return_shared(channel_moderation);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy(channel_moderation_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun add() {
        let (
            mut scenario_val,
            mut channel_moderation_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_moderation_registry = &mut channel_moderation_registry_val;

            let channel_key = utf8(b"channel-name");

            let _channel_moderation_address = channel_moderation::create(
                channel_moderation_registry,
                channel_key,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut channel_moderation = ts::take_shared<ChannelModeration>(
                scenario
            );

            channel_moderation::add(
                &mut channel_moderation,
                SERVER
            );

            let is_moderator = channel_moderation::is_moderator(
                &channel_moderation,
                SERVER
            );

            assert!(is_moderator, EIsNotModerator);

            ts::return_shared(channel_moderation);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy(channel_moderation_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EAlreadyChannelModerator)]
    fun add_fail() {
        let (
            mut scenario_val,
            mut channel_moderation_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_moderation_registry = &mut channel_moderation_registry_val;

            let channel_key = utf8(b"channel-name");

            let _channel_moderation_address = channel_moderation::create(
                channel_moderation_registry,
                channel_key,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut channel_moderation = ts::take_shared<ChannelModeration>(
                scenario
            );

            channel_moderation::add(
                &mut channel_moderation,
                ADMIN
            );

            ts::return_shared(channel_moderation);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy(channel_moderation_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun remove() {
        let (
            mut scenario_val,
            mut channel_moderation_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_moderation_registry = &mut channel_moderation_registry_val;

            let channel_key = utf8(b"channel-name");

            let _channel_moderation_address = channel_moderation::create(
                channel_moderation_registry,
                channel_key,
                ts::ctx(scenario)
            );
        };
        
        ts::next_tx(scenario, ADMIN);
        {
            let mut channel_moderation = ts::take_shared<ChannelModeration>(
                scenario
            );

            channel_moderation::add(
                &mut channel_moderation,
                SERVER
            );

            channel_moderation::remove(
                &mut channel_moderation,
                SERVER
            );

            let is_moderator = channel_moderation::is_moderator(
                &channel_moderation,
                SERVER
            );

            assert!(!is_moderator, EIsModerator);

            ts::return_shared(channel_moderation);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy(channel_moderation_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ENotChannelModerator)]
    fun remove_fail() {
        let (
            mut scenario_val,
            mut channel_moderation_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_moderation_registry = &mut channel_moderation_registry_val;

            let channel_key = utf8(b"channel-name");

            let _channel_moderation_address = channel_moderation::create(
                channel_moderation_registry,
                channel_key,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut channel_moderation = ts::take_shared<ChannelModeration>(
                scenario
            );

            channel_moderation::remove(
                &mut channel_moderation,
                SERVER
            );

            ts::return_shared(channel_moderation);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy(channel_moderation_registry_val);
        };

        ts::end(scenario_val);
    }
}
