#[test_only]
module sage_channel::test_channel_membership {
    use std::string::{utf8};

    use sui::{table::{ETableNotEmpty}};

    use sui::test_scenario::{Self as ts, Scenario};

    use sage_admin::{admin::{Self, AdminCap}};

    use sage_channel::{
        channel::{Self},
        channel_membership::{Self, ChannelMembershipRegistry, EChannelMemberExists}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    const EChannelMembershipCountMismatch: u64 = 0;
    const EChannelNotMember: u64 = 1;

    // --------------- Test Functions ---------------

    #[test_only]
    public fun setup_for_testing(): (Scenario, ChannelMembershipRegistry) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let channel_membership_registry = {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            let channel_membership_registry = channel_membership::create_channel_membership_registry(
                &admin_cap,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, admin_cap);

            channel_membership_registry
        };

        (scenario_val, channel_membership_registry)
    }

    #[test]
    fun test_channel_membership_registry_init() {
        let (
            mut scenario_val,
            channel_membership_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            channel_membership::destroy_for_testing(channel_membership_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ETableNotEmpty)]
    fun test_channel_membership_create() {
        let (
            mut scenario_val,
            mut channel_membership_registry_val,
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_membership_registry = &mut channel_membership_registry_val;

            let created_at: u64 = 999;

            let channel = channel::create(
                utf8(b"channel-name"),
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                created_at,
                ADMIN
            );

            channel_membership::create(
                channel_membership_registry,
                channel,
                ts::ctx(scenario)
            );

            let channel_membership = channel_membership::get_membership(
                channel_membership_registry,
                channel
            );

            let channel_member_count = channel_membership::get_member_length(
                channel_membership
            );

            assert!(channel_member_count == 1, EChannelMembershipCountMismatch);

            let is_member = channel_membership::is_member(
                channel_membership,
                ADMIN
            );

            assert!(is_member, EChannelNotMember);

            channel_membership::destroy_for_testing(channel_membership_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EChannelMemberExists)]
    fun test_channel_join() {
        let (
            mut scenario_val,
            mut channel_membership_registry_val,
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_membership_registry = &mut channel_membership_registry_val;

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

            channel_membership::create(
                channel_membership_registry,
                channel,
                ts::ctx(scenario)
            );

            let channel_membership = channel_membership::get_membership(
                channel_membership_registry,
                channel
            );

            channel_membership::join(
                channel_membership,
                channel_name,
                ts::ctx(scenario)
            );

            channel_membership::destroy_for_testing(channel_membership_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ETableNotEmpty)]
    fun test_channel_leave() {
        let (
            mut scenario_val,
            mut channel_membership_registry_val,
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_membership_registry = &mut channel_membership_registry_val;

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

            channel_membership::create(
                channel_membership_registry,
                channel,
                ts::ctx(scenario)
            );

            let channel_membership = channel_membership::get_membership(
                channel_membership_registry,
                channel
            );

            channel_membership::leave(
                channel_membership,
                channel_name,
                ts::ctx(scenario)
            );

            let channel_member_count_leave = channel_membership::get_member_length(
                channel_membership
            );

            assert!(channel_member_count_leave == 0, EChannelMembershipCountMismatch);

            channel_membership::join(
                channel_membership,
                channel_name,
                ts::ctx(scenario)
            );

            let channel_member_count_join = channel_membership::get_member_length(
                channel_membership
            );

            assert!(channel_member_count_join == 1, EChannelMembershipCountMismatch);

            channel_membership::destroy_for_testing(channel_membership_registry_val);
        };

        ts::end(scenario_val);
    }
}
