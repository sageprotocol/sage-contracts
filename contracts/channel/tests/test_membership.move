#[test_only]
module sage_channel::test_channel_membership {
    use std::string::{utf8};

    use sui::{
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy}
    };

    use sage_admin::{admin::{Self}};

    use sage_channel::{
        channel_membership::{
            Self,
            ChannelMembership,
            ChannelMembershipRegistry,
            EChannelMemberDoesNotExist,
            EChannelMemberExists
        }
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;
    const SERVER: address = @server;

    // --------------- Errors ---------------

    const EChannelMembershipCountMismatch: u64 = 0;
    const EChannelMembershipDoesNotExist: u64 = 1;
    const EChannelAlreadyMember: u64 = 2;
    const EChannelNotMember: u64 = 3;

    // --------------- Test Functions ---------------

    #[test_only]
    public fun setup_for_testing(): (Scenario, ChannelMembershipRegistry) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
            channel_membership::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let channel_membership_registry = {
            let channel_membership_registry = scenario.take_shared<ChannelMembershipRegistry>();

            channel_membership_registry
        };

        (scenario_val, channel_membership_registry)
    }

    #[test]
    fun test_init() {
        let (
            mut scenario_val,
            channel_membership_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy(channel_membership_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun create() {
        let (
            mut scenario_val,
            mut channel_membership_registry_val,
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_membership_registry = &mut channel_membership_registry_val;

            let channel_key = utf8(b"channel-name");

            let channel_membership_address = channel_membership::create(
                channel_membership_registry,
                channel_key,
                ts::ctx(scenario)
            );

            let borrowed_membership_address = channel_membership::borrow_membership_address(
                channel_membership_registry,
                channel_key
            );

            assert!(channel_membership_address == borrowed_membership_address, EChannelMembershipDoesNotExist);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let channel_membership = ts::take_shared<ChannelMembership>(
                scenario
            );

            let channel_member_count = channel_membership::get_member_length(
                &channel_membership
            );

            assert!(channel_member_count == 1, EChannelMembershipCountMismatch);

            let is_member = channel_membership::is_member(
                &channel_membership,
                ADMIN
            );

            assert!(is_member, EChannelNotMember);

            ts::return_shared(channel_membership);

            destroy(channel_membership_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun join() {
        let (
            mut scenario_val,
            mut channel_membership_registry_val,
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_membership_registry = &mut channel_membership_registry_val;

            let channel_key = utf8(b"channel-name");

            let _channel_membership_address = channel_membership::create(
                channel_membership_registry,
                channel_key,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, SERVER);
        {
            let mut channel_membership = ts::take_shared<ChannelMembership>(
                scenario
            );

            channel_membership::join(
                &mut channel_membership,
                SERVER
            );

            let channel_member_count = channel_membership::get_member_length(
                &channel_membership
            );

            assert!(channel_member_count == 2, EChannelMembershipCountMismatch);

            let is_member = channel_membership::is_member(
                &channel_membership,
                SERVER
            );

            assert!(is_member, EChannelNotMember);

            ts::return_shared(channel_membership);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy(channel_membership_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EChannelMemberExists)]
    fun join_fail() {
        let (
            mut scenario_val,
            mut channel_membership_registry_val,
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_membership_registry = &mut channel_membership_registry_val;

            let channel_key = utf8(b"channel-name");

            let _channel_membership_address = channel_membership::create(
                channel_membership_registry,
                channel_key,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut channel_membership = ts::take_shared<ChannelMembership>(
                scenario
            );

            channel_membership::join(
                &mut channel_membership,
                ADMIN
            );

            ts::return_shared(channel_membership);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy(channel_membership_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun leave() {
        let (
            mut scenario_val,
            mut channel_membership_registry_val,
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_membership_registry = &mut channel_membership_registry_val;

            let channel_key = utf8(b"channel-name");

            let _channel_membership_address = channel_membership::create(
                channel_membership_registry,
                channel_key,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut channel_membership = ts::take_shared<ChannelMembership>(
                scenario
            );

            channel_membership::leave(
                &mut channel_membership,
                ADMIN
            );

            let channel_member_count = channel_membership::get_member_length(
                &channel_membership
            );

            assert!(channel_member_count == 0, EChannelMembershipCountMismatch);

            let is_member = channel_membership::is_member(
                &channel_membership,
                SERVER
            );

            assert!(!is_member, EChannelAlreadyMember);

            ts::return_shared(channel_membership);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy(channel_membership_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EChannelMemberDoesNotExist)]
    fun leave_fail() {
        let (
            mut scenario_val,
            mut channel_membership_registry_val,
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_membership_registry = &mut channel_membership_registry_val;

            let channel_key = utf8(b"channel-name");

            let _channel_membership_address = channel_membership::create(
                channel_membership_registry,
                channel_key,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, SERVER);
        {
            let mut channel_membership = ts::take_shared<ChannelMembership>(
                scenario
            );

            channel_membership::leave(
                &mut channel_membership,
                SERVER
            );

            ts::return_shared(channel_membership);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy(channel_membership_registry_val);
        };

        ts::end(scenario_val);
    }
}
