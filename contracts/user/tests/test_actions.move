#[test_only]
module sage_user::test_user_actions {
    use std::string::{utf8};

    use sui::{
        clock::{Self, Clock},
        coin::{mint_for_testing},
        sui::{SUI},
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy}
    };

    use sage_admin::{
        admin::{Self, AdminCap, InviteCap},
        apps::{Self, App}
    };

    use sage_user::{
        user::{Self, User},
        user_actions::{
            Self,
            EInviteNotAllowed,
            ENoSelfJoin,
            EUserDoesNotExist,
            EUserMembershipMismatch,
            EUserNameMismatch
        },
        user_fees::{Self, UserFees},
        user_invite::{Self, InviteConfig, UserInviteRegistry},
        user_membership::{Self, UserMembership, UserMembershipRegistry},
        user_registry::{Self, UserRegistry},
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;
    const OTHER: address = @0xbabe;
    const SERVER: address = @server;

    const CREATE_INVITE_CUSTOM_FEE: u64 = 1;
    const CREATE_INVITE_SUI_FEE: u64 = 2;
    const CREATE_USER_CUSTOM_FEE: u64 = 3;
    const CREATE_USER_SUI_FEE: u64 = 4;
    const JOIN_USER_CUSTOM_FEE: u64 = 5;
    const JOIN_USER_SUI_FEE: u64 = 6;
    const LEAVE_USER_CUSTOM_FEE: u64 = 7;
    const LEAVE_USER_SUI_FEE: u64 = 8;
    const UPDATE_USER_CUSTOM_FEE: u64 = 9;
    const UPDATE_USER_SUI_FEE: u64 = 10;

    // --------------- Errors ---------------

    const EHasMember: u64 = 0;
    const EHashMismatch: u64 = 1;
    const EInviteRecordExists: u64 = 2;
    const ENoInviteRecord: u64 = 3;
    const EUserAvatarMismatch: u64 = 4;
    const EUserBannerMismatch: u64 = 5;
    const EUserDescriptionMismatch: u64 = 6;
    const EUserInviteMismatch: u64 = 7;
    const EUserMembershipCountMismatch: u64 = 8;
    const ETestUserNameMismatch: u64 = 9;
    const EUserMember: u64 = 10;
    const EUserNotMember: u64 = 11;

    // --------------- Test Functions ---------------

    #[test_only]
    fun destroy_for_testing(
        app: App,
        user_registry: UserRegistry,
        user_invite_registry: UserInviteRegistry,
        user_membership_registry: UserMembershipRegistry,
        invite_config: InviteConfig,
        user_fees: UserFees
    ) {
        destroy(app);
        destroy(invite_config);
        destroy(user_registry);
        destroy(user_invite_registry);
        destroy(user_membership_registry);
        destroy(user_fees);
    }

    #[test_only]
    fun setup_for_testing(): (
        Scenario,
        App,
        UserRegistry,
        UserInviteRegistry,
        UserMembershipRegistry,
        InviteConfig,
        UserFees
    ) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
            apps::init_for_testing(ts::ctx(scenario));
            user_invite::init_for_testing(ts::ctx(scenario));
            user_membership::init_for_testing(ts::ctx(scenario));
            user_registry::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let (
            app,
            user_registry,
            user_invite_registry,
            user_membership_registry,
            invite_config,
            user_fees
        ) = {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            let invite_config = scenario.take_shared<InviteConfig>();
            let user_registry = scenario.take_shared<UserRegistry>();
            let user_invite_registry = scenario.take_shared<UserInviteRegistry>();
            let user_membership_registry = scenario.take_shared<UserMembershipRegistry>();

            let mut app = apps::create_for_testing(
                utf8(b"sage"),
                ts::ctx(scenario)
            );

            let user_fees = user_fees::create_for_testing<SUI>(
                &mut app,
                CREATE_INVITE_CUSTOM_FEE,
                CREATE_INVITE_SUI_FEE,
                CREATE_USER_CUSTOM_FEE,
                CREATE_USER_SUI_FEE,
                JOIN_USER_CUSTOM_FEE,
                JOIN_USER_SUI_FEE,
                LEAVE_USER_CUSTOM_FEE,
                LEAVE_USER_SUI_FEE,
                UPDATE_USER_CUSTOM_FEE,
                UPDATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, admin_cap);

            (
                app,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                invite_config,
                user_fees
            )
        };

        (
            scenario_val,
            app,
            user_registry,
            user_invite_registry,
            user_membership_registry,
            invite_config,
            user_fees
        )
    }

    #[test]
    fun test_user_actions_init() {
        let (
            mut scenario_val,
            app,
            user_registry_val,
            user_invite_registry_val,
            user_membership_registry_val,
            invite_config,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                app,
                user_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                invite_config,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_actions_create() {
        let (
            mut scenario_val,
            app,
            mut user_registry_val,
            mut user_invite_registry_val,
            mut user_membership_registry_val,
            invite_config,
            user_fees
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

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let _user_address = user_actions::create(
                &clock,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                &user_fees,
                &invite_config,
                invite_code,
                invite_key,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                name,
                custom_payment,
                sui_payment,
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
                app,
                user_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                invite_config,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_actions_create_invite_included() {
        let (
            mut scenario_val,
            app,
            mut user_registry_val,
            mut user_invite_registry_val,
            mut user_membership_registry_val,
            invite_config,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let user_registry = &mut user_registry_val;
        let user_invite_registry = &mut user_invite_registry_val;
        let user_membership_registry = &mut user_membership_registry_val;

        let invite_code = utf8(b"code");
        let invite_key = utf8(b"key");
        
        let mut invite_hash = vector::empty<u8>();

        invite_hash.push_back(0xd4);
        invite_hash.push_back(0x9b);
        invite_hash.push_back(0x04);
        invite_hash.push_back(0x7a);
        invite_hash.push_back(0xac);
        invite_hash.push_back(0xa5);
        invite_hash.push_back(0xfd);
        invite_hash.push_back(0x3e);
        invite_hash.push_back(0x37);
        invite_hash.push_back(0xea);
        invite_hash.push_back(0x3b);
        invite_hash.push_back(0xe6);
        invite_hash.push_back(0x31);
        invite_hash.push_back(0x1e);
        invite_hash.push_back(0x68);
        invite_hash.push_back(0xfc);
        invite_hash.push_back(0x91);
        invite_hash.push_back(0x8e);
        invite_hash.push_back(0x7e);
        invite_hash.push_back(0x16);
        invite_hash.push_back(0xbd);
        invite_hash.push_back(0x31);
        invite_hash.push_back(0xbf);
        invite_hash.push_back(0xcd);
        invite_hash.push_back(0x24);
        invite_hash.push_back(0xc4);
        invite_hash.push_back(0x4b);
        invite_hash.push_back(0xa5);
        invite_hash.push_back(0xc9);
        invite_hash.push_back(0x38);
        invite_hash.push_back(0xe9);
        invite_hash.push_back(0x4a);

        ts::next_tx(scenario, ADMIN);
        {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);
        };

        ts::next_tx(scenario, ADMIN);
        {
            user_invite::create_invite(
                user_invite_registry,
                invite_hash,
                invite_key,
                OTHER
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let clock: Clock = ts::take_shared(scenario);

            let name = utf8(b"user-name");

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let _user_address = user_actions::create(
                &clock,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                &user_fees,
                &invite_config,
                invite_code,
                invite_key,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                name,
                custom_payment,
                sui_payment,
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

            let has_record = user_invite::has_record(
                user_invite_registry,
                invite_key
            );

            assert!(!has_record, EInviteRecordExists);

            ts::return_shared(clock);

            destroy_for_testing(
                app,
                user_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                invite_config,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_actions_create_invite_required() {
        let (
            mut scenario_val,
            app,
            mut user_registry_val,
            mut user_invite_registry_val,
            mut user_membership_registry_val,
            mut invite_config,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let user_registry = &mut user_registry_val;
        let user_invite_registry = &mut user_invite_registry_val;
        let user_membership_registry = &mut user_membership_registry_val;

        let invite_code = utf8(b"code");
        let invite_key = utf8(b"key");
        
        let mut invite_hash = vector::empty<u8>();

        invite_hash.push_back(0xd4);
        invite_hash.push_back(0x9b);
        invite_hash.push_back(0x04);
        invite_hash.push_back(0x7a);
        invite_hash.push_back(0xac);
        invite_hash.push_back(0xa5);
        invite_hash.push_back(0xfd);
        invite_hash.push_back(0x3e);
        invite_hash.push_back(0x37);
        invite_hash.push_back(0xea);
        invite_hash.push_back(0x3b);
        invite_hash.push_back(0xe6);
        invite_hash.push_back(0x31);
        invite_hash.push_back(0x1e);
        invite_hash.push_back(0x68);
        invite_hash.push_back(0xfc);
        invite_hash.push_back(0x91);
        invite_hash.push_back(0x8e);
        invite_hash.push_back(0x7e);
        invite_hash.push_back(0x16);
        invite_hash.push_back(0xbd);
        invite_hash.push_back(0x31);
        invite_hash.push_back(0xbf);
        invite_hash.push_back(0xcd);
        invite_hash.push_back(0x24);
        invite_hash.push_back(0xc4);
        invite_hash.push_back(0x4b);
        invite_hash.push_back(0xa5);
        invite_hash.push_back(0xc9);
        invite_hash.push_back(0x38);
        invite_hash.push_back(0xe9);
        invite_hash.push_back(0x4a);

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
                true
            );

            ts::return_to_sender(scenario, invite_cap);
        };

        ts::next_tx(scenario, ADMIN);
        {
            user_invite::create_invite(
                user_invite_registry,
                invite_hash,
                invite_key,
                OTHER
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let clock: Clock = ts::take_shared(scenario);

            let name = utf8(b"user-name");

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let _user_address = user_actions::create(
                &clock,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                &user_fees,
                &invite_config,
                invite_code,
                invite_key,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                name,
                custom_payment,
                sui_payment,
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

            let has_record = user_invite::has_record(
                user_invite_registry,
                invite_key
            );

            assert!(!has_record, EInviteRecordExists);

            ts::return_shared(clock);

            destroy_for_testing(
                app,
                user_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                invite_config,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_actions_join() {
        let (
            mut scenario_val,
            app,
            mut user_registry_val,
            mut user_invite_registry_val,
            mut user_membership_registry_val,
            invite_config,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let user_registry = &mut user_registry_val;
        let user_invite_registry = &mut user_invite_registry_val;
        let user_membership_registry = &mut user_membership_registry_val;

        let invite_code = utf8(b"");
        let invite_key = utf8(b"");

        let other_name = utf8(b"other-name");

        ts::next_tx(scenario, OTHER);
        let (user_registry, user_membership_registry) = {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let _other_user_address = user_actions::create(
                &clock,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                &user_fees,
                &invite_config,
                invite_code,
                invite_key,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                other_name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);

            (user_registry, user_membership_registry)
        };

        ts::next_tx(scenario, OTHER);
        let (
            user,
            mut user_membership
         ) = {
            let user = ts::take_from_sender<User>(
                scenario
            );
            let user_membership = ts::take_shared<UserMembership>(
                scenario
            );

            (user, user_membership)
        };

        ts::next_tx(scenario, ADMIN);
        let clock = {
            let clock: Clock = ts::take_shared(scenario);

            let name = utf8(b"user-name");

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            ); 

            let _user_address = user_actions::create(
                &clock,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                &user_fees,
                &invite_config,
                invite_code,
                invite_key,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            clock
        };

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                JOIN_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                JOIN_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::join(
                user_registry,
                user_membership_registry,
                &user,
                &mut user_membership,
                &user_fees,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let is_member = user_membership::is_member(
                &user_membership,
                ADMIN
            );

            assert!(is_member, EUserNotMember);

            let member_length = user_membership::get_member_length(
                &user_membership
            );

            assert!(member_length == 1, EUserMembershipCountMismatch);

            ts::return_shared(clock);
            ts::return_shared(user_membership);

            ts::return_to_address(
                OTHER,
                user
            );

            destroy_for_testing(
                app,
                user_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                invite_config,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EUserDoesNotExist)]
    fun test_user_actions_join_no_user() {
        let (
            mut scenario_val,
            app,
            mut user_registry_val,
            mut user_invite_registry_val,
            mut user_membership_registry_val,
            invite_config,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let user_registry = &mut user_registry_val;
        let user_invite_registry = &mut user_invite_registry_val;
        let user_membership_registry = &mut user_membership_registry_val;

        let invite_code = utf8(b"");
        let invite_key = utf8(b"");

        let other_name = utf8(b"other-name");

        ts::next_tx(scenario, OTHER);
        let (user_registry, user_membership_registry) = {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let _other_user_address = user_actions::create(
                &clock,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                &user_fees,
                &invite_config,
                invite_code,
                invite_key,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                other_name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);

            (user_registry, user_membership_registry)
        };

        ts::next_tx(scenario, OTHER);
        let (
            user,
            mut user_membership
         ) = {
            let user = ts::take_from_sender<User>(
                scenario
            );
            let user_membership = ts::take_shared<UserMembership>(
                scenario
            );

            (user, user_membership)
        };

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                JOIN_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                JOIN_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::join(
                user_registry,
                user_membership_registry,
                &user,
                &mut user_membership,
                &user_fees,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            ts::return_shared(user_membership);

            ts::return_to_address(
                OTHER,
                user
            );

            destroy_for_testing(
                app,
                user_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                invite_config,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ENoSelfJoin)]
    fun test_user_actions_join_self() {
        let (
            mut scenario_val,
            app,
            mut user_registry_val,
            mut user_invite_registry_val,
            mut user_membership_registry_val,
            invite_config,
            user_fees
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
        let clock = {
            let clock: Clock = ts::take_shared(scenario);

            let name = utf8(b"user-name");

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            ); 

            let _user_address = user_actions::create(
                &clock,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                &user_fees,
                &invite_config,
                invite_code,
                invite_key,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            clock
        };

        ts::next_tx(scenario, ADMIN);
        let (
            user,
            mut user_membership
         ) = {
            let user = ts::take_from_sender<User>(
                scenario
            );
            let user_membership = ts::take_shared<UserMembership>(
                scenario
            );

            (user, user_membership)
        };

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                JOIN_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                JOIN_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::join(
                user_registry,
                user_membership_registry,
                &user,
                &mut user_membership,
                &user_fees,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            ts::return_shared(clock);
            ts::return_shared(user_membership);

            ts::return_to_address(
                OTHER,
                user
            );

            destroy_for_testing(
                app,
                user_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                invite_config,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EUserMembershipMismatch)]
    fun test_user_actions_join_mismatch() {
        let (
            mut scenario_val,
            app,
            mut user_registry_val,
            mut user_invite_registry_val,
            mut user_membership_registry_val,
            invite_config,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let user_registry = &mut user_registry_val;
        let user_invite_registry = &mut user_invite_registry_val;
        let user_membership_registry = &mut user_membership_registry_val;

        let invite_code = utf8(b"");
        let invite_key = utf8(b"");

        let other_name = utf8(b"other-name");

        ts::next_tx(scenario, OTHER);
        let (user_registry, user_membership_registry) = {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let _other_user_address = user_actions::create(
                &clock,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                &user_fees,
                &invite_config,
                invite_code,
                invite_key,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                other_name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);

            (user_registry, user_membership_registry)
        };

        ts::next_tx(scenario, OTHER);
        let user = {
            let user = ts::take_from_sender<User>(
                scenario
            );

            user
        };

        ts::next_tx(scenario, ADMIN);
        let clock = {
            let clock: Clock = ts::take_shared(scenario);

            let name = utf8(b"user-name");

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            ); 

            let _user_address = user_actions::create(
                &clock,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                &user_fees,
                &invite_config,
                invite_code,
                invite_key,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            clock
        };

        ts::next_tx(scenario, ADMIN);
        let mut user_membership = {
            let user_membership = ts::take_shared<UserMembership>(
                scenario
            );

            user_membership
        };

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                JOIN_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                JOIN_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::join(
                user_registry,
                user_membership_registry,
                &user,
                &mut user_membership,
                &user_fees,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            ts::return_shared(clock);
            ts::return_shared(user_membership);

            ts::return_to_address(
                OTHER,
                user
            );

            destroy_for_testing(
                app,
                user_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                invite_config,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_actions_leave() {
        let (
            mut scenario_val,
            app,
            mut user_registry_val,
            mut user_invite_registry_val,
            mut user_membership_registry_val,
            invite_config,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let user_registry = &mut user_registry_val;
        let user_invite_registry = &mut user_invite_registry_val;
        let user_membership_registry = &mut user_membership_registry_val;

        let invite_code = utf8(b"");
        let invite_key = utf8(b"");

        let other_name = utf8(b"other-name");

        ts::next_tx(scenario, OTHER);
        let (user_registry, user_membership_registry) = {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let _other_user_address = user_actions::create(
                &clock,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                &user_fees,
                &invite_config,
                invite_code,
                invite_key,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                other_name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);

            (user_registry, user_membership_registry)
        };

        ts::next_tx(scenario, OTHER);
        let (
            user,
            mut user_membership
         ) = {
            let user = ts::take_from_sender<User>(
                scenario
            );
            let user_membership = ts::take_shared<UserMembership>(
                scenario
            );

            (user, user_membership)
        };

        ts::next_tx(scenario, ADMIN);
        let clock = {
            let clock: Clock = ts::take_shared(scenario);

            let name = utf8(b"user-name");

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            ); 

            let _user_address = user_actions::create(
                &clock,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                &user_fees,
                &invite_config,
                invite_code,
                invite_key,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            clock
        };

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                JOIN_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                JOIN_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::join(
                user_registry,
                user_membership_registry,
                &user,
                &mut user_membership,
                &user_fees,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                LEAVE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                LEAVE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::leave(
                user_registry,
                user_membership_registry,
                &user,
                &mut user_membership,
                &user_fees,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let is_member = user_membership::is_member(
                &user_membership,
                ADMIN
            );

            assert!(!is_member, EUserMember);

            let member_length = user_membership::get_member_length(
                &user_membership
            );

            assert!(member_length == 0, EUserMembershipCountMismatch);

            ts::return_shared(clock);
            ts::return_shared(user_membership);

            ts::return_to_address(
                OTHER,
                user
            );

            destroy_for_testing(
                app,
                user_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                invite_config,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EUserMembershipMismatch)]
    fun test_user_actions_leave_mismatch() {
        let (
            mut scenario_val,
            app,
            mut user_registry_val,
            mut user_invite_registry_val,
            mut user_membership_registry_val,
            invite_config,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let user_registry = &mut user_registry_val;
        let user_invite_registry = &mut user_invite_registry_val;
        let user_membership_registry = &mut user_membership_registry_val;

        let invite_code = utf8(b"");
        let invite_key = utf8(b"");

        let other_name = utf8(b"other-name");

        ts::next_tx(scenario, ADMIN);
        {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);
        };

        ts::next_tx(scenario, OTHER);
        let clock = {
            let clock: Clock = ts::take_shared(scenario);

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let _other_user_address = user_actions::create(
                &clock,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                &user_fees,
                &invite_config,
                invite_code,
                invite_key,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                other_name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            clock
        };

        ts::next_tx(scenario, OTHER);
        let (
            other_user,
            mut other_user_membership
        ) = {
            let user = ts::take_from_sender<User>(
                scenario
            );
            let user_membership = ts::take_shared<UserMembership>(
                scenario
            );

            (user, user_membership)
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"user-name");

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            ); 

            let _user_address = user_actions::create(
                &clock,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                &user_fees,
                &invite_config,
                invite_code,
                invite_key,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                JOIN_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                JOIN_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::join(
                user_registry,
                user_membership_registry,
                &other_user,
                &mut other_user_membership,
                &user_fees,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        let (
            user,
            mut user_membership
        ) = {
            let user = ts::take_from_sender<User>(
                scenario
            );
            let user_membership = ts::take_shared<UserMembership>(
                scenario
            );

            (user, user_membership)
        };

        ts::next_tx(scenario, OTHER);
        {
            let custom_payment = mint_for_testing<SUI>(
                JOIN_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                JOIN_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::join(
                user_registry,
                user_membership_registry,
                &user,
                &mut user_membership,
                &user_fees,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                LEAVE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                LEAVE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::leave(
                user_registry,
                user_membership_registry,
                &user,
                &mut other_user_membership,
                &user_fees,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            ts::return_shared(clock);

            ts::return_shared(other_user_membership);
            ts::return_shared(user_membership);

            ts::return_to_address(
                OTHER,
                other_user
            );
            ts::return_to_address(
                ADMIN,
                user
            );

            destroy_for_testing(
                app,
                user_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                invite_config,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_invite_create() {
        let (
            mut scenario_val,
            app,
            mut user_registry_val,
            mut user_invite_registry_val,
            mut user_membership_registry_val,
            invite_config,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let user_registry = &mut user_registry_val;
        let user_invite_registry = &mut user_invite_registry_val;
        let user_membership_registry = &mut user_membership_registry_val;

        let invite_code = utf8(b"code");
        let invite_key = utf8(b"key");
        let invite_hash = b"hash";

        ts::next_tx(scenario, ADMIN);
        {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let clock: Clock = ts::take_shared(scenario);

            let _user_address = user_actions::create(
                &clock,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                &user_fees,
                &invite_config,
                utf8(b""),
                utf8(b""),
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                utf8(b"user-name"),
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(clock);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_INVITE_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_INVITE_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::create_invite(
                user_registry,
                user_invite_registry,
                &invite_config,
                &user_fees,
                invite_code,
                invite_hash,
                invite_key,
                custom_payment,
                sui_payment,
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
                app,
                user_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                invite_config
          ,
          user_fees  );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EUserDoesNotExist)]
    fun test_user_invite_create_no_user() {
        let (
            mut scenario_val,
            app,
            user_registry_val,
            mut user_invite_registry_val,
            user_membership_registry_val,
            invite_config,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let user_registry = &user_registry_val;
        let user_invite_registry = &mut user_invite_registry_val;

        let invite_code = utf8(b"code");
        let invite_key = utf8(b"key");
        let invite_hash = b"hash";

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_INVITE_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_INVITE_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::create_invite(
                user_registry,
                user_invite_registry,
                &invite_config,
                &user_fees,
                invite_code,
                invite_hash,
                invite_key,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                app,
                user_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                invite_config
          ,
          user_fees  );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInviteNotAllowed)]
    fun test_user_invite_create_not_allowed() {
        let (
            mut scenario_val,
            app,
            user_registry_val,
            mut user_invite_registry_val,
            user_membership_registry_val,
            mut invite_config,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let user_registry = &user_registry_val;
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
            let custom_payment = mint_for_testing<SUI>(
                CREATE_INVITE_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_INVITE_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::create_invite(
                user_registry,
                user_invite_registry,
                &invite_config,
                &user_fees,
                invite_code,
                invite_hash,
                invite_key,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                app,
                user_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                invite_config
          ,
          user_fees  );
        };

        ts::end(scenario_val);
    }

     #[test]
    fun test_user_invite_create_admin() {
        let (
            mut scenario_val,
            app,
            user_registry_val,
            mut user_invite_registry_val,
            user_membership_registry_val,
            invite_config,
            user_fees
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
                app,
                user_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                invite_config
          ,
          user_fees  );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_actions_update() {
        let (
            mut scenario_val,
            app,
            mut user_registry_val,
            mut user_invite_registry_val,
            mut user_membership_registry_val,
            mut invite_config,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

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
        let clock = {
            let clock: Clock = ts::take_shared(scenario);

            let avatar_hash = utf8(b"avatar_hash");
            let banner_hash = utf8(b"banner_hash");
            let description = utf8(b"description");
            let name = utf8(b"user-name");

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let _user_address = user_actions::create(
                &clock,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                &user_fees,
                &invite_config,
                utf8(b""),
                utf8(b""),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            clock
        };

        ts::next_tx(scenario, ADMIN);
        let (
            new_avatar_hash,
            new_banner_hash,
            new_description,
            new_name
        ) = {
            let new_avatar_hash = utf8(b"avatar_hash");
            let new_banner_hash = utf8(b"banner_hash");
            let new_description = utf8(b"description");
            let new_name = utf8(b"USER-name");

            let user = ts::take_from_sender<User>(
                scenario
            );

            let custom_payment = mint_for_testing<SUI>(
                UPDATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                UPDATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::update(
                &clock,
                user_registry,
                &user_fees,
                user,
                new_avatar_hash,
                new_banner_hash,
                new_description,
                new_name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            (
                new_avatar_hash,
                new_banner_hash,
                new_description,
                new_name
            )
        };

        ts::next_tx(scenario, ADMIN);
        {
            let user = ts::take_from_sender<User>(
                scenario
            );

            let user_request = user::create_user_request(user);

            let (retrieved_avatar, user_request) = user::get_avatar(
                user_request
            );
            let (retrieved_banner, user_request) = user::get_banner(
                user_request
            );
            let (retrieved_description, user_request) = user::get_description(
                user_request
            );
            let (retrieved_name, user_request) = user::get_name(
                user_request
            );

            assert!(retrieved_avatar == new_avatar_hash, EUserAvatarMismatch);
            assert!(retrieved_banner == new_banner_hash, EUserBannerMismatch);
            assert!(retrieved_description == new_description, EUserDescriptionMismatch);
            assert!(retrieved_name == new_name, ETestUserNameMismatch);

            user::destroy_user_request(user_request, ADMIN);

            ts::return_shared(clock);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                app,
                user_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                invite_config
          ,
          user_fees  );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EUserNameMismatch)]
    fun test_user_actions_update_name_self_mismatch() {
        let (
            mut scenario_val,
            app,
            mut user_registry_val,
            mut user_invite_registry_val,
            mut user_membership_registry_val,
            mut invite_config,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

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
        let clock = {
            let clock: Clock = ts::take_shared(scenario);

            let avatar_hash = utf8(b"avatar_hash");
            let banner_hash = utf8(b"banner_hash");
            let description = utf8(b"description");
            let name = utf8(b"user-name");

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let _user_address = user_actions::create(
                &clock,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                &user_fees,
                &invite_config,
                utf8(b""),
                utf8(b""),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            clock
        };

        ts::next_tx(scenario, ADMIN);
        {
            let new_avatar_hash = utf8(b"avatar_hash");
            let new_banner_hash = utf8(b"banner_hash");
            let new_description = utf8(b"description");
            let new_name = utf8(b"new-name");

            let user = ts::take_from_sender<User>(
                scenario
            );

            let custom_payment = mint_for_testing<SUI>(
                UPDATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                UPDATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::update(
                &clock,
                user_registry,
                &user_fees,
                user,
                new_avatar_hash,
                new_banner_hash,
                new_description,
                new_name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let user = ts::take_from_sender<User>(
                scenario
            );

            let user_request = user::create_user_request(user);

            let (retrieved_avatar, user_request) = user::get_avatar(
                user_request
            );
            let (retrieved_banner, user_request) = user::get_banner(
                user_request
            );
            let (retrieved_description, user_request) = user::get_description(
                user_request
            );
            let (retrieved_name, user_request) = user::get_name(
                user_request
            );

            assert!(retrieved_avatar == new_avatar_hash, EUserAvatarMismatch);
            assert!(retrieved_banner == new_banner_hash, EUserBannerMismatch);
            assert!(retrieved_description == new_description, EUserDescriptionMismatch);
            assert!(retrieved_name == new_name, ETestUserNameMismatch);

            user::destroy_user_request(user_request, ADMIN);

            ts::return_shared(clock);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                app,
                user_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                invite_config
          ,
          user_fees  );
        };

        ts::end(scenario_val);
    }
}
