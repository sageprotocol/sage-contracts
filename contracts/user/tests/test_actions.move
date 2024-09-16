#[test_only]
module sage_user::test_user_actions {
    use std::string::{utf8};

    use sui::{
        clock::{Self, Clock},
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy}
    };

    use sage_admin::{
        admin::{Self, AdminCap, InviteCap}
    };

    use sage_user::{
        user_actions::{Self, EInviteNotAllowed},
        user_invite::{Self, InviteConfig, UserInviteRegistry},
        user_membership::{Self, UserMembershipRegistry},
        user_registry::{Self, UserRegistry},
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;
    const OTHER: address = @0xbabe;
    const SERVER: address = @server;

    // --------------- Errors ---------------

    const EHasMember: u64 = 370;
    const EHashMismatch: u64 = 371;
    const ENoInviteRecord: u64 = 372;
    const EUserInviteMismatch: u64 = 373;
    const EUserMembershipCountMismatch: u64 = 374;
    const EUserNotMember: u64 = 375;

    // --------------- Test Functions ---------------

    #[test_only]
    fun destroy_for_testing(
        user_registry: UserRegistry,
        user_invite_registry: UserInviteRegistry,
        user_membership_registry: UserMembershipRegistry,
        invite_config: InviteConfig
    ) {
        destroy(invite_config);
        destroy(user_registry);
        destroy(user_invite_registry);
        destroy(user_membership_registry);
    }

    #[test_only]
    fun setup_for_testing(): (
        Scenario,
        UserRegistry,
        UserInviteRegistry,
        UserMembershipRegistry,
        InviteConfig
    ) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
            user_invite::init_for_testing(ts::ctx(scenario));
            user_membership::init_for_testing(ts::ctx(scenario));
            user_registry::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let (
            user_registry,
            user_invite_registry,
            user_membership_registry,
            invite_config
        ) = {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            let invite_config = scenario.take_shared<InviteConfig>();
            let user_registry = scenario.take_shared<UserRegistry>();
            let user_invite_registry = scenario.take_shared<UserInviteRegistry>();
            let user_membership_registry = scenario.take_shared<UserMembershipRegistry>();
            ts::return_to_sender(scenario, admin_cap);

            (user_registry, user_invite_registry, user_membership_registry, invite_config)
        };

        (scenario_val, user_registry, user_invite_registry, user_membership_registry, invite_config)
    }

    #[test]
    fun test_user_actions_init() {
        let (
            mut scenario_val,
            user_registry_val,
            user_invite_registry_val,
            user_membership_registry_val,
            invite_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                user_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                invite_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_actions_create() {
        let (
            mut scenario_val,
            mut user_registry_val,
            mut user_invite_registry_val,
            mut user_membership_registry_val,
            invite_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let user_registry = &mut user_registry_val;
        let user_invite_registry = &mut user_invite_registry_val;
        let user_membership_registry = &mut user_membership_registry_val;

        let invite_code = utf8(b"");
        let invite_key = utf8(b"");

        ts::next_tx(scenario, ADMIN);
        {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let clock: Clock = ts::take_shared(scenario);

            let name = utf8(b"user-name");    

            let _user = user_actions::create(
                &clock,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                &invite_config,
                invite_code,
                invite_key,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                name,
                ts::ctx(scenario)
            );

            let has_member = user_registry::has_address_record(
                user_registry,
                ADMIN
            );

            assert!(has_member, EHasMember);

            let has_member = user_registry::has_username_record(
                user_registry,
                name
            );

            assert!(has_member, EHasMember);

            ts::return_shared(clock);

            destroy_for_testing(
                user_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                invite_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_actions_join() {
        let (
            mut scenario_val,
            mut user_registry_val,
            mut user_invite_registry_val,
            mut user_membership_registry_val,
            invite_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let user_registry = &mut user_registry_val;
        let user_invite_registry = &mut user_invite_registry_val;
        let user_membership_registry = &mut user_membership_registry_val;

        let invite_code = utf8(b"");
        let invite_key = utf8(b"");

        let other_name = utf8(b"other-name");

        ts::next_tx(scenario, OTHER);
        let (other_user, user_registry, user_membership_registry) = {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            let other_user = user_actions::create(
                &clock,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                &invite_config,
                invite_code,
                invite_key,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                other_name,
                ts::ctx(scenario)
            );

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);

            (other_user, user_registry, user_membership_registry)
        };

        ts::next_tx(scenario, ADMIN);
        {
            let clock: Clock = ts::take_shared(scenario);

            let name = utf8(b"user-name");    

            let _user = user_actions::create(
                &clock,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                &invite_config,
                invite_code,
                invite_key,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                name,
                ts::ctx(scenario)
            );

            user_actions::join(
                user_registry,
                user_membership_registry,
                other_name,
                ts::ctx(scenario)
            );

            let user_membership = user_membership::borrow_membership_mut(
                user_membership_registry,
                other_user
            );

            let is_member = user_membership::is_member(
                user_membership,
                ADMIN
            );

            assert!(is_member, EUserNotMember);

            let member_length = user_membership::get_member_length(
                user_membership
            );

            assert!(member_length == 1, EUserMembershipCountMismatch);

            ts::return_shared(clock);

            destroy_for_testing(
                user_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                invite_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_invite_create() {
        let (
            mut scenario_val,
            user_registry_val,
            mut user_invite_registry_val,
            user_membership_registry_val,
            invite_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let user_invite_registry = &mut user_invite_registry_val;

        let invite_code = utf8(b"code");
        let invite_key = utf8(b"key");
        let invite_hash = b"hash";

        ts::next_tx(scenario, ADMIN);
        {
            user_actions::create_invite(
                user_invite_registry,
                &invite_config,
                invite_code,
                invite_hash,
                invite_key,
                ts::ctx(scenario)
            );

            let has_record = user_invite::has_record(
                user_invite_registry,
                invite_key
            );

            assert!(has_record, ENoInviteRecord);

            let (hash, user) = user_invite::get_destructured_invite(
                user_invite_registry,
                invite_key
            );

            assert!(hash == invite_hash, EHashMismatch);
            assert!(user == ADMIN, EUserInviteMismatch);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                user_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                invite_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInviteNotAllowed)]
    fun test_user_invite_create_fail() {
        let (
            mut scenario_val,
            user_registry_val,
            mut user_invite_registry_val,
            user_membership_registry_val,
            mut invite_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let user_invite_registry = &mut user_invite_registry_val;

        let invite_code = utf8(b"code");
        let invite_key = utf8(b"key");
        let invite_hash = b"hash";

        ts::next_tx(scenario, SERVER);
        {
            let invite_cap = ts::take_from_sender<InviteCap>(scenario);

            user_invite::set_invite_config(
                &invite_cap,
                &mut invite_config,
                true
            );

            ts::return_to_sender(scenario, invite_cap);
        };

        ts::next_tx(scenario, ADMIN);
        {
            user_actions::create_invite(
                user_invite_registry,
                &invite_config,
                invite_code,
                invite_hash,
                invite_key,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                user_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                invite_config
            );
        };

        ts::end(scenario_val);
    }

     #[test]
    fun test_user_invite_create_admin() {
        let (
            mut scenario_val,
            user_registry_val,
            mut user_invite_registry_val,
            user_membership_registry_val,
            invite_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let user_invite_registry = &mut user_invite_registry_val;

        let invite_key = utf8(b"key");
        let invite_hash = b"hash";

        ts::next_tx(scenario, SERVER);
        {
            let invite_cap = ts::take_from_sender<InviteCap>(scenario);

            user_actions::create_invite_admin(
                &invite_cap,
                user_invite_registry,
                invite_hash,
                invite_key,
                OTHER
            );

            let has_record = user_invite::has_record(
                user_invite_registry,
                invite_key
            );

            assert!(has_record, ENoInviteRecord);

            let (hash, user) = user_invite::get_destructured_invite(
                user_invite_registry,
                invite_key
            );

            assert!(hash == invite_hash, EHashMismatch);
            assert!(user == OTHER, EUserInviteMismatch);

            ts::return_to_sender(scenario, invite_cap);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                user_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                invite_config
            );
        };

        ts::end(scenario_val);
    }
}
