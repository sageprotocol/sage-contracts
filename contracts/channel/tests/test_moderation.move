#[test_only]
module sage_channel::test_channel_moderation {
    use std::string::{utf8};

    use sui::{
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy}
    };

    use sage_admin::{admin::{Self}};

    use sage_channel::{
        channel_moderation::{Self, ChannelModerationRegistry, EChannelModerationRecordDoesNotExist}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;
    const SERVER: address = @server;

    // --------------- Errors ---------------

    const EChannelModerationDoesNotExist: u64 = 0;
    const EIsModerator: u64 = 1;
    const EIsNotModerator: u64 = 2;

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
    fun registry_init() {
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
    fun registry_add() {
        let (
            mut scenario_val,
            mut channel_moderation_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_moderation_registry = &mut channel_moderation_registry_val;

            let channel_key = utf8(b"channel-name");

            channel_moderation::create(
                channel_moderation_registry,
                channel_key,
                ts::ctx(scenario)
            );

            let has_record = channel_moderation::has_record(
                channel_moderation_registry,
                channel_key
            );

            assert!(has_record, EChannelModerationDoesNotExist);

            let is_moderator = channel_moderation::is_moderator(
                channel_moderation_registry,
                channel_key,
                ADMIN
            );

            assert!(is_moderator, EIsNotModerator);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy(channel_moderation_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun replace() {
        let (
            mut scenario_val,
            mut channel_moderation_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_moderation_registry = &mut channel_moderation_registry_val;

            let channel_key = utf8(b"channel-name");

            channel_moderation::create(
                channel_moderation_registry,
                channel_key,
                ts::ctx(scenario)
            );

            let mut channel_moderators = vector::empty<address>();
            channel_moderators.push_back(SERVER);

            channel_moderation::replace(
                channel_moderation_registry,
                channel_key,
                channel_moderators
            );

            let is_moderator = channel_moderation::is_moderator(
                channel_moderation_registry,
                channel_key,
                ADMIN
            );

            assert!(!is_moderator, EIsModerator);

            let is_moderator = channel_moderation::is_moderator(
                channel_moderation_registry,
                channel_key,
                SERVER
            );

            assert!(is_moderator, EIsNotModerator);

            destroy(channel_moderation_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EChannelModerationRecordDoesNotExist)]
    fun replace_fail() {
        let (
            mut scenario_val,
            mut channel_moderation_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_moderation_registry = &mut channel_moderation_registry_val;

            let channel_key = utf8(b"channel-name");

            let mut channel_moderators = vector::empty<address>();
            channel_moderators.push_back(SERVER);

            channel_moderation::replace(
                channel_moderation_registry,
                channel_key,
                channel_moderators
            );

            destroy(channel_moderation_registry_val);
        };

        ts::end(scenario_val);
    }
}
