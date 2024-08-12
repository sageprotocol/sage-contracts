#[test_only]
module sage_channel::test_channel_actions {
    use sui::clock::{Self, Clock};

    use std::string::{utf8};

    use sui::test_scenario::{Self as ts, Scenario};
    use sui::test_utils::{destroy};

    use sui::{
        table::{ETableNotEmpty}
    };

    use sage_admin::{
       admin::{Self, AdminCap, InviteCap}
    };

    use sage_channel::{
        channel::{Self},
        channel_actions::{Self, EUserDoesNotExist},
        channel_membership::{Self, ChannelMembershipRegistry},
        channel_registry::{Self, ChannelRegistry},
    };

    use sage_user::{
        user_actions::{Self},
        user_invite::{Self, InviteConfig, UserInviteRegistry},
        user_membership::{Self, UserMembershipRegistry},
        user_registry::{Self, UserRegistry}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;
    const SERVER: address = @server;

    // --------------- Errors ---------------

    const EMemberLength: u64 = 0;
    const EHasMember: u64 = 1;
    const EChannelAvatarMismatch: u64 = 2;
    const EChannelBannerMismatch: u64 = 3;
    const EChannelDescriptionMismatch: u64 = 4;

    // --------------- Test Functions ---------------

    #[test_only]
    fun destroy_for_testing(
        channel_registry: ChannelRegistry,
        channel_membership_registry: ChannelMembershipRegistry,
        user_registry: UserRegistry,
        user_invite_registry: UserInviteRegistry,
        user_membership_registry: UserMembershipRegistry,
        invite_config: InviteConfig
    ) {
        channel_membership::destroy_for_testing(channel_membership_registry);
        channel_registry::destroy_for_testing(channel_registry);
        user_registry::destroy_for_testing(user_registry);
        user_invite::destroy_for_testing(user_invite_registry);
        user_membership::destroy_for_testing(user_membership_registry);

        destroy(invite_config);
    }

    #[test_only]
    fun setup_for_testing(): (
        Scenario,
        ChannelRegistry,
        ChannelMembershipRegistry,
        UserRegistry,
        UserInviteRegistry,
        UserMembershipRegistry,
        InviteConfig
    ) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let (
            channel_registry,
            channel_membership_registry,
            user_registry,
            user_invite_registry,
            user_membership_registry,
            invite_config
        ) = {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            let invite_config = user_invite::create_invite_config(&admin_cap);

            let channel_registry = channel_registry::create_channel_registry(
                &admin_cap,
                ts::ctx(scenario)
            );

            let channel_membership_registry = channel_membership::create_channel_membership_registry(
                &admin_cap,
                ts::ctx(scenario)
            );

            let user_registry = user_registry::create_user_registry(
                &admin_cap,
                ts::ctx(scenario)
            );

            let user_invite_registry = user_invite::create_invite_registry(
                &admin_cap,
                ts::ctx(scenario)
            );

            let user_membership_registry = user_membership::create_user_membership_registry(
                &admin_cap,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, admin_cap);

            (
                channel_registry,
                channel_membership_registry,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                invite_config
            )
        };

        (
            scenario_val,
            channel_registry,
            channel_membership_registry,
            user_registry,
            user_invite_registry,
            user_membership_registry,
            invite_config
        )
    }

    #[test]
    fun test_channel_actions_init() {
        let (
            mut scenario_val,
            channel_registry_val,
            channel_membership_registry_val,
            user_registry_val,
            user_invite_registry_val,
            user_membership_registry_val,
            invite_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                channel_registry_val,
                channel_membership_registry_val,
                user_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                invite_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ETableNotEmpty)]
    fun test_channel_actions_create() {
        let (
            mut scenario_val,
            mut channel_registry_val,
            mut channel_membership_registry_val,
            mut user_registry_val,
            mut user_invite_registry_val,
            mut user_membership_registry_val,
            mut invite_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let channel_registry = &mut channel_registry_val;
        let channel_membership_registry = &mut channel_membership_registry_val;
        let user_registry = &mut user_registry_val;
        let user_invite_registry = &mut user_invite_registry_val;
        let user_membership_registry = &mut user_membership_registry_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);
        };

