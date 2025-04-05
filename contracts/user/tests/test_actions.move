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
        apps::{Self, App},
        types::{
            Self,
            ChannelConfig,
            UserOwnedConfig,
            ETypeMismatch
        }
    };

    use sage_shared::{
        membership::{Self},
        posts::{Self}
    };

    use sage_user::{
        test_user_invite::{Self},
        user_actions::{
            Self,
            EInvalidUserDescription,
            EInvalidUsername,
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
        user_owned::{Self, UserOwned},
        user_registry::{Self, UserRegistry},
        user_shared::{Self, UserShared}
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

    const EDescriptionInvalid: u64 = 0;
    const EFavoritesMismatch: u64 = 1;
    const EHasMember: u64 = 2;
    const EHashMismatch: u64 = 3;
    const ENoInviteRecord: u64 = 4;
    const ENoPostsRecord: u64 = 5;
    const EPostsLengthMismatch: u64 = 6;
    const EUserAddressMismatch: u64 = 7;
    const EUserAvatarMismatch: u64 = 8;
    const EUserBannerMismatch: u64 = 9;
    const EUserDescriptionMismatch: u64 = 10;
    const EUserKeyMismatch: u64 = 11;
    const EUserOwnerMismatch: u64 = 12;
    const EUserInviteMismatch: u64 = 13;
    const EUserMembershipCountMismatch: u64 = 14;
    const ETestUserNameMismatch: u64 = 15;
    const EUserNotMember: u64 = 16;

    // --------------- Name Tag ---------------

    public struct InvalidChannel has key {
        id: UID
    }

    public struct ValidChannel has key {
        id: UID
    }

    // --------------- Test Functions ---------------

    #[test_only]
    fun destroy_for_testing(
        app: App,
        clock: Clock,
        invite_config: InviteConfig,
        owned_user_config: UserOwnedConfig,
        user_registry: UserRegistry,
        user_invite_registry: UserInviteRegistry,
        user_fees: UserFees
    ) {
        destroy(app);
        ts::return_shared(clock);
        destroy(invite_config);
        destroy(owned_user_config);
        destroy(user_registry);
        destroy(user_invite_registry);
        destroy(user_fees);
    }

    #[test_only]
    fun setup_for_testing(): (
        Scenario,
        App,
        Clock,
        InviteConfig,
        UserOwnedConfig,
        UserRegistry,
        UserInviteRegistry,
        UserFees
    ) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
            apps::init_for_testing(ts::ctx(scenario));
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
            clock,
            invite_config,
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

            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            let clock = ts::take_shared<Clock>(scenario);

            types::create_owned_user_config<UserOwned>(
                &admin_cap,
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
                clock,
                invite_config,
                user_registry,
                user_invite_registry
            )
        };

        ts::next_tx(scenario, ADMIN);
        let (
            owned_user_config,
            user_fees
         ) = {
            let owned_user_config = ts::take_shared<UserOwnedConfig>(scenario);
            let user_fees = ts::take_shared<UserFees>(scenario);

            (
                owned_user_config,
                user_fees
            )
        };

        (
            scenario_val,
            app,
            clock,
            invite_config,
            owned_user_config,
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
            clock,
            invite_config,
            owned_user_config,
            user_registry,
            user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_assert_description_pass() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let description = utf8(b"description");

            user_actions::assert_user_description(&description);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidUserDescription)]
    fun test_user_assert_description_fail() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let description = utf8(b"abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefg");

            user_actions::assert_user_description(&description);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_assert_name_pass() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"name");

            user_actions::assert_user_name(&name);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidUsername)]
    fun test_user_assert_name_format_fail() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"USERname-");

            user_actions::assert_user_name(&name);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidUsername)]
    fun test_user_assert_name_length_fail() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"USERnameUSERnameUSERn");

            user_actions::assert_user_name(&name);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidUsername)]
    fun test_user_assert_name_symbol_fail() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"USER*name");

            user_actions::assert_user_name(&name);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_actions_create_no_invite() {
        let (
            mut scenario_val,
            app,
            clock,
            invite_config,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let key = utf8(b"user-name");
        let name = utf8(b"USER-name");

        ts::next_tx(scenario, ADMIN);
        let (
            owned_user_address,
            shared_user_address
        ) = {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let (
                owned_user_address,
                shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            (
                owned_user_address,
                shared_user_address
            )
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

            let retrieved_owned_user_address = user_registry::get_owned_user_address_from_key(
                &user_registry,
                key
            );

            let retrieved_shared_user_address = user_registry::get_shared_user_address_from_key(
                &user_registry,
                key
            );

            assert!(retrieved_owned_user_address == owned_user_address, EUserAddressMismatch);
            assert!(retrieved_shared_user_address == shared_user_address, EUserAddressMismatch);

            let owned_user = ts::take_from_sender<UserOwned>(scenario);

            let retrieved_avatar = user_owned::get_avatar(&owned_user);
            assert!(retrieved_avatar == avatar, EUserAvatarMismatch);

            let retrieved_banner = user_owned::get_banner(&owned_user);
            assert!(retrieved_banner == banner, EUserBannerMismatch);

            let retrieved_description = user_owned::get_description(&owned_user);
            assert!(retrieved_description == description, EUserDescriptionMismatch);

            let retrieved_owner = user_owned::get_owner(&owned_user);
            assert!(retrieved_owner == ADMIN, EUserOwnerMismatch);

            let retrieved_key = user_owned::get_key(&owned_user);
            assert!(retrieved_key == utf8(b"user-name"), EUserKeyMismatch);

            let retrieved_name = user_owned::get_name(&owned_user);
            assert!(retrieved_name == name, ETestUserNameMismatch);

            let retrieved_shared_user_address = user_owned::get_shared_user(&owned_user);
            assert!(retrieved_shared_user_address == shared_user_address, EUserAddressMismatch);

            let shared_user = ts::take_shared<UserShared>(scenario);

            let retrieved_owner = user_shared::get_owner(&shared_user);
            assert!(retrieved_owner == ADMIN, EUserOwnerMismatch);

            let retrieved_key = user_shared::get_key(&shared_user);
            assert!(retrieved_key == utf8(b"user-name"), EUserKeyMismatch);

            let retrieved_owned_user_address = user_shared::get_owned_user(&shared_user);
            assert!(retrieved_owned_user_address == owned_user_address, EUserAddressMismatch);

            ts::return_to_sender(scenario, owned_user);
            ts::return_shared(shared_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
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
            clock,
            invite_config,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let key = utf8(b"user-name");
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
        let (
            owned_user_address,
            shared_user_address
        ) = {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let (
                owned_user_address,
                shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::some(invite_code),
                option::some(invite_key),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            (
                owned_user_address,
                shared_user_address
            )
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

            let retrieved_owned_user_address = user_registry::get_owned_user_address_from_key(
                &user_registry,
                key
            );

            let retrieved_shared_user_address = user_registry::get_shared_user_address_from_key(
                &user_registry,
                key
            );

            assert!(retrieved_owned_user_address == owned_user_address, EUserAddressMismatch);
            assert!(retrieved_shared_user_address == shared_user_address, EUserAddressMismatch);

            let owned_user = ts::take_from_sender<UserOwned>(scenario);

            let retrieved_avatar = user_owned::get_avatar(&owned_user);
            assert!(retrieved_avatar == avatar, EUserAvatarMismatch);

            let retrieved_banner = user_owned::get_banner(&owned_user);
            assert!(retrieved_banner == banner, EUserBannerMismatch);

            let retrieved_description = user_owned::get_description(&owned_user);
            assert!(retrieved_description == description, EUserDescriptionMismatch);

            let retrieved_owner = user_owned::get_owner(&owned_user);
            assert!(retrieved_owner == ADMIN, EUserOwnerMismatch);

            let retrieved_key = user_owned::get_key(&owned_user);
            assert!(retrieved_key == utf8(b"user-name"), EUserKeyMismatch);

            let retrieved_name = user_owned::get_name(&owned_user);
            assert!(retrieved_name == name, ETestUserNameMismatch);

            let retrieved_shared_user_address = user_owned::get_shared_user(&owned_user);
            assert!(retrieved_shared_user_address == shared_user_address, EUserAddressMismatch);

            let shared_user = ts::take_shared<UserShared>(scenario);

            let retrieved_owner = user_shared::get_owner(&shared_user);
            assert!(retrieved_owner == ADMIN, EUserOwnerMismatch);

            let retrieved_key = user_shared::get_key(&shared_user);
            assert!(retrieved_key == utf8(b"user-name"), EUserKeyMismatch);

            let retrieved_owned_user_address = user_shared::get_owned_user(&shared_user);
            assert!(retrieved_owned_user_address == owned_user_address, EUserAddressMismatch);

            ts::return_to_sender(scenario, owned_user);
            ts::return_shared(shared_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidUserDescription)]
    fun test_user_create_description_fail() {
        let (
            mut scenario_val,
            app,
            clock,
            invite_config,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefg");
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

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidUsername)]
    fun test_user_create_name_fail() {
        let (
            mut scenario_val,
            app,
            clock,
            invite_config,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let name = utf8(b"abcdefghijklmnopqrstuvwxyz");

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

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
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
            clock,
            mut invite_config,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
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

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
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
            clock,
            invite_config,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
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

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::some(utf8(b"code")),
                option::some(utf8(b"key")),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
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
            clock,
            invite_config,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
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

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::some(invite_code),
                option::some(invite_key),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
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
            clock,
            invite_config,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
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

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
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
            clock,
            invite_config,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
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

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
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
            clock,
            invite_config,
            owned_user_config,
            mut user_registry,
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
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                utf8(b"avatar"),
                utf8(b"banner"),
                utf8(b"description"),
                utf8(b"name"),
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
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

            let owned_user = ts::take_from_sender<UserOwned>(scenario);

            user_actions::create_invite<SUI>(
                &invite_config,
                &user_fees,
                &mut user_invite_registry,
                &owned_user,
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

            ts::return_to_sender(scenario, owned_user);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
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
            clock,
            invite_config,
            owned_user_config,
            mut user_registry,
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
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                utf8(b"avatar"),
                utf8(b"banner"),
                utf8(b"description"),
                utf8(b"name"),
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

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

            let owned_user = ts::take_from_sender<UserOwned>(scenario);

            user_actions::create_invite<SUI>(
                &invite_config,
                &user_fees,
                &mut user_invite_registry,
                &owned_user,
                invite_code,
                invite_hash,
                invite_key,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, owned_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
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
            clock,
            invite_config,
            owned_user_config,
            mut user_registry,
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
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                utf8(b"avatar"),
                utf8(b"banner"),
                utf8(b"description"),
                utf8(b"name"),
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

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

            let owned_user = ts::take_from_sender<UserOwned>(scenario);

            user_actions::create_invite<SUI>(
                &invite_config,
                &user_fees,
                &mut user_invite_registry,
                &owned_user,
                invite_code,
                invite_hash,
                invite_key,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, owned_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
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
            clock,
            mut invite_config,
            owned_user_config,
            mut user_registry,
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
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                utf8(b"avatar"),
                utf8(b"banner"),
                utf8(b"description"),
                utf8(b"name"),
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
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
            let custom_payment = mint_for_testing<SUI>(
                CREATE_INVITE_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_INVITE_SUI_FEE,
                ts::ctx(scenario)
            );

            let owned_user = ts::take_from_sender<UserOwned>(scenario);

            user_actions::create_invite<SUI>(
                &invite_config,
                &user_fees,
                &mut user_invite_registry,
                &owned_user,
                invite_code,
                invite_hash,
                invite_key,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, owned_user);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
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
            clock,
            invite_config,
            owned_user_config,
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
                clock,
                invite_config,
                owned_user_config,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_actions_favorite_channel() {
        let (
            mut scenario_val,
            app,
            clock,
            invite_config,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");

        ts::next_tx(scenario, ADMIN);
        let admin_cap = {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            admin_cap
        };

        ts::next_tx(scenario, ADMIN);
        {
            types::create_channel_config<ValidChannel>(
                &admin_cap,
                ts::ctx(scenario)
            );

            let name = utf8(b"admin");

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let channel = ValidChannel {
                id: object::new(ts::ctx(scenario))
            };
            let channel_config = ts::take_shared<ChannelConfig>(scenario);
            let mut owned_user = ts::take_from_sender<UserOwned>(scenario);

            user_actions::add_favorite_channel<ValidChannel>(
                &app,
                &clock,
                &channel,
                &channel_config,
                &mut owned_user,
                ts::ctx(scenario)
            );

            let length = user_owned::get_channel_favorites_length(
                &app,
                &owned_user
            );

            assert!(length == 1, EFavoritesMismatch);

            user_actions::remove_favorite_channel<ValidChannel>(
                &app,
                &clock,
                &channel,
                &mut owned_user,
                ts::ctx(scenario)
            );

            let length = user_owned::get_channel_favorites_length(
                &app,
                &owned_user
            );

            assert!(length == 0, EFavoritesMismatch);

            destroy(admin_cap);
            destroy(channel);
            destroy(channel_config);
            destroy(owned_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ETypeMismatch)]
    fun test_user_actions_favorite_channel_add_fail() {
        let (
            mut scenario_val,
            app,
            clock,
            invite_config,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");

        ts::next_tx(scenario, ADMIN);
        let admin_cap = {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            admin_cap
        };

        ts::next_tx(scenario, ADMIN);
        {
            types::create_channel_config<ValidChannel>(
                &admin_cap,
                ts::ctx(scenario)
            );

            let name = utf8(b"admin");

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let channel = InvalidChannel {
                id: object::new(ts::ctx(scenario))
            };
            let channel_config = ts::take_shared<ChannelConfig>(scenario);
            let mut owned_user = ts::take_from_sender<UserOwned>(scenario);

            user_actions::add_favorite_channel<InvalidChannel>(
                &app,
                &clock,
                &channel,
                &channel_config,
                &mut owned_user,
                ts::ctx(scenario)
            );

            destroy(admin_cap);
            destroy(channel);
            destroy(channel_config);
            destroy(owned_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_actions_favorite_user() {
        let (
            mut scenario_val,
            app,
            clock,
            invite_config,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");

        ts::next_tx(scenario, ADMIN);
        let admin_cap = {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            admin_cap
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"admin");

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        let mut owned_user_admin = {
            let owned_user = ts::take_from_sender<UserOwned>(scenario);

            owned_user
        };

        ts::next_tx(scenario, OTHER);
        {
            let name = utf8(b"other");

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        let shared_user_other = {
            let shared_user = ts::take_shared<UserShared>(scenario);

            shared_user
        };

        ts::next_tx(scenario, ADMIN);
        {
            let channel = ValidChannel {
                id: object::new(ts::ctx(scenario))
            };

            user_actions::add_favorite_user(
                &app,
                &clock,
                &mut owned_user_admin,
                &shared_user_other,
                ts::ctx(scenario)
            );

            let length = user_owned::get_user_favorites_length(
                &app,
                &owned_user_admin
            );

            assert!(length == 1, EFavoritesMismatch);

            user_actions::remove_favorite_user(
                &app,
                &clock,
                &mut owned_user_admin,
                &shared_user_other,
                ts::ctx(scenario)
            );

            let length = user_owned::get_user_favorites_length(
                &app,
                &owned_user_admin
            );

            assert!(length == 0, EFavoritesMismatch);

            destroy(admin_cap);
            destroy(channel);
            destroy(owned_user_admin);
            destroy(shared_user_other);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
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
            clock,
            invite_config,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
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

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        let mut other_shared_user = {
            let other_shared_user = ts::take_shared<UserShared>(scenario);

            let name = utf8(b"user-name");

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            other_shared_user
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

            let owned_user = ts::take_from_sender<UserOwned>(scenario);

            user_actions::follow<SUI>(
                &clock,
                &owned_user,
                &mut other_shared_user,
                &user_fees,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let follows = user_shared::borrow_follows_mut(&mut other_shared_user);

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

            user_actions::unfollow<SUI>(
                &clock,
                &mut other_shared_user,
                &user_fees,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let membership = user_shared::borrow_follows_mut(&mut other_shared_user);

            let is_member = membership::is_member(
                membership,
                ADMIN
            );

            assert!(!is_member, EUserNotMember);

            let member_length = membership::get_length(
                membership
            );

            assert!(member_length == 0, EUserMembershipCountMismatch);

            ts::return_to_sender(scenario, owned_user);
            ts::return_shared(other_shared_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_user_actions_follow_incorrect_custom_payment() {
        let (
            mut scenario_val,
            app,
            clock,
            invite_config,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
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

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
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

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                JOIN_USER_SUI_FEE,
                ts::ctx(scenario)
            );
            
            let owned_user = ts::take_from_sender<UserOwned>(scenario);
            let mut other_shared_user = ts::take_shared<UserShared>(scenario);

            user_actions::follow<SUI>(
                &clock,
                &owned_user,
                &mut other_shared_user,
                &user_fees,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, owned_user);
            ts::return_shared(other_shared_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_user_actions_follow_incorrect_sui_payment() {
        let (
            mut scenario_val,
            app,
            clock,
            invite_config,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
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

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
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

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let owned_user = ts::take_from_sender<UserOwned>(scenario);
            let mut other_shared_user = ts::take_shared<UserShared>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                JOIN_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            user_actions::follow<SUI>(
                &clock,
                &owned_user,
                &mut other_shared_user,
                &user_fees,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, owned_user);
            ts::return_shared(other_shared_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ENoSelfJoin)]
    fun test_user_actions_follow_no_self() {
        let (
            mut scenario_val,
            app,
            clock,
            invite_config,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
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

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let owned_user = ts::take_from_sender<UserOwned>(scenario);
            let mut shared_user = ts::take_shared<UserShared>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                JOIN_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                JOIN_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::follow<SUI>(
                &clock,
                &owned_user,
                &mut shared_user,
                &user_fees,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, owned_user);
            ts::return_shared(shared_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_user_actions_unfollow_incorrect_custom_payment() {
        let (
            mut scenario_val,
            app,
            clock,
            invite_config,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
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

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        let mut other_shared_user ={
            let other_shared_user = ts::take_shared<UserShared>(scenario);

            let name = utf8(b"user-name");

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            other_shared_user
        };

        ts::next_tx(scenario, ADMIN);
        {
            let owned_user = ts::take_from_sender<UserOwned>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                JOIN_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                JOIN_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::follow<SUI>(
                &clock,
                &owned_user,
                &mut other_shared_user,
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

            user_actions::unfollow<SUI>(
                &clock,
                &mut other_shared_user,
                &user_fees,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, owned_user);
            ts::return_shared(other_shared_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_user_actions_unfollow_incorrect_sui_payment() {
        let (
            mut scenario_val,
            app,
            clock,
            invite_config,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
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

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        let mut other_shared_user = {
            let other_shared_user = ts::take_shared<UserShared>(scenario);

            let name = utf8(b"user-name");

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            other_shared_user
        };

        ts::next_tx(scenario, ADMIN);
        {  
            let owned_user = ts::take_from_sender<UserOwned>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                JOIN_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                JOIN_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::follow<SUI>(
                &clock,
                &owned_user,
                &mut other_shared_user,
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

            user_actions::unfollow<SUI>(
                &clock,
                &mut other_shared_user,
                &user_fees,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, owned_user);
            ts::return_shared(other_shared_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
        
        owned_user_config,        user_registry,
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
            clock,
            invite_config,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
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

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let owned_user = ts::take_from_sender<UserOwned>(scenario);
            let mut shared_user = ts::take_shared<UserShared>(scenario);

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
            ) = user_actions::post<SUI>(
                &app,
                &clock,
                &owned_user,
                &owned_user_config,
                &mut shared_user,
                &user_fees,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let posts = user_shared::borrow_posts_mut(&mut shared_user);

            let has_record = posts::has_record(
                posts,
                timestamp
            );

            assert!(has_record, ENoPostsRecord);

            let length = posts::get_length(posts);

            assert!(length == 1, EPostsLengthMismatch);

            ts::return_to_sender(scenario, owned_user);
            ts::return_shared(shared_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
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
            clock,
            invite_config,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
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

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let owned_user = ts::take_from_sender<UserOwned>(scenario);
            let mut shared_user = ts::take_shared<UserShared>(scenario);

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
            ) = user_actions::post<SUI>(
                &app,
                &clock,
                &owned_user,
                &owned_user_config,
                &mut shared_user,
                &user_fees,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, owned_user);
            ts::return_shared(shared_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
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
            clock,
            invite_config,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
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

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let owned_user = ts::take_from_sender<UserOwned>(scenario);
            let mut shared_user = ts::take_shared<UserShared>(scenario);

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
            ) = user_actions::post<SUI>(
                &app,
                &clock,
                &owned_user,
                &owned_user_config,
                &mut shared_user,
                &user_fees,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, owned_user);
            ts::return_shared(shared_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
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
            clock,
            mut invite_config,
            owned_user_config,
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
            let avatar = utf8(b"avatar");
            let banner = utf8(b"banner");
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

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let new_avatar = utf8(b"new-avatar");
            let new_banner = utf8(b"new-banner");
            let new_description = utf8(b"new-description");
            let new_name = utf8(b"USER-name");

            let mut owned_user = ts::take_from_sender<UserOwned>(scenario);

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
                &mut owned_user,
                new_avatar,
                new_banner,
                new_description,
                new_name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let retrieved_avatar = user_owned::get_avatar(&owned_user);
            assert!(retrieved_avatar == new_avatar, EUserAvatarMismatch);

            let retrieved_banner = user_owned::get_banner(&owned_user);
            assert!(retrieved_banner == new_banner, EUserBannerMismatch);

            let retrieved_description = user_owned::get_description(&owned_user);
            assert!(retrieved_description == new_description, EUserDescriptionMismatch);

            let retrieved_key = user_owned::get_key(&owned_user);
            assert!(retrieved_key == utf8(b"user-name"), EUserKeyMismatch);

            let retrieved_name = user_owned::get_name(&owned_user);
            assert!(retrieved_name == new_name, ETestUserNameMismatch);

            ts::return_to_sender(scenario, owned_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
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
            clock,
            mut invite_config,
            owned_user_config,
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
            let avatar = utf8(b"avatar");
            let banner = utf8(b"banner");
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

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let new_avatar = utf8(b"new-avatar");
            let new_banner = utf8(b"new-banner");
            let new_description = utf8(b"new-description");
            let new_name = utf8(b"USER-name");

            let mut owned_user = ts::take_from_sender<UserOwned>(
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
                &mut owned_user,
                new_avatar,
                new_banner,
                new_description,
                new_name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, owned_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
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
            clock,
            mut invite_config,
            owned_user_config,
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
            let avatar = utf8(b"avatar");
            let banner = utf8(b"banner");
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

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let new_avatar = utf8(b"new-avatar");
            let new_banner = utf8(b"new-banner");
            let new_description = utf8(b"new-description");
            let new_name = utf8(b"USER-name");

            let mut owned_user = ts::take_from_sender<UserOwned>(
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
                &mut owned_user,
                new_avatar,
                new_banner,
                new_description,
                new_name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, owned_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
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
            clock,
            mut invite_config,
            owned_user_config,
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
            let avatar = utf8(b"avatar");
            let banner = utf8(b"banner");
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

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let new_avatar = utf8(b"new-avatar");
            let new_banner = utf8(b"new-banner");
            let new_description = utf8(b"new-description");
            let new_name = utf8(b"different");

            let mut owned_user = ts::take_from_sender<UserOwned>(
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
                &mut owned_user,
                new_avatar,
                new_banner,
                new_description,
                new_name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, owned_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
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
            clock,
            mut invite_config,
            owned_user_config,
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
            let avatar = utf8(b"avatar");
            let banner = utf8(b"banner");
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

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, OTHER);
        {
            let avatar = utf8(b"avatar");
            let banner = utf8(b"banner");
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

            let (
                _owned_user_address,
                _shared_user_address
            ) = user_actions::create<SUI>(
                &clock,
                &invite_config,
                &mut user_registry,
                &mut user_invite_registry,
                &user_fees,
                option::none(),
                option::none(),
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, OTHER);
        {
            let new_avatar = utf8(b"new-avatar");
            let new_banner = utf8(b"new-banner");
            let new_description = utf8(b"new-description");
            let new_name = utf8(b"USER-name");

            let mut owned_user = ts::take_from_sender<UserOwned>(
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
                &mut owned_user,
                new_avatar,
                new_banner,
                new_description,
                new_name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, owned_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                user_registry,
                user_invite_registry,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_description_validity() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let description = utf8(b"ab");

            let is_valid = user_actions::is_valid_description_for_testing(&description);

            assert!(is_valid == true, EDescriptionInvalid);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let description = utf8(b"abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefg");

            let is_valid = user_actions::is_valid_description_for_testing(&description);

            assert!(is_valid == false, EDescriptionInvalid);
        };

        ts::end(scenario_val);
    }
}
