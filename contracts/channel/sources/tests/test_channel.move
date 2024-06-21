#[test_only]
module sage::test_channel {
    use sui::clock::{Self, Clock};

    use std::string::{Self, utf8};

    use sui::test_scenario::{Self as ts, Scenario};

    use sui::{table::{ETableNotEmpty}};

    use sage::{
        admin::{Self, AdminCap},
        channel::{Self},
        channel_membership::{Self, ChannelMembershipRegistry},
        channel_registry::{Self, ChannelRegistry}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @0xde1;

    // --------------- Errors ---------------

    const EMemberLength: u64 = 0;
    const EIsMember: u64 = 1;
    const EChannelNameInvalid: u64 = 2;

    // --------------- Public Functions ---------------

    #[test_only]
    public fun setup_for_testing(): (Scenario, ChannelRegistry, ChannelMembershipRegistry) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let (channel_registry, channel_membership_registry) = {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            let channel_registry = channel_registry::create_channel_registry(
                &admin_cap,
                ts::ctx(scenario)
            );

            let channel_membership_registry = channel_membership::create_channel_membership_registry(
                &admin_cap,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, admin_cap);

            (channel_registry, channel_membership_registry)
        };

        (scenario_val, channel_registry, channel_membership_registry)
    }

    #[test]
    fun test_channel_init() {
        let (
            mut scenario_val,
            channel_registry_val,
            channel_membership_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            channel_membership::destroy_for_testing(channel_membership_registry_val);
            channel_registry::destroy_for_testing(channel_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ETableNotEmpty)]
    fun test_channel_create() {
        let (
            mut scenario_val,
            mut channel_registry_val,
            mut channel_membership_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let clock: Clock = ts::take_shared(scenario);

            let channel_registry = &mut channel_registry_val;
            let channel_membership_registry = &mut channel_membership_registry_val;

            let channel_id = channel::create(
                &clock,
                channel_registry,
                channel_membership_registry,
                string::utf8(b"channel-name"),
                string::utf8(b"avatar_hash"),
                string::utf8(b"banner_hash"),
                string::utf8(b"description"),
                ts::ctx(scenario)
            );

            let channel_membership = channel_membership::get_membership(
                channel_membership_registry,
                channel_id
            );

            let member_length = channel_membership::get_member_length(
                channel_membership
            );

            assert!(member_length == 1, EMemberLength);

            ts::return_shared(clock);

            channel_membership::destroy_for_testing(channel_membership_registry_val);
            channel_registry::destroy_for_testing(channel_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ETableNotEmpty)]
    fun test_channel_is_member() {
        let (
            mut scenario_val,
            mut channel_registry_val,
            mut channel_membership_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let clock: Clock = ts::take_shared(scenario);

            let channel_registry = &mut channel_registry_val;
            let channel_membership_registry = &mut channel_membership_registry_val;

            let channel_id = channel::create(
                &clock,
                channel_registry,
                channel_membership_registry,
                string::utf8(b"channel-name"),
                string::utf8(b"avatar_hash"),
                string::utf8(b"banner_hash"),
                string::utf8(b"description"),
                ts::ctx(scenario)
            );

            let channel_membership = channel_membership::get_membership(
                channel_membership_registry,
                channel_id
            );

            let is_member = channel_membership::is_member(
                channel_membership,
                tx_context::sender(ts::ctx(scenario))
            );

            assert!(is_member, EIsMember);

            ts::return_shared(clock);

            channel_membership::destroy_for_testing(channel_membership_registry_val);
            channel_registry::destroy_for_testing(channel_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ETableNotEmpty)]
    fun test_channel_leave() {
        let (
            mut scenario_val,
            mut channel_registry_val,
            mut channel_membership_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let clock: Clock = ts::take_shared(scenario);

            let channel_registry = &mut channel_registry_val;
            let channel_membership_registry = &mut channel_membership_registry_val;

            let channel_id = channel::create(
                &clock,
                channel_registry,
                channel_membership_registry,
                string::utf8(b"channel-name"),
                string::utf8(b"avatar_hash"),
                string::utf8(b"banner_hash"),
                string::utf8(b"description"),
                ts::ctx(scenario)
            );

            let channel_membership = channel_membership::get_membership(
                channel_membership_registry,
                channel_id
            );

            channel_membership::leave(
                channel_membership,
                channel_id,
                ts::ctx(scenario)
            );

            let member_length = channel_membership::get_member_length(
                channel_membership
            );

            assert!(member_length == 0, EMemberLength);

            ts::return_shared(clock);

            channel_membership::destroy_for_testing(channel_membership_registry_val);
            channel_registry::destroy_for_testing(channel_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_channel_name_validity() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"ab");

            let is_valid = channel::is_valid_channel_name_for_testing(&name);

            assert!(is_valid == false, EChannelNameInvalid);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"abcdefghijklmnopqrstu");

            let is_valid = channel::is_valid_channel_name_for_testing(&name);

            assert!(is_valid == false, EChannelNameInvalid);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"abcdefghijklmnopqrst");

            let is_valid = channel::is_valid_channel_name_for_testing(&name);

            assert!(is_valid == true, EChannelNameInvalid);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"abcdefghij-klmnopqrs");

            let is_valid = channel::is_valid_channel_name_for_testing(&name);

            assert!(is_valid == true, EChannelNameInvalid);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"ab-");

            let is_valid = channel::is_valid_channel_name_for_testing(&name);

            assert!(is_valid == false, EChannelNameInvalid);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"-ab");

            let is_valid = channel::is_valid_channel_name_for_testing(&name);

            assert!(is_valid == false, EChannelNameInvalid);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"a_b");

            let is_valid = channel::is_valid_channel_name_for_testing(&name);

            assert!(is_valid == false, EChannelNameInvalid);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"ab?");

            let is_valid = channel::is_valid_channel_name_for_testing(&name);

            assert!(is_valid == false, EChannelNameInvalid);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"ab\"ab");

            let is_valid = channel::is_valid_channel_name_for_testing(&name);

            assert!(is_valid == false, EChannelNameInvalid);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"ab123");

            let is_valid = channel::is_valid_channel_name_for_testing(&name);

            assert!(is_valid == true, EChannelNameInvalid);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"987ab");

            let is_valid = channel::is_valid_channel_name_for_testing(&name);

            assert!(is_valid == true, EChannelNameInvalid);
        };

        ts::end(scenario_val);
    }
}