        ts::next_tx(scenario, SERVER);
        {
            let invite_cap = ts::take_from_sender<InviteCap>(scenario);

            user_invite::set_invite_config(
                &invite_cap,
                &mut invite_config,
                false
            );

            ts::return_to_sender(scenario, invite_cap);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let clock: Clock = ts::take_shared(scenario);

            let _user = user_actions::create(
                &clock,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                &invite_config,
                utf8(b""),
                utf8(b""),
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                utf8(b"user-name"),
                ts::ctx(scenario)
            );

            let channel_name = utf8(b"channel-name");

            let channel = channel_actions::create(
                &clock,
                channel_registry,
                channel_membership_registry,
                user_registry,
                channel_name,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                ts::ctx(scenario)
            );

            let channel_membership = channel_membership::borrow_membership_mut(
                channel_membership_registry,
                channel
            );

            let member_length = channel_membership::get_member_length(
                channel_membership
            );

            assert!(member_length == 1, EMemberLength);

            let has_member = channel_registry::has_record(
                channel_registry,
                channel_name
            );

            assert!(has_member, EHasMember);

            ts::return_shared(clock);

            destroy_for_testing(
                channel_registry_val,
                channel_membership_registry_val,
                user_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                invite_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EUserDoesNotExist)]
    fun test_channel_actions_create_no_user() {
        let (
            mut scenario_val,
            mut channel_registry_val,
            mut channel_membership_registry_val,
            mut user_registry_val,
            user_invite_registry_val,
            user_membership_registry_val,
            invite_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let channel_registry = &mut channel_registry_val;
        let channel_membership_registry = &mut channel_membership_registry_val;
        let user_registry = &mut user_registry_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let clock: Clock = ts::take_shared(scenario);

            let channel_name = utf8(b"channel-name");

            let channel = channel_actions::create(
                &clock,
                channel_registry,
                channel_membership_registry,
                user_registry,
                channel_name,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                ts::ctx(scenario)
            );

            let channel_membership = channel_membership::borrow_membership_mut(
                channel_membership_registry,
                channel
            );

            let member_length = channel_membership::get_member_length(
                channel_membership
            );

            assert!(member_length == 1, EMemberLength);

            let has_member = channel_registry::has_record(
                channel_registry,
                channel_name
            );

            assert!(has_member, EHasMember);

            ts::return_shared(clock);

            destroy_for_testing(
                channel_registry_val,
                channel_membership_registry_val,
                user_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                invite_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ETableNotEmpty)]
    fun test_channel_actions_update_avatar() {
        let (
            mut scenario_val,
            mut channel_registry_val,
            mut channel_membership_registry_val,
            mut user_registry_val,
            mut user_invite_registry_val,
            mut user_membership_registry_val,
            mut invite_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let channel_registry = &mut channel_registry_val;
        let channel_membership_registry = &mut channel_membership_registry_val;
        let user_registry = &mut user_registry_val;
        let user_invite_registry = &mut user_invite_registry_val;
        let user_membership_registry = &mut user_membership_registry_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);
        };

        ts::next_tx(scenario, SERVER);
        {
            let invite_cap = ts::take_from_sender<InviteCap>(scenario);

            user_invite::set_invite_config(
                &invite_cap,
                &mut invite_config,
                false
            );

            ts::return_to_sender(scenario, invite_cap);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let clock: Clock = ts::take_shared(scenario);
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            let _user = user_actions::create(
                &clock,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                &invite_config,
                utf8(b""),
                utf8(b""),
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                utf8(b"user-name"),
                ts::ctx(scenario)
            );

            let avatar_hash = utf8(b"avatar_hash");
            let channel_name = utf8(b"channel-name");

            let mut channel = channel_actions::create(
                &clock,
                channel_registry,
                channel_membership_registry,
                user_registry,
                channel_name,
                avatar_hash,
                utf8(b"banner_hash"),
                utf8(b"description"),
                ts::ctx(scenario)
            );

            let channel_avatar_hash = channel::get_avatar(
                channel
            );

            assert!(channel_avatar_hash == avatar_hash, EChannelAvatarMismatch);

            let new_avatar_hash = utf8(b"new_avatar_hash");

            channel_actions::update_avatar_admin(
                &admin_cap,
                channel_name,
                &mut channel,
                new_avatar_hash
            );

            let channel_avatar_hash = channel::get_avatar(
                channel
            );

            assert!(channel_avatar_hash == new_avatar_hash, EChannelAvatarMismatch);

            ts::return_shared(clock);
            ts::return_to_sender(scenario, admin_cap);

            destroy_for_testing(
                channel_registry_val,
                channel_membership_registry_val,
                user_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                invite_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ETableNotEmpty)]
    fun test_channel_actions_update_banner() {
        let (
            mut scenario_val,
            mut channel_registry_val,
            mut channel_membership_registry_val,
            mut user_registry_val,
            mut user_invite_registry_val,
            mut user_membership_registry_val,
            mut invite_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let channel_registry = &mut channel_registry_val;
        let channel_membership_registry = &mut channel_membership_registry_val;
        let user_registry = &mut user_registry_val;
        let user_invite_registry = &mut user_invite_registry_val;
        let user_membership_registry = &mut user_membership_registry_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);
        };

        ts::next_tx(scenario, SERVER);
        {
            let invite_cap = ts::take_from_sender<InviteCap>(scenario);

            user_invite::set_invite_config(
                &invite_cap,
                &mut invite_config,
                false
            );

            ts::return_to_sender(scenario, invite_cap);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let clock: Clock = ts::take_shared(scenario);
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            let _user = user_actions::create(
                &clock,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                &invite_config,
                utf8(b""),
                utf8(b""),
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                utf8(b"user-name"),
                ts::ctx(scenario)
            );

            let banner_hash = utf8(b"banner_hash");
            let channel_name = utf8(b"channel-name");

            let mut channel = channel_actions::create(
                &clock,
                channel_registry,
                channel_membership_registry,
                user_registry,
                channel_name,
                utf8(b"avatar_hash"),
                banner_hash,
                utf8(b"description"),
                ts::ctx(scenario)
            );

            let channel_banner_hash = channel::get_banner(
                channel
            );

            assert!(channel_banner_hash == banner_hash, EChannelBannerMismatch);

            let new_banner_hash = utf8(b"new_banner_hash");

            channel_actions::update_banner_admin(
                &admin_cap,
                channel_name,
                &mut channel,
                new_banner_hash
            );

            let channel_banner_hash = channel::get_banner(
                channel
            );

            assert!(channel_banner_hash == new_banner_hash, EChannelBannerMismatch);

            ts::return_shared(clock);
            ts::return_to_sender(scenario, admin_cap);

            destroy_for_testing(
                channel_registry_val,
                channel_membership_registry_val,
                user_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                invite_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ETableNotEmpty)]
    fun test_channel_actions_update_description() {
        let (
            mut scenario_val,
            mut channel_registry_val,
            mut channel_membership_registry_val,
            mut user_registry_val,
            mut user_invite_registry_val,
            mut user_membership_registry_val,
            mut invite_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let channel_registry = &mut channel_registry_val;
        let channel_membership_registry = &mut channel_membership_registry_val;
        let user_registry = &mut user_registry_val;
        let user_invite_registry = &mut user_invite_registry_val;
        let user_membership_registry = &mut user_membership_registry_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);
        };

        ts::next_tx(scenario, SERVER);
        {
            let invite_cap = ts::take_from_sender<InviteCap>(scenario);

            user_invite::set_invite_config(
                &invite_cap,
                &mut invite_config,
                false
            );

            ts::return_to_sender(scenario, invite_cap);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let clock: Clock = ts::take_shared(scenario);
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            let _user = user_actions::create(
                &clock,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                &invite_config,
                utf8(b""),
                utf8(b""),
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                utf8(b"user-name"),
                ts::ctx(scenario)
            );

            let channel_name = utf8(b"channel-name");
            let description = utf8(b"description");

            let mut channel = channel_actions::create(
                &clock,
                channel_registry,
                channel_membership_registry,
                user_registry,
                channel_name,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                description,
                ts::ctx(scenario)
            );

            let channel_description = channel::get_description(
                channel
            );

            assert!(channel_description == description, EChannelDescriptionMismatch);

            let new_description = utf8(b"new_description");

            channel_actions::update_description_admin(
                &admin_cap,
                channel_name,
                &mut channel,
                new_description
            );

            let channel_description = channel::get_description(
                channel
            );

            assert!(channel_description == new_description, EChannelDescriptionMismatch);

            ts::return_shared(clock);
            ts::return_to_sender(scenario, admin_cap);

            destroy_for_testing(
                channel_registry_val,
                channel_membership_registry_val,
                user_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                invite_config
            );
        };

        ts::end(scenario_val);
    }
}
