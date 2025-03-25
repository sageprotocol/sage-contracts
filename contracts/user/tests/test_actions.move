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
        admin::{
            Self,
            AdminCap,
            FeeCap,
            InviteCap
        },
        authentication::{
            Self,
            AuthenticationConfig,
            InvalidAuthSoul,
            ValidAuthSoul,
            ENotAuthenticated
        },
        apps::{Self, App}
    };

    use sage_shared::{
        membership::{Self},
        posts::{Self}
    };

    use sage_user::{
        test_user_invite::{Self},
        user::{Self, User},
        user_actions::{
            Self,
            EInviteRequired,
            ENoSelfJoin,
            EUserNameMismatch
        },
        user_fees::{
            Self,
            UserFees,
            EIncorrectCustomPayment,
            EIncorrectSuiPayment
        },
        user_invite::{
            Self,
            InviteConfig,
            UserInviteRegistry,
            EInviteDoesNotExist,
            EInviteInvalid,
            EInviteNotAllowed
        },
        user_registry::{Self, UserRegistry}
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
    const POST_TO_USER_CUSTOM_FEE: u64 = 9;
    const POST_TO_USER_SUI_FEE: u64 = 10;
    const UPDATE_USER_CUSTOM_FEE: u64 = 11;
    const UPDATE_USER_SUI_FEE: u64 = 12;

    const INCORRECT_FEE: u64 = 100;

    // --------------- Errors ---------------

    const EHasMember: u64 = 0;
    const EHashMismatch: u64 = 1;
    const ENoInviteRecord: u64 = 2;
    const ENoPostsRecord: u64 = 3;
    const EPostsLengthMismatch: u64 = 4;
    const EUserAvatarMismatch: u64 = 5;
    const EUserBannerMismatch: u64 = 6;
    const EUserDescriptionMismatch: u64 = 7;
    const EUserKeyMismatch: u64 = 8;
    const EUserOwnerMismatch: u64 = 9;
    const EUserInviteMismatch: u64 = 10;
    const EUserMembershipCountMismatch: u64 = 11;
    const ETestUserNameMismatch: u64 = 12;
    const EUserNotMember: u64 = 13;

    // --------------- Test Functions ---------------

    #[test_only]
    fun destroy_for_testing(
        app: App,
        authentication_config: AuthenticationConfig,
        clock: Clock,
        invite_config: InviteConfig,
        soul: ValidAuthSoul,
        user_registry: UserRegistry,
        user_invite_registry: UserInviteRegistry,
        user_fees: UserFees
    ) {
        destroy(app);
        destroy(authentication_config);
        ts::return_shared(clock);
        destroy(invite_config);
        destroy(soul);
        destroy(user_registry);
        destroy(user_invite_registry);
        destroy(user_fees);
    }

    #[test_only]
    fun setup_for_testing(): (
        Scenario,
        App,
        AuthenticationConfig,
        Clock,
        InviteConfig,
        ValidAuthSoul,
        UserRegistry,
        UserInviteRegistry,
        UserFees
    ) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
            apps::init_for_testing(ts::ctx(scenario));
            authentication::init_for_testing(ts::ctx(scenario));
            user_invite::init_for_testing(ts::ctx(scenario));
            user_registry::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);
        };

        ts::next_tx(scenario, ADMIN);
        let (
            app,
            authentication_config,
            clock,
            invite_config,
            soul,
            user_registry,
            user_invite_registry
        ) = {
            let invite_config = scenario.take_shared<InviteConfig>();
            let user_registry = scenario.take_shared<UserRegistry>();
            let user_invite_registry = scenario.take_shared<UserInviteRegistry>();

            let mut app = apps::create_for_testing(
                utf8(b"sage"),
                ts::ctx(scenario)
            );

            let mut authentication_config = scenario.take_shared<AuthenticationConfig>();

            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            authentication::update_soul<ValidAuthSoul>(
                &admin_cap,
                &mut authentication_config
            );

            let clock = ts::take_shared<Clock>(scenario);

            let soul = authentication::create_valid_auth_soul(
                ts::ctx(scenario)
            );

            user_fees::create<SUI>(
                &fee_cap,
                &mut app,
                CREATE_INVITE_CUSTOM_FEE,
                CREATE_INVITE_SUI_FEE,
                CREATE_USER_CUSTOM_FEE,
                CREATE_USER_SUI_FEE,
                JOIN_USER_CUSTOM_FEE,
                JOIN_USER_SUI_FEE,
                LEAVE_USER_CUSTOM_FEE,
                LEAVE_USER_SUI_FEE,
                POST_TO_USER_CUSTOM_FEE,
                POST_TO_USER_SUI_FEE,
                UPDATE_USER_CUSTOM_FEE,
                UPDATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, admin_cap);
            ts::return_to_sender(scenario, fee_cap);

            (
                app,
                authentication_config,
                clock,
                invite_config,
                soul,
                user_registry,
                user_invite_registry
            )
        };

        ts::next_tx(scenario, ADMIN);
        let user_fees = {
            let user_fees = ts::take_shared<UserFees>(scenario);

            user_fees
        };

        (
            scenario_val,
            app,
            authentication_config,
            clock,
            invite_config,
            soul,
            user_registry,
            user_invite_registry,
            user_fees
        )
    }

    #[test]
    fun test_user_actions_init() {
        let (
            mut scenario_val,
            app,
            authentication_config,
            clock,
            invite_config,
            soul,
            user_registry,
            user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                app,
                authentication_config,
                clock,
                invite_config,
                soul,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_actions_create_no_invite() {
        let (
            mut scenario_val,
            app,
            authentication_config,
            clock,
            invite_config,
            soul,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar_hash = utf8(b"avatar_hash");
        let banner_hash = utf8(b"banner_hash");
        let description = utf8(b"description");
        let name = utf8(b"USER-name");

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

            let _user_address = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let has_member = user_registry::has_address_record(
                &user_registry,
                ADMIN
            );

            assert!(has_member, EHasMember);

            let has_member = user_registry::has_username_record(
                &user_registry,
                name
            );

            assert!(has_member, EHasMember);

            let user = ts::take_shared<User>(scenario);

            let retrieved_avatar = user::get_avatar(&user);
            assert!(retrieved_avatar == avatar_hash, EUserAvatarMismatch);

            let retrieved_banner = user::get_banner(&user);
            assert!(retrieved_banner == banner_hash, EUserBannerMismatch);

            let retrieved_description = user::get_description(&user);
            assert!(retrieved_description == description, EUserDescriptionMismatch);

            let retrieved_owner = user::get_owner(&user);
            assert!(retrieved_owner == ADMIN, EUserOwnerMismatch);

            let retrieved_key = user::get_key(&user);
            assert!(retrieved_key == utf8(b"user-name"), EUserKeyMismatch);

            let retrieved_name = user::get_name(&user);
            assert!(retrieved_name == name, ETestUserNameMismatch);

            ts::return_shared(user);

            destroy_for_testing(
                app,
                authentication_config,
                clock,
                invite_config,
                soul,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_actions_create_with_invite() {
        let (
            mut scenario_val,
            app,
            authentication_config,
            clock,
            invite_config,
            soul,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar_hash = utf8(b"avatar_hash");
        let banner_hash = utf8(b"banner_hash");
        let description = utf8(b"description");
        let name = utf8(b"USER-name");

        let invite_code = utf8(b"code");
        let invite_key = utf8(b"key");
        let invite_hash = test_user_invite::create_hash_array(
            b"d49b047aaca5fd3e37ea3be6311e68fc918e7e16bd31bfcd24c44ba5c938e94a"
        );

        ts::next_tx(scenario, SERVER);
        {
            user_invite::create_invite(
                &mut user_invite_registry,
                invite_hash,
                invite_key,
                SERVER
            );
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

            let _user_address = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::some(invite_code),
                option::some(invite_key),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let has_member = user_registry::has_address_record(
                &user_registry,
                ADMIN
            );

            assert!(has_member, EHasMember);

            let has_member = user_registry::has_username_record(
                &user_registry,
                name
            );

            assert!(has_member, EHasMember);

            let user = ts::take_shared<User>(scenario);

            let retrieved_avatar = user::get_avatar(&user);
            assert!(retrieved_avatar == avatar_hash, EUserAvatarMismatch);

            let retrieved_banner = user::get_banner(&user);
            assert!(retrieved_banner == banner_hash, EUserBannerMismatch);

            let retrieved_description = user::get_description(&user);
            assert!(retrieved_description == description, EUserDescriptionMismatch);

            let retrieved_owner = user::get_owner(&user);
            assert!(retrieved_owner == ADMIN, EUserOwnerMismatch);

            let retrieved_key = user::get_key(&user);
            assert!(retrieved_key == utf8(b"user-name"), EUserKeyMismatch);

            let retrieved_name = user::get_name(&user);
            assert!(retrieved_name == name, ETestUserNameMismatch);

            ts::return_shared(user);

            destroy_for_testing(
                app,
                authentication_config,
                clock,
                invite_config,
                soul,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInviteRequired)]
    fun test_user_actions_create_invite_required_not_included() {
        let (
            mut scenario_val,
            app,
            authentication_config,
            clock,
            mut invite_config,
            soul,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar_hash = utf8(b"avatar_hash");
        let banner_hash = utf8(b"banner_hash");
        let description = utf8(b"description");
        let name = utf8(b"USER-name");

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
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let _user_address = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            destroy_for_testing(
                app,
                authentication_config,
                clock,
                invite_config,
                soul,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInviteDoesNotExist)]
    fun test_user_actions_create_invite_dne() {
        let (
            mut scenario_val,
            app,
            authentication_config,
            clock,
            invite_config,
            soul,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar_hash = utf8(b"avatar_hash");
        let banner_hash = utf8(b"banner_hash");
        let description = utf8(b"description");
        let name = utf8(b"USER-name");

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

            let _user_address = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::some(utf8(b"code")),
                option::some(utf8(b"key")),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            destroy_for_testing(
                app,
                authentication_config,
                clock,
                invite_config,
                soul,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInviteInvalid)]
    fun test_user_actions_create_invite_invalid() {
        let (
            mut scenario_val,
            app,
            authentication_config,
            clock,
            invite_config,
            soul,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar_hash = utf8(b"avatar_hash");
        let banner_hash = utf8(b"banner_hash");
        let description = utf8(b"description");
        let name = utf8(b"USER-name");

        let invite_code = utf8(b"");
        let invite_key = utf8(b"key");
        let invite_hash = test_user_invite::create_hash_array(
            b"d49b047aaca5fd3e37ea3be6311e68fc918e7e16bd31bfcd24c44ba5c938e94a"
        );

        ts::next_tx(scenario, SERVER);
        {
            user_invite::create_invite(
                &mut user_invite_registry,
                invite_hash,
                invite_key,
                SERVER
            );
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

            let _user_address = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::some(invite_code),
                option::some(invite_key),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            destroy_for_testing(
                app,
                authentication_config,
                clock,
                invite_config,
                soul,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_user_actions_create_incorrect_custom_payment() {
        let (
            mut scenario_val,
            app,
            authentication_config,
            clock,
            invite_config,
            soul,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar_hash = utf8(b"avatar_hash");
        let banner_hash = utf8(b"banner_hash");
        let description = utf8(b"description");
        let name = utf8(b"USER-name");

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let _user_address = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            destroy_for_testing(
                app,
                authentication_config,
                clock,
                invite_config,
                soul,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_user_actions_create_incorrect_sui_payment() {
        let (
            mut scenario_val,
            app,
            authentication_config,
            clock,
            invite_config,
            soul,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar_hash = utf8(b"avatar_hash");
        let banner_hash = utf8(b"banner_hash");
        let description = utf8(b"description");
        let name = utf8(b"USER-name");

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            let _user_address = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            destroy_for_testing(
                app,
                authentication_config,
                clock,
                invite_config,
                soul,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_actions_invite_create() {
        let (
            mut scenario_val,
            app,
            authentication_config,
            clock,
            invite_config,
            soul,
            user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

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

            user_actions::create_invite<SUI, ValidAuthSoul>(
                &authentication_config,
                &invite_config,
                &user_fees,
                &mut user_invite_registry,
                &soul,
                invite_code,
                invite_hash,
                invite_key,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let has_record = user_invite::has_record(
                &user_invite_registry,
                invite_key
            );

            assert!(has_record, ENoInviteRecord);

            let (hash, user) = user_invite::get_destructured_invite(
                &user_invite_registry,
                invite_key
            );

            assert!(hash == invite_hash, EHashMismatch);
            assert!(user == ADMIN, EUserInviteMismatch);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                app,
                authentication_config,
                clock,
                invite_config,
                soul,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ENotAuthenticated)]
    fun test_user_actions_invite_create_auth_fail() {
        let (
            mut scenario_val,
            app,
            authentication_config,
            clock,
            invite_config,
            soul,
            user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

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

            let invalid_soul = authentication::create_invalid_auth_soul(
                ts::ctx(scenario)
            );

            user_actions::create_invite<SUI, InvalidAuthSoul>(
                &authentication_config,
                &invite_config,
                &user_fees,
                &mut user_invite_registry,
                &invalid_soul,
                invite_code,
                invite_hash,
                invite_key,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            destroy(invalid_soul);

            destroy_for_testing(
                app,
                authentication_config,
                clock,
                invite_config,
                soul,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_user_actions_invite_create_incorrect_custom_payment() {
        let (
            mut scenario_val,
            app,
            authentication_config,
            clock,
            invite_config,
            soul,
            user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let invite_code = utf8(b"code");
        let invite_key = utf8(b"key");
        let invite_hash = b"hash";

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_INVITE_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::create_invite<SUI, ValidAuthSoul>(
                &authentication_config,
                &invite_config,
                &user_fees,
                &mut user_invite_registry,
                &soul,
                invite_code,
                invite_hash,
                invite_key,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            destroy_for_testing(
                app,
                authentication_config,
                clock,
                invite_config,
                soul,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_user_actions_invite_create_incorrect_sui_payment() {
        let (
            mut scenario_val,
            app,
            authentication_config,
            clock,
            invite_config,
            soul,
            user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

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
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            user_actions::create_invite<SUI, ValidAuthSoul>(
                &authentication_config,
                &invite_config,
                &user_fees,
                &mut user_invite_registry,
                &soul,
                invite_code,
                invite_hash,
                invite_key,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            destroy_for_testing(
                app,
                authentication_config,
                clock,
                invite_config,
                soul,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInviteNotAllowed)]
    fun test_user_actions_invite_create_not_allowed() {
        let (
            mut scenario_val,
            app,
            authentication_config,
            clock,
            mut invite_config,
            soul,
            user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

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

            user_actions::create_invite<SUI, ValidAuthSoul>(
                &authentication_config,
                &invite_config,
                &user_fees,
                &mut user_invite_registry,
                &soul,
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
                authentication_config,
                clock,
                invite_config,
                soul,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_actions_invite_create_admin() {
        let (
            mut scenario_val,
            app,
            authentication_config,
            clock,
            invite_config,
            soul,
            user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let invite_key = utf8(b"key");
        let invite_hash = b"hash";

        ts::next_tx(scenario, SERVER);
        {
            let invite_cap = ts::take_from_sender<InviteCap>(scenario);

            user_actions::create_invite_admin(
                &invite_cap,
                &mut user_invite_registry,
                invite_hash,
                invite_key,
                OTHER
            );

            let has_record = user_invite::has_record(
                &user_invite_registry,
                invite_key
            );

            assert!(has_record, ENoInviteRecord);

            let (hash, user) = user_invite::get_destructured_invite(
                &user_invite_registry,
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
                authentication_config,
                clock,
                invite_config,
                soul,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_actions_follows() {
        let (
            mut scenario_val,
            app,
            authentication_config,
            clock,
            invite_config,
            soul,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar_hash = utf8(b"avatar_hash");
        let banner_hash = utf8(b"banner_hash");
        let description = utf8(b"description");

        ts::next_tx(scenario, OTHER);
        {
            let name = utf8(b"other-name");

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let _other_user_address = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut other_user = ts::take_shared<User>(scenario);

            let name = utf8(b"user-name");

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let _user_address = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                JOIN_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                JOIN_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::join<SUI, ValidAuthSoul>(
                &authentication_config,
                &clock,
                &soul,
                &mut other_user,
                &user_fees,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let follows = user::borrow_follows_mut(&mut other_user);

            let is_member = membership::is_member(
                follows,
                ADMIN
            );

            assert!(is_member, EUserNotMember);

            let member_length = membership::get_length(
                follows
            );

            assert!(member_length == 1, EUserMembershipCountMismatch);

            let custom_payment = mint_for_testing<SUI>(
                LEAVE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                LEAVE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::leave<SUI>(
                &clock,
                &mut other_user,
                &user_fees,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let membership = user::borrow_follows_mut(&mut other_user);

            let is_member = membership::is_member(
                membership,
                ADMIN
            );

            assert!(!is_member, EUserNotMember);

            let member_length = membership::get_length(
                membership
            );

            assert!(member_length == 0, EUserMembershipCountMismatch);

            ts::return_shared(other_user);

            destroy_for_testing(
                app,
                authentication_config,
                clock,
                invite_config,
                soul,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ENotAuthenticated)]
    fun test_user_actions_join_auth_fail() {
        let (
            mut scenario_val,
            app,
            authentication_config,
            clock,
            invite_config,
            soul,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar_hash = utf8(b"avatar_hash");
        let banner_hash = utf8(b"banner_hash");
        let description = utf8(b"description");

        ts::next_tx(scenario, OTHER);
        {
            let name = utf8(b"other-name");

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let _other_user_address = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut other_user = ts::take_shared<User>(scenario);

            let name = utf8(b"user-name");

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let _user_address = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                JOIN_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                JOIN_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let invalid_soul = authentication::create_invalid_auth_soul(
                ts::ctx(scenario)
            );

            user_actions::join<SUI, InvalidAuthSoul>(
                &authentication_config,
                &clock,
                &invalid_soul,
                &mut other_user,
                &user_fees,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            destroy(invalid_soul);
            ts::return_shared(other_user);

            destroy_for_testing(
                app,
                authentication_config,
                clock,
                invite_config,
                soul,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_user_actions_join_incorrect_custom_payment() {
        let (
            mut scenario_val,
            app,
            authentication_config,
            clock,
            invite_config,
            soul,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar_hash = utf8(b"avatar_hash");
        let banner_hash = utf8(b"banner_hash");
        let description = utf8(b"description");

        ts::next_tx(scenario, OTHER);
        {
            let name = utf8(b"other-name");

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let _other_user_address = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut other_user = ts::take_shared<User>(scenario);

            let name = utf8(b"user-name");

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let _user_address = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                JOIN_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::join<SUI, ValidAuthSoul>(
                &authentication_config,
                &clock,
                &soul,
                &mut other_user,
                &user_fees,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(other_user);

            destroy_for_testing(
                app,
                authentication_config,
                clock,
                invite_config,
                soul,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_user_actions_join_incorrect_sui_payment() {
        let (
            mut scenario_val,
            app,
            authentication_config,
            clock,
            invite_config,
            soul,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar_hash = utf8(b"avatar_hash");
        let banner_hash = utf8(b"banner_hash");
        let description = utf8(b"description");

        ts::next_tx(scenario, OTHER);
        {
            let name = utf8(b"other-name");

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let _other_user_address = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut other_user = ts::take_shared<User>(scenario);

            let name = utf8(b"user-name");

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let _user_address = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                JOIN_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            user_actions::join<SUI, ValidAuthSoul>(
                &authentication_config,
                &clock,
                &soul,
                &mut other_user,
                &user_fees,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(other_user);

            destroy_for_testing(
                app,
                authentication_config,
                clock,
                invite_config,
                soul,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ENoSelfJoin)]
    fun test_user_actions_join_no_self() {
        let (
            mut scenario_val,
            app,
            authentication_config,
            clock,
            invite_config,
            soul,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar_hash = utf8(b"avatar_hash");
        let banner_hash = utf8(b"banner_hash");
        let description = utf8(b"description");

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

            let _user_address = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut user = ts::take_shared<User>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                JOIN_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                JOIN_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::join<SUI, ValidAuthSoul>(
                &authentication_config,
                &clock,
                &soul,
                &mut user,
                &user_fees,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(user);

            destroy_for_testing(
                app,
                authentication_config,
                clock,
                invite_config,
                soul,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_user_actions_leave_incorrect_custom_payment() {
        let (
            mut scenario_val,
            app,
            authentication_config,
            clock,
            invite_config,
            soul,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar_hash = utf8(b"avatar_hash");
        let banner_hash = utf8(b"banner_hash");
        let description = utf8(b"description");

        ts::next_tx(scenario, OTHER);
        {
            let name = utf8(b"other-name");

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let _other_user_address = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut other_user = ts::take_shared<User>(scenario);

            let name = utf8(b"user-name");

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let _user_address = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                JOIN_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                JOIN_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::join<SUI, ValidAuthSoul>(
                &authentication_config,
                &clock,
                &soul,
                &mut other_user,
                &user_fees,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                LEAVE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::leave<SUI>(
                &clock,
                &mut other_user,
                &user_fees,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(other_user);

            destroy_for_testing(
                app,
                authentication_config,
                clock,
                invite_config,
                soul,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_user_actions_leave_incorrect_sui_payment() {
        let (
            mut scenario_val,
            app,
            authentication_config,
            clock,
            invite_config,
            soul,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar_hash = utf8(b"avatar_hash");
        let banner_hash = utf8(b"banner_hash");
        let description = utf8(b"description");

        ts::next_tx(scenario, OTHER);
        {
            let name = utf8(b"other-name");

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let _other_user_address = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut other_user = ts::take_shared<User>(scenario);

            let name = utf8(b"user-name");

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let _user_address = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                JOIN_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                JOIN_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::join<SUI, ValidAuthSoul>(
                &authentication_config,
                &clock,
                &soul,
                &mut other_user,
                &user_fees,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                LEAVE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            user_actions::leave<SUI>(
                &clock,
                &mut other_user,
                &user_fees,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(other_user);

            destroy_for_testing(
                app,
                authentication_config,
                clock,
                invite_config,
                soul,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_actions_post() {
        let (
            mut scenario_val,
            app,
            authentication_config,
            clock,
            invite_config,
            soul,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar_hash = utf8(b"avatar_hash");
        let banner_hash = utf8(b"banner_hash");
        let description = utf8(b"description");
        let name = utf8(b"USER-name");

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

            let _user_address = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut user = ts::take_shared<User>(scenario);

            let data = utf8(b"data");
            let description = utf8(b"description");
            let title = utf8(b"title");

            let custom_payment = mint_for_testing<SUI>(
                POST_TO_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                POST_TO_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let (
                _post_address,
                timestamp
            ) = user_actions::post<SUI, ValidAuthSoul>(
                &app,
                &authentication_config,
                &clock,
                &soul,
                &mut user,
                &user_fees,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let posts = user::borrow_posts_mut(&mut user);

            let has_record = posts::has_record(
                posts,
                timestamp
            );

            assert!(has_record, ENoPostsRecord);

            let length = posts::get_length(posts);

            assert!(length == 1, EPostsLengthMismatch);

            ts::return_shared(user);

            destroy_for_testing(
                app,
                authentication_config,
                clock,
                invite_config,
                soul,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ENotAuthenticated)]
    fun test_user_actions_post_auth_fail() {
        let (
            mut scenario_val,
            app,
            authentication_config,
            clock,
            invite_config,
            soul,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar_hash = utf8(b"avatar_hash");
        let banner_hash = utf8(b"banner_hash");
        let description = utf8(b"description");
        let name = utf8(b"USER-name");

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

            let _user_address = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut user = ts::take_shared<User>(scenario);

            let data = utf8(b"data");
            let description = utf8(b"description");
            let title = utf8(b"title");

            let custom_payment = mint_for_testing<SUI>(
                POST_TO_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                POST_TO_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let invalid_soul = authentication::create_invalid_auth_soul(
                ts::ctx(scenario)
            );

            let (
                _post_address,
                _timestamp
            ) = user_actions::post<SUI, InvalidAuthSoul>(
                &app,
                &authentication_config,
                &clock,
                &invalid_soul,
                &mut user,
                &user_fees,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            destroy(invalid_soul);
            ts::return_shared(user);

            destroy_for_testing(
                app,
                authentication_config,
                clock,
                invite_config,
                soul,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_user_actions_post_incorrect_custom_payment() {
        let (
            mut scenario_val,
            app,
            authentication_config,
            clock,
            invite_config,
            soul,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar_hash = utf8(b"avatar_hash");
        let banner_hash = utf8(b"banner_hash");
        let description = utf8(b"description");
        let name = utf8(b"USER-name");

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

            let _user_address = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut user = ts::take_shared<User>(scenario);

            let data = utf8(b"data");
            let description = utf8(b"description");
            let title = utf8(b"title");

            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                POST_TO_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let (
                _post_address,
                _timestamp
            ) = user_actions::post<SUI, ValidAuthSoul>(
                &app,
                &authentication_config,
                &clock,
                &soul,
                &mut user,
                &user_fees,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(user);

            destroy_for_testing(
                app,
                authentication_config,
                clock,
                invite_config,
                soul,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_user_actions_post_incorrect_sui_payment() {
        let (
            mut scenario_val,
            app,
            authentication_config,
            clock,
            invite_config,
            soul,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar_hash = utf8(b"avatar_hash");
        let banner_hash = utf8(b"banner_hash");
        let description = utf8(b"description");
        let name = utf8(b"USER-name");

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

            let _user_address = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut user = ts::take_shared<User>(scenario);

            let data = utf8(b"data");
            let description = utf8(b"description");
            let title = utf8(b"title");

            let custom_payment = mint_for_testing<SUI>(
                POST_TO_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            let (
                _post_address,
                _timestamp
            ) = user_actions::post<SUI, ValidAuthSoul>(
                &app,
                &authentication_config,
                &clock,
                &soul,
                &mut user,
                &user_fees,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(user);

            destroy_for_testing(
                app,
                authentication_config,
                clock,
                invite_config,
                soul,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_actions_update() {
        let (
            mut scenario_val,
            app,
            authentication_config,
            clock,
            mut invite_config,
            soul,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

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

            let _user_address = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let new_avatar_hash = utf8(b"avatar_hash");
            let new_banner_hash = utf8(b"banner_hash");
            let new_description = utf8(b"description");
            let new_name = utf8(b"USER-name");

            let mut user = ts::take_shared<User>(
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

            user_actions::update<SUI>(
                &clock,
                &user_registry,
                &user_fees,
                &mut user,
                new_avatar_hash,
                new_banner_hash,
                new_description,
                new_name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let retrieved_avatar = user::get_avatar(&user);
            assert!(retrieved_avatar == new_avatar_hash, EUserAvatarMismatch);

            let retrieved_banner = user::get_banner(&user);
            assert!(retrieved_banner == new_banner_hash, EUserBannerMismatch);

            let retrieved_description = user::get_description(&user);
            assert!(retrieved_description == new_description, EUserDescriptionMismatch);

            let retrieved_key = user::get_key(&user);
            assert!(retrieved_key == utf8(b"user-name"), EUserKeyMismatch);

            let retrieved_name = user::get_name(&user);
            assert!(retrieved_name == new_name, ETestUserNameMismatch);

            ts::return_shared(user);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                app,
                authentication_config,
                clock,
                invite_config,
                soul,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_user_actions_update_incorrect_custom_payment() {
        let (
            mut scenario_val,
            app,
            authentication_config,
            clock,
            mut invite_config,
            soul,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

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

            let _user_address = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let new_avatar_hash = utf8(b"avatar_hash");
            let new_banner_hash = utf8(b"banner_hash");
            let new_description = utf8(b"description");
            let new_name = utf8(b"USER-name");

            let mut user = ts::take_shared<User>(
                scenario
            );

            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                UPDATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::update<SUI>(
                &clock,
                &user_registry,
                &user_fees,
                &mut user,
                new_avatar_hash,
                new_banner_hash,
                new_description,
                new_name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(user);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                app,
                authentication_config,
                clock,
                invite_config,
                soul,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_user_actions_update_incorrect_sui_payment() {
        let (
            mut scenario_val,
            app,
            authentication_config,
            clock,
            mut invite_config,
            soul,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

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

            let _user_address = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let new_avatar_hash = utf8(b"avatar_hash");
            let new_banner_hash = utf8(b"banner_hash");
            let new_description = utf8(b"description");
            let new_name = utf8(b"USER-name");

            let mut user = ts::take_shared<User>(
                scenario
            );

            let custom_payment = mint_for_testing<SUI>(
                UPDATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            user_actions::update<SUI>(
                &clock,
                &user_registry,
                &user_fees,
                &mut user,
                new_avatar_hash,
                new_banner_hash,
                new_description,
                new_name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(user);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                app,
                authentication_config,
                clock,
                invite_config,
                soul,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EUserNameMismatch)]
    fun test_user_actions_update_name_mismatch() {
        let (
            mut scenario_val,
            app,
            authentication_config,
            clock,
            mut invite_config,
            soul,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

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

            let _user_address = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let new_avatar_hash = utf8(b"avatar_hash");
            let new_banner_hash = utf8(b"banner_hash");
            let new_description = utf8(b"description");
            let new_name = utf8(b"different");

            let mut user = ts::take_shared<User>(
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

            user_actions::update<SUI>(
                &clock,
                &user_registry,
                &user_fees,
                &mut user,
                new_avatar_hash,
                new_banner_hash,
                new_description,
                new_name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(user);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                app,
                authentication_config,
                clock,
                invite_config,
                soul,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EUserNameMismatch)]
    fun test_user_actions_update_owner_mismatch() {
        let (
            mut scenario_val,
            app,
            authentication_config,
            clock,
            mut invite_config,
            soul,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

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

            let _user_address = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, OTHER);
        {
            let avatar_hash = utf8(b"avatar_hash");
            let banner_hash = utf8(b"banner_hash");
            let description = utf8(b"description");
            let name = utf8(b"other-name");

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let _user_address = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar_hash,
                banner_hash,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, OTHER);
        {
            let new_avatar_hash = utf8(b"avatar_hash");
            let new_banner_hash = utf8(b"banner_hash");
            let new_description = utf8(b"description");
            let new_name = utf8(b"USER-name");

            let mut user = ts::take_shared<User>(
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

            user_actions::update<SUI>(
                &clock,
                &user_registry,
                &user_fees,
                &mut user,
                new_avatar_hash,
                new_banner_hash,
                new_description,
                new_name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(user);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                app,
                authentication_config,
                clock,
                invite_config,
                soul,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }
}
