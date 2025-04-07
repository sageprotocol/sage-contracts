#[test_only]
module sage_channel::test_channel_actions {
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
            FeeCap
        },
        apps::{Self, App},
        types::{
            Self,
            UserOwnedConfig
        }
    };

    use sage_channel::{
        channel::{Self, Channel},
        channel_actions::{
            Self,
            EChannelNameMismatch
        },
        channel_fees::{
            Self,
            ChannelFees,
            EIncorrectCustomPayment,
            EIncorrectSuiPayment
        },
        channel_registry::{Self, ChannelRegistry},
    };

    use sage_shared::{
        membership::{Self, EIsNotMember},
        moderation::{Self, EIsNotModerator, EIsNotOwner},
        posts::{Self}
    };

    use sage_user::{
        user_actions::{Self},
        user_fees::{Self, UserFees},
        user_invite::{Self, InviteConfig, UserInviteRegistry},
        user_owned::{UserOwned},
        user_registry::{Self, UserRegistry},
        user_shared::{UserShared}
    };

    use sage_utils::{
        string_helpers::{Self}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;
    const SERVER: address = @server;

    const ADD_MODERATOR_CUSTOM_FEE: u64 = 1;
    const ADD_MODERATOR_SUI_FEE: u64 = 2;
    const CREATE_CHANNEL_CUSTOM_FEE: u64 = 3;
    const CREATE_CHANNEL_SUI_FEE: u64 = 4;
    const JOIN_CHANNEL_CUSTOM_FEE: u64 = 5;
    const JOIN_CHANNEL_SUI_FEE: u64 = 6;
    const LEAVE_CHANNEL_CUSTOM_FEE: u64 = 7;
    const LEAVE_CHANNEL_SUI_FEE: u64 = 8;
    const POST_TO_CHANNEL_CUSTOM_FEE: u64 = 9;
    const POST_TO_CHANNEL_SUI_FEE: u64 = 10;
    const REMOVE_MODERATOR_CUSTOM_FEE: u64 = 11;
    const REMOVE_MODERATOR_SUI_FEE: u64 = 12;
    const UPDATE_CHANNEL_CUSTOM_FEE: u64 = 13;
    const UPDATE_CHANNEL_SUI_FEE: u64 = 14;

    const CREATE_INVITE_CUSTOM_FEE: u64 = 21;
    const CREATE_INVITE_SUI_FEE: u64 = 22;
    const CREATE_USER_CUSTOM_FEE: u64 = 23;
    const CREATE_USER_SUI_FEE: u64 = 24;
    const JOIN_USER_CUSTOM_FEE: u64 = 25;
    const JOIN_USER_SUI_FEE: u64 = 26;
    const LEAVE_USER_CUSTOM_FEE: u64 = 27;
    const LEAVE_USER_SUI_FEE: u64 = 28;
    const POST_TO_USER_CUSTOM_FEE: u64 = 29;
    const POST_TO_USER_SUI_FEE: u64 = 30;
    const UPDATE_USER_CUSTOM_FEE: u64 = 31;
    const UPDATE_USER_SUI_FEE: u64 = 32;

    const INCORRECT_FEE: u64 = 100;

    // --------------- Errors ---------------

    const EChannelAvatarMismatch: u64 = 2;
    const EChannelBannerMismatch: u64 = 3;
    const EChannelDescriptionMismatch: u64 = 4;
    const EChannelCreatorMismatch: u64 = 5;
    const EChannelKeyMismatch: u64 = 6;
    const EIsMember: u64 = 1;
    const EIsModerator: u64 = 7;
    const EIsOwner: u64 = 1;
    const EMemberLengthMismatch: u64 = 9;
    const EModeratorLengthMismatch: u64 = 9;
    const ENoPostRecord: u64 = 1;
    const ENoRegistryRecord: u64 = 10;
    const EPostsLengthMismatch: u64 = 1;
    const ETestChannelNameMismatch: u64 = 10;
    const ETestIsNotMember: u64 = 1;
    const ETestIsNotModerator: u64 = 8;
    const ETestIsNotOwner: u64 = 1;

    // --------------- Test Functions ---------------

    #[test_only]
    fun destroy_for_testing(
        app: App,
        channel_fees: ChannelFees,
        channel_registry: ChannelRegistry,
        clock: Clock,
        invite_config: InviteConfig,
        owned_user_admin: UserOwned,
        owned_user_server: UserOwned,
        owned_user_config: UserOwnedConfig,
        shared_user_admin: UserShared,
        shared_user_server: UserShared,
        user_fees: UserFees,
        user_registry: UserRegistry,
        user_invite_registry: UserInviteRegistry
    ) {
        destroy(app);
        destroy(channel_fees);
        destroy(channel_registry);
        ts::return_shared(clock);
        destroy(invite_config);
        destroy(owned_user_admin);
        destroy(owned_user_server);
        destroy(owned_user_config);
        destroy(shared_user_admin);
        destroy(shared_user_server);
        destroy(user_fees);
        destroy(user_registry);
        destroy(user_invite_registry);
    }

    #[test_only]
    fun setup_for_testing(): (
        Scenario,
        App,
        ChannelFees,
        ChannelRegistry,
        Clock,
        InviteConfig,
        UserOwned,
        UserOwned,
        UserOwnedConfig,
        UserShared,
        UserShared,
        UserFees,
        UserRegistry,
        UserInviteRegistry
    ) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
            apps::init_for_testing(ts::ctx(scenario));
            channel_registry::init_for_testing(ts::ctx(scenario));
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
            channel_registry,
            clock,
            invite_config,
            mut user_registry,
            mut user_invite_registry
        ) = {
            let channel_registry = scenario.take_shared<ChannelRegistry>();
            let invite_config = scenario.take_shared<InviteConfig>();
            let user_invite_registry = scenario.take_shared<UserInviteRegistry>();
            let user_registry = scenario.take_shared<UserRegistry>();

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

            channel_fees::create<SUI>(
                &fee_cap,
                &mut app,
                ADD_MODERATOR_CUSTOM_FEE,
                ADD_MODERATOR_SUI_FEE,
                CREATE_CHANNEL_CUSTOM_FEE,
                CREATE_CHANNEL_SUI_FEE,
                JOIN_CHANNEL_CUSTOM_FEE,
                JOIN_CHANNEL_SUI_FEE,
                LEAVE_CHANNEL_CUSTOM_FEE,
                LEAVE_CHANNEL_SUI_FEE,
                POST_TO_CHANNEL_CUSTOM_FEE,
                POST_TO_CHANNEL_SUI_FEE,
                REMOVE_MODERATOR_CUSTOM_FEE,
                REMOVE_MODERATOR_SUI_FEE,
                UPDATE_CHANNEL_CUSTOM_FEE,
                UPDATE_CHANNEL_SUI_FEE,
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
                channel_registry,
                clock,
                invite_config,
                user_registry,
                user_invite_registry
            )
        };

        ts::next_tx(scenario, ADMIN);
        let (
            channel_fees,
            user_fees,
            owned_user_config
         ) = {
            let channel_fees = scenario.take_shared<ChannelFees>();
            let user_fees = scenario.take_shared<UserFees>();

            let owned_user_config = scenario.take_shared<UserOwnedConfig>();

            (
                channel_fees,
                user_fees,
                owned_user_config
            )
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
                _owned_address,
                _shared_address
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
                utf8(b"admin"),
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, SERVER);
        let (
            owned_user_admin,
            shared_user_admin
        ) = {
            let owned_user = ts::take_from_address<UserOwned>(
                scenario,
                ADMIN
            );
            let shared_user = ts::take_shared<UserShared>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let (
                _owned_address,
                _shared_address
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
                utf8(b"server"),
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            (
                owned_user,
                shared_user
            )
        };

        ts::next_tx(scenario, SERVER);
        let (
            owned_user_server,
            shared_user_server
        ) = {
            let owned_user = ts::take_from_sender<UserOwned>(scenario);
            let shared_user = ts::take_shared<UserShared>(scenario);

            (
                owned_user,
                shared_user
            )
        };

        (
            scenario_val,
            app,
            channel_fees,
            channel_registry,
            clock,
            invite_config,
            owned_user_admin,
            owned_user_server,
            owned_user_config,
            shared_user_admin,
            shared_user_server,
            user_fees,
            user_registry,
            user_invite_registry
        )
    }

    #[test]
    fun test_init() {
        let (
            mut scenario_val,
            app,
            channel_fees,
            channel_registry,
            clock,
            invite_config,
            owned_user_admin,
            owned_user_server,
            owned_user_config,
            shared_user_admin,
            shared_user_server,
            user_fees,
            user_registry,
            user_invite_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                app,
                channel_fees,
                channel_registry,
                clock,
                invite_config,
                owned_user_admin,
                owned_user_server,
                owned_user_config,
                shared_user_admin,
                shared_user_server,
                user_fees,
                user_registry,
                user_invite_registry
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_channel_actions_create() {
        let (
            mut scenario_val,
            app,
            channel_fees,
            mut channel_registry,
            clock,
            invite_config,
            owned_user_admin,
            owned_user_server,
            owned_user_config,
            shared_user_admin,
            shared_user_server,
            user_fees,
            user_registry,
            user_invite_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let name = utf8(b"CHANNEL-name");

        let key = string_helpers::to_lowercase(&name);

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let _channel_address = channel_actions::create<SUI>(
                &channel_fees,
                &mut channel_registry,
                &clock,
                &owned_user_admin,
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
            let mut channel = ts::take_shared<Channel>(scenario);

            let retrieved_avatar = channel::get_avatar(&channel);
            assert!(retrieved_avatar == avatar, EChannelAvatarMismatch);

            let retrieved_banner = channel::get_banner(&channel);
            assert!(retrieved_banner == banner, EChannelBannerMismatch);

            let retrieved_creator = channel::get_created_by(&channel);
            assert!(retrieved_creator == ADMIN, EChannelCreatorMismatch);

            let retrieved_description = channel::get_description(&channel);
            assert!(retrieved_description == description, EChannelDescriptionMismatch);

            let retrieved_key = channel::get_key(&channel);
            assert!(retrieved_key == key, EChannelKeyMismatch);

            let retrieved_name = channel::get_name(&channel);
            assert!(retrieved_name == name, ETestChannelNameMismatch);

            let follows = channel::borrow_follows_mut(&mut channel);

            let is_member = membership::is_member(
                follows,
                ADMIN
            );

            assert!(is_member, ETestIsNotMember);

            let length = membership::get_length(
                follows
            );

            assert!(length == 1, EMemberLengthMismatch);

            let has_record = channel_registry::has_record(
                &channel_registry,
                key
            );

            assert!(has_record, ENoRegistryRecord);

            ts::return_shared(channel);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut channel = ts::take_shared<Channel>(scenario);

            let moderation = channel::borrow_moderators_mut(&mut channel);

            let is_moderator = moderation::is_moderator(
                moderation,
                ADMIN
            );

            assert!(is_moderator, ETestIsNotModerator);

            let length = moderation::get_length(
                moderation
            );

            assert!(length == 1, EModeratorLengthMismatch);

            let is_owner = moderation::is_owner(
                moderation,
                ADMIN
            );

            assert!(is_owner, ETestIsNotOwner);

            ts::return_shared(channel);

            destroy_for_testing(
                app,
                channel_fees,
                channel_registry,
                clock,
                invite_config,
                owned_user_admin,
                owned_user_server,
                owned_user_config,
                shared_user_admin,
                shared_user_server,
                user_fees,
                user_registry,
                user_invite_registry
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_channel_actions_create_incorrect_custom_payment() {
        let (
            mut scenario_val,
            app,
            channel_fees,
            mut channel_registry,
            clock,
            invite_config,
            owned_user_admin,
            owned_user_server,
            owned_user_config,
            shared_user_admin,
            shared_user_server,
            user_fees,
            user_registry,
            user_invite_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let name = utf8(b"channel-name");

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let _channel_address = channel_actions::create<SUI>(
                &channel_fees,
                &mut channel_registry,
                &clock,
                &owned_user_admin,
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
                channel_fees,
                channel_registry,
                clock,
                invite_config,
                owned_user_admin,
                owned_user_server,
                owned_user_config,
                shared_user_admin,
                shared_user_server,
                user_fees,
                user_registry,
                user_invite_registry
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_channel_actions_create_incorrect_sui_payment() {
        let (
            mut scenario_val,
            app,
            channel_fees,
            mut channel_registry,
            clock,
            invite_config,
            owned_user_admin,
            owned_user_server,
            owned_user_config,
            shared_user_admin,
            shared_user_server,
            user_fees,
            user_registry,
            user_invite_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let name = utf8(b"channel-name");

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            let _channel_address = channel_actions::create<SUI>(
                &channel_fees,
                &mut channel_registry,
                &clock,
                &owned_user_admin,
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
                channel_fees,
                channel_registry,
                clock,
                invite_config,
                owned_user_admin,
                owned_user_server,
                owned_user_config,
                shared_user_admin,
                shared_user_server,
                user_fees,
                user_registry,
                user_invite_registry
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_channel_actions_follows() {
        let (
            mut scenario_val,
            app,
            channel_fees,
            mut channel_registry,
            clock,
            invite_config,
            owned_user_admin,
            owned_user_server,
            owned_user_config,
            shared_user_admin,
            shared_user_server,
            user_fees,
            user_registry,
            user_invite_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let name = utf8(b"CHANNEL-name");

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let _channel_address = channel_actions::create<SUI>(
                &channel_fees,
                &mut channel_registry,
                &clock,
                &owned_user_admin,
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, SERVER);
        let mut channel = {
            let mut channel = ts::take_shared<Channel>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                JOIN_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                JOIN_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            channel_actions::follow<SUI>(
                &mut channel,
                &channel_fees,
                &clock,
                &owned_user_server,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let follows = channel::borrow_follows_mut(&mut channel);

            let is_member = membership::is_member(
                follows,
                SERVER
            );

            assert!(is_member, ETestIsNotMember);

            let length = membership::get_length(
                follows
            );

            assert!(length == 2, EMemberLengthMismatch);

            channel
        };

        ts::next_tx(scenario, SERVER);
        {
            let custom_payment = mint_for_testing<SUI>(
                LEAVE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                LEAVE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            channel_actions::unfollow<SUI>(
                &mut channel,
                &channel_fees,
                &clock,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let follows = channel::borrow_follows_mut(&mut channel);

            let is_member = membership::is_member(
                follows,
                SERVER
            );

            assert!(!is_member, EIsMember);

            let length = membership::get_length(
                follows
            );

            assert!(length == 1, EMemberLengthMismatch);

            ts::return_shared(channel);

            destroy_for_testing(
                app,
                channel_fees,
                channel_registry,
                clock,
                invite_config,
                owned_user_admin,
                owned_user_server,
                owned_user_config,
                shared_user_admin,
                shared_user_server,
                user_fees,
                user_registry,
                user_invite_registry
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_channel_actions_follow_incorrect_custom_payment() {
        let (
            mut scenario_val,
            app,
            channel_fees,
            mut channel_registry,
            clock,
            invite_config,
            owned_user_admin,
            owned_user_server,
            owned_user_config,
            shared_user_admin,
            shared_user_server,
            user_fees,
            user_registry,
            user_invite_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let name = utf8(b"CHANNEL-name");

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let _channel_address = channel_actions::create<SUI>(
                &channel_fees,
                &mut channel_registry,
                &clock,
                &owned_user_admin,
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, SERVER);
        {
            let mut channel = ts::take_shared<Channel>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                JOIN_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            channel_actions::follow<SUI>(
                &mut channel,
                &channel_fees,
                &clock,
                &owned_user_server,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(channel);

            destroy_for_testing(
                app,
                channel_fees,
                channel_registry,
                clock,
                invite_config,
                owned_user_admin,
                owned_user_server,
                owned_user_config,
                shared_user_admin,
                shared_user_server,
                user_fees,
                user_registry,
                user_invite_registry
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_channel_actions_follow_incorrect_sui_payment() {
        let (
            mut scenario_val,
            app,
            channel_fees,
            mut channel_registry,
            clock,
            invite_config,
            owned_user_admin,
            owned_user_server,
            owned_user_config,
            shared_user_admin,
            shared_user_server,
            user_fees,
            user_registry,
            user_invite_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let name = utf8(b"CHANNEL-name");

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let _channel_address = channel_actions::create<SUI>(
                &channel_fees,
                &mut channel_registry,
                &clock,
                &owned_user_admin,
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, SERVER);
        {
            let mut channel = ts::take_shared<Channel>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                JOIN_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            channel_actions::follow<SUI>(
                &mut channel,
                &channel_fees,
                &clock,
                &owned_user_server,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(channel);

            destroy_for_testing(
                app,
                channel_fees,
                channel_registry,
                clock,
                invite_config,
                owned_user_admin,
                owned_user_server,
                owned_user_config,
                shared_user_admin,
                shared_user_server,
                user_fees,
                user_registry,
                user_invite_registry
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_channel_actions_unfollow_incorrect_custom_payment() {
        let (
            mut scenario_val,
            app,
            channel_fees,
            mut channel_registry,
            clock,
            invite_config,
            owned_user_admin,
            owned_user_server,
            owned_user_config,
            shared_user_admin,
            shared_user_server,
            user_fees,
            user_registry,
            user_invite_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let name = utf8(b"CHANNEL-name");

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let _channel_address = channel_actions::create<SUI>(
                &channel_fees,
                &mut channel_registry,
                &clock,
                &owned_user_admin,
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, SERVER);
        {
            let mut channel = ts::take_shared<Channel>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                JOIN_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                JOIN_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            channel_actions::follow<SUI>(
                &mut channel,
                &channel_fees,
                &clock,
                &owned_user_server,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                LEAVE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            channel_actions::unfollow<SUI>(
                &mut channel,
                &channel_fees,
                &clock,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(channel);

            destroy_for_testing(
                app,
                channel_fees,
                channel_registry,
                clock,
                invite_config,
                owned_user_admin,
                owned_user_server,
                owned_user_config,
                shared_user_admin,
                shared_user_server,
                user_fees,
                user_registry,
                user_invite_registry
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_channel_actions_unfollow_incorrect_sui_payment() {
        let (
            mut scenario_val,
            app,
            channel_fees,
            mut channel_registry,
            clock,
            invite_config,
            owned_user_admin,
            owned_user_server,
            owned_user_config,
            shared_user_admin,
            shared_user_server,
            user_fees,
            user_registry,
            user_invite_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let name = utf8(b"CHANNEL-name");

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let _channel_address = channel_actions::create<SUI>(
                &channel_fees,
                &mut channel_registry,
                &clock,
                &owned_user_admin,
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, SERVER);
        {
            let mut channel = ts::take_shared<Channel>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                JOIN_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                JOIN_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            channel_actions::follow<SUI>(
                &mut channel,
                &channel_fees,
                &clock,
                &owned_user_server,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                LEAVE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            channel_actions::unfollow<SUI>(
                &mut channel,
                &channel_fees,
                &clock,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(channel);

            destroy_for_testing(
                app,
                channel_fees,
                channel_registry,
                clock,
                invite_config,
                owned_user_admin,
                owned_user_server,
                owned_user_config,
                shared_user_admin,
                shared_user_server,
                user_fees,
                user_registry,
                user_invite_registry
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_channel_actions_moderation_admin() {
        let (
            mut scenario_val,
            app,
            channel_fees,
            mut channel_registry,
            clock,
            invite_config,
            owned_user_admin,
            owned_user_server,
            owned_user_config,
            shared_user_admin,
            shared_user_server,
            user_fees,
            user_registry,
            user_invite_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let name = utf8(b"CHANNEL-name");

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let _channel_address = channel_actions::create<SUI>(
                &channel_fees,
                &mut channel_registry,
                &clock,
                &owned_user_admin,
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
        let admin_cap = {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            let mut channel = ts::take_shared<Channel>(scenario);

            channel_actions::add_moderator_as_admin(
                &admin_cap,
                &mut channel,
                &clock,
                &user_registry,
                utf8(b"server")
            );

            let moderation = channel::borrow_moderators_mut(&mut channel);

            let is_moderator = moderation::is_moderator(
                moderation,
                SERVER
            );

            assert!(is_moderator, ETestIsNotModerator);

            let is_owner = moderation::is_owner(
                moderation,
                SERVER
            );

            assert!(!is_owner, EIsOwner);

            ts::return_shared(channel);

            admin_cap
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut channel = ts::take_shared<Channel>(scenario);

            channel_actions::remove_moderator_as_admin(
                &admin_cap,
                &mut channel,
                &clock,
                &user_registry,
                utf8(b"server")
            );

            let moderation = channel::borrow_moderators_mut(&mut channel);

            let is_moderator = moderation::is_moderator(
                moderation,
                SERVER
            );

            assert!(!is_moderator, EIsModerator);

            let is_owner = moderation::is_owner(
                moderation,
                SERVER
            );

            assert!(!is_owner, EIsOwner);

            let length = moderation::get_length(moderation);

            assert!(length == 1, EModeratorLengthMismatch);

            ts::return_to_sender(scenario, admin_cap);
            ts::return_shared(channel);

            destroy_for_testing(
                app,
                channel_fees,
                channel_registry,
                clock,
                invite_config,
                owned_user_admin,
                owned_user_server,
                owned_user_config,
                shared_user_admin,
                shared_user_server,
                user_fees,
                user_registry,
                user_invite_registry
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_channel_actions_moderation_owner() {
        let (
            mut scenario_val,
            app,
            channel_fees,
            mut channel_registry,
            clock,
            invite_config,
            owned_user_admin,
            owned_user_server,
            owned_user_config,
            shared_user_admin,
            shared_user_server,
            user_fees,
            user_registry,
            user_invite_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let name = utf8(b"CHANNEL-name");

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let _channel_address = channel_actions::create<SUI>(
                &channel_fees,
                &mut channel_registry,
                &clock,
                &owned_user_admin,
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
            let mut channel = ts::take_shared<Channel>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                ADD_MODERATOR_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                ADD_MODERATOR_SUI_FEE,
                ts::ctx(scenario)
            );

            channel_actions::add_moderator_as_owner<SUI>(
                &mut channel,
                &channel_fees,
                &clock,
                &shared_user_server,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let moderation = channel::borrow_moderators_mut(&mut channel);

            let is_moderator = moderation::is_moderator(
                moderation,
                SERVER
            );

            assert!(is_moderator, ETestIsNotModerator);

            let is_owner = moderation::is_owner(
                moderation,
                SERVER
            );

            assert!(!is_owner, EIsOwner);

            ts::return_shared(channel);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut channel = ts::take_shared<Channel>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                REMOVE_MODERATOR_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                REMOVE_MODERATOR_SUI_FEE,
                ts::ctx(scenario)
            );

            channel_actions::remove_moderator_as_owner<SUI>(
                &mut channel,
                &channel_fees,
                &clock,
                &shared_user_server,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let moderation = channel::borrow_moderators_mut(&mut channel);

            let is_moderator = moderation::is_moderator(
                moderation,
                SERVER
            );

            assert!(!is_moderator, EIsModerator);

            let is_owner = moderation::is_owner(
                moderation,
                SERVER
            );

            assert!(!is_owner, EIsOwner);

            let length = moderation::get_length(moderation);

            assert!(length == 1, EModeratorLengthMismatch);

            ts::return_shared(channel);

            destroy_for_testing(
                app,
                channel_fees,
                channel_registry,
                clock,
                invite_config,
                owned_user_admin,
                owned_user_server,
                owned_user_config,
                shared_user_admin,
                shared_user_server,
                user_fees,
                user_registry,
                user_invite_registry
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIsNotOwner)]
    fun test_channel_actions_add_moderator_owner_not_owner() {
        let (
            mut scenario_val,
            app,
            channel_fees,
            mut channel_registry,
            clock,
            invite_config,
            owned_user_admin,
            owned_user_server,
            owned_user_config,
            shared_user_admin,
            shared_user_server,
            user_fees,
            user_registry,
            user_invite_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let name = utf8(b"CHANNEL-name");

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let _channel_address = channel_actions::create<SUI>(
                &channel_fees,
                &mut channel_registry,
                &clock,
                &owned_user_admin,
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, SERVER);
        {
            let mut channel = ts::take_shared<Channel>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                ADD_MODERATOR_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                ADD_MODERATOR_SUI_FEE,
                ts::ctx(scenario)
            );

            channel_actions::add_moderator_as_owner<SUI>(
                &mut channel,
                &channel_fees,
                &clock,
                &shared_user_server,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(channel);

            destroy_for_testing(
                app,
                channel_fees,
                channel_registry,
                clock,
                invite_config,
                owned_user_admin,
                owned_user_server,
                owned_user_config,
                shared_user_admin,
                shared_user_server,
                user_fees,
                user_registry,
                user_invite_registry
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_channel_actions_add_moderator_owner_incorrect_custom_payment() {
        let (
            mut scenario_val,
            app,
            channel_fees,
            mut channel_registry,
            clock,
            invite_config,
            owned_user_admin,
            owned_user_server,
            owned_user_config,
            shared_user_admin,
            shared_user_server,
            user_fees,
            user_registry,
            user_invite_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let name = utf8(b"CHANNEL-name");

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let _channel_address = channel_actions::create<SUI>(
                &channel_fees,
                &mut channel_registry,
                &clock,
                &owned_user_admin,
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
            let mut channel = ts::take_shared<Channel>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                ADD_MODERATOR_SUI_FEE,
                ts::ctx(scenario)
            );

            channel_actions::add_moderator_as_owner<SUI>(
                &mut channel,
                &channel_fees,
                &clock,
                &shared_user_server,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(channel);

            destroy_for_testing(
                app,
                channel_fees,
                channel_registry,
                clock,
                invite_config,
                owned_user_admin,
                owned_user_server,
                owned_user_config,
                shared_user_admin,
                shared_user_server,
                user_fees,
                user_registry,
                user_invite_registry
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_channel_actions_add_moderator_owner_incorrect_sui_payment() {
        let (
            mut scenario_val,
            app,
            channel_fees,
            mut channel_registry,
            clock,
            invite_config,
            owned_user_admin,
            owned_user_server,
            owned_user_config,
            shared_user_admin,
            shared_user_server,
            user_fees,
            user_registry,
            user_invite_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let name = utf8(b"CHANNEL-name");

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let _channel_address = channel_actions::create<SUI>(
                &channel_fees,
                &mut channel_registry,
                &clock,
                &owned_user_admin,
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
            let mut channel = ts::take_shared<Channel>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                ADD_MODERATOR_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            channel_actions::add_moderator_as_owner<SUI>(
                &mut channel,
                &channel_fees,
                &clock,
                &shared_user_server,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(channel);

            destroy_for_testing(
                app,
                channel_fees,
                channel_registry,
                clock,
                invite_config,
                owned_user_admin,
                owned_user_server,
                owned_user_config,
                shared_user_admin,
                shared_user_server,
                user_fees,
                user_registry,
                user_invite_registry
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIsNotOwner)]
    fun test_channel_actions_remove_moderator_owner_not_owner() {
        let (
            mut scenario_val,
            app,
            channel_fees,
            mut channel_registry,
            clock,
            invite_config,
            owned_user_admin,
            owned_user_server,
            owned_user_config,
            shared_user_admin,
            shared_user_server,
            user_fees,
            user_registry,
            user_invite_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let name = utf8(b"CHANNEL-name");

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let _channel_address = channel_actions::create<SUI>(
                &channel_fees,
                &mut channel_registry,
                &clock,
                &owned_user_admin,
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
            let mut channel = ts::take_shared<Channel>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                ADD_MODERATOR_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                ADD_MODERATOR_SUI_FEE,
                ts::ctx(scenario)
            );

            channel_actions::add_moderator_as_owner<SUI>(
                &mut channel,
                &channel_fees,
                &clock,
                &shared_user_server,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(channel);
        };

        ts::next_tx(scenario, SERVER);
        {
            let mut channel = ts::take_shared<Channel>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                REMOVE_MODERATOR_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                REMOVE_MODERATOR_SUI_FEE,
                ts::ctx(scenario)
            );

            channel_actions::remove_moderator_as_owner<SUI>(
                &mut channel,
                &channel_fees,
                &clock,
                &shared_user_server,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(channel);

            destroy_for_testing(
                app,
                channel_fees,
                channel_registry,
                clock,
                invite_config,
                owned_user_admin,
                owned_user_server,
                owned_user_config,
                shared_user_admin,
                shared_user_server,
                user_fees,
                user_registry,
                user_invite_registry
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_channel_actions_remove_moderator_owner_incorrect_custom_payment() {
        let (
            mut scenario_val,
            app,
            channel_fees,
            mut channel_registry,
            clock,
            invite_config,
            owned_user_admin,
            owned_user_server,
            owned_user_config,
            shared_user_admin,
            shared_user_server,
            user_fees,
            user_registry,
            user_invite_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let name = utf8(b"CHANNEL-name");

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let _channel_address = channel_actions::create<SUI>(
                &channel_fees,
                &mut channel_registry,
                &clock,
                &owned_user_admin,
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
            let mut channel = ts::take_shared<Channel>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                ADD_MODERATOR_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                ADD_MODERATOR_SUI_FEE,
                ts::ctx(scenario)
            );

            channel_actions::add_moderator_as_owner<SUI>(
                &mut channel,
                &channel_fees,
                &clock,
                &shared_user_server,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                REMOVE_MODERATOR_SUI_FEE,
                ts::ctx(scenario)
            );

            channel_actions::remove_moderator_as_owner<SUI>(
                &mut channel,
                &channel_fees,
                &clock,
                &shared_user_server,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(channel);

            destroy_for_testing(
                app,
                channel_fees,
                channel_registry,
                clock,
                invite_config,
                owned_user_admin,
                owned_user_server,
                owned_user_config,
                shared_user_admin,
                shared_user_server,
                user_fees,
                user_registry,
                user_invite_registry
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_channel_actions_remove_moderator_owner_incorrect_sui_payment() {
        let (
            mut scenario_val,
            app,
            channel_fees,
            mut channel_registry,
            clock,
            invite_config,
            owned_user_admin,
            owned_user_server,
            owned_user_config,
            shared_user_admin,
            shared_user_server,
            user_fees,
            user_registry,
            user_invite_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let name = utf8(b"CHANNEL-name");

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let _channel_address = channel_actions::create<SUI>(
                &channel_fees,
                &mut channel_registry,
                &clock,
                &owned_user_admin,
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
            let mut channel = ts::take_shared<Channel>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                ADD_MODERATOR_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                ADD_MODERATOR_SUI_FEE,
                ts::ctx(scenario)
            );

            channel_actions::add_moderator_as_owner<SUI>(
                &mut channel,
                &channel_fees,
                &clock,
                &shared_user_server,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                REMOVE_MODERATOR_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            channel_actions::remove_moderator_as_owner<SUI>(
                &mut channel,
                &channel_fees,
                &clock,
                &shared_user_server,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(channel);

            destroy_for_testing(
                app,
                channel_fees,
                channel_registry,
                clock,
                invite_config,
                owned_user_admin,
                owned_user_server,
                owned_user_config,
                shared_user_admin,
                shared_user_server,
                user_fees,
                user_registry,
                user_invite_registry
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_channel_actions_post() {
        let (
            mut scenario_val,
            app,
            channel_fees,
            mut channel_registry,
            mut clock,
            invite_config,
            owned_user_admin,
            owned_user_server,
            owned_user_config,
            shared_user_admin,
            shared_user_server,
            user_fees,
            user_registry,
            user_invite_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let name = utf8(b"CHANNEL-name");

        let posts_key = utf8(b"sage-posts");

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let _channel_address = channel_actions::create<SUI>(
                &channel_fees,
                &mut channel_registry,
                &clock,
                &owned_user_admin,
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
        let timestamp_1 = {
            let mut channel = ts::take_shared<Channel>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                POST_TO_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                POST_TO_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let data = utf8(b"data");
            let title = utf8(b"title");

            let (
                _post_address,
                timestamp
            ) = channel_actions::post<SUI>(
                &app,
                &mut channel,
                &channel_fees,
                &clock,
                &owned_user_admin,
                &owned_user_config,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(channel);

            clock::increment_for_testing(
                &mut clock,
                1
            );

            timestamp
        };

        ts::next_tx(scenario, ADMIN);
        let timestamp_2 = {
            let mut channel = ts::take_shared<Channel>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                POST_TO_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                POST_TO_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let data = utf8(b"data");
            let title = utf8(b"title");

            let (
                _post_address,
                timestamp
            ) = channel_actions::post<SUI>(
                &app,
                &mut channel,
                &channel_fees,
                &clock,
                &owned_user_admin,
                &owned_user_config,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(channel);

            timestamp
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut channel = ts::take_shared<Channel>(scenario);

            let posts = channel::take_posts(
                &mut channel,
                posts_key,
                ts::ctx(scenario)
            );

            let has_record = posts::has_record(
                &posts,
                timestamp_1
            );

            assert!(has_record, ENoPostRecord);

            let has_record = posts::has_record(
                &posts,
                timestamp_2
            );

            assert!(has_record, ENoPostRecord);

            let length = posts::get_length(&posts);

            assert!(length == 2, EPostsLengthMismatch);

            channel::return_posts(
                &mut channel,
                posts,
                posts_key
            );

            ts::return_shared(channel);

            destroy_for_testing(
                app,
                channel_fees,
                channel_registry,
                clock,
                invite_config,
                owned_user_admin,
                owned_user_server,
                owned_user_config,
                shared_user_admin,
                shared_user_server,
                user_fees,
                user_registry,
                user_invite_registry
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_channel_actions_post_incorrect_custom_payment() {
        let (
            mut scenario_val,
            app,
            channel_fees,
            mut channel_registry,
            clock,
            invite_config,
            owned_user_admin,
            owned_user_server,
            owned_user_config,
            shared_user_admin,
            shared_user_server,
            user_fees,
            user_registry,
            user_invite_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let name = utf8(b"CHANNEL-name");

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let _channel_address = channel_actions::create<SUI>(
                &channel_fees,
                &mut channel_registry,
                &clock,
                &owned_user_admin,
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
            let mut channel = ts::take_shared<Channel>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                POST_TO_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let data = utf8(b"data");
            let title = utf8(b"title");

            let (
                _post_address,
                _timestamp
            ) = channel_actions::post<SUI>(
                &app,
                &mut channel,
                &channel_fees,
                &clock,
                &owned_user_admin,
                &owned_user_config,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(channel);

            destroy_for_testing(
                app,
                channel_fees,
                channel_registry,
                clock,
                invite_config,
                owned_user_admin,
                owned_user_server,
                owned_user_config,
                shared_user_admin,
                shared_user_server,
                user_fees,
                user_registry,
                user_invite_registry
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_channel_actions_post_incorrect_sui_payment() {
        let (
            mut scenario_val,
            app,
            channel_fees,
            mut channel_registry,
            clock,
            invite_config,
            owned_user_admin,
            owned_user_server,
            owned_user_config,
            shared_user_admin,
            shared_user_server,
            user_fees,
            user_registry,
            user_invite_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let name = utf8(b"CHANNEL-name");

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let _channel_address = channel_actions::create<SUI>(
                &channel_fees,
                &mut channel_registry,
                &clock,
                &owned_user_admin,
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
            let mut channel = ts::take_shared<Channel>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                POST_TO_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            let data = utf8(b"data");
            let title = utf8(b"title");

            let (
                _post_address,
                _timestamp
            ) = channel_actions::post<SUI>(
                &app,
                &mut channel,
                &channel_fees,
                &clock,
                &owned_user_admin,
                &owned_user_config,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(channel);

            destroy_for_testing(
                app,
                channel_fees,
                channel_registry,
                clock,
                invite_config,
                owned_user_admin,
                owned_user_server,
                owned_user_config,
                shared_user_admin,
                shared_user_server,
                user_fees,
                user_registry,
                user_invite_registry
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIsNotMember)]
    fun test_channel_actions_post_not_member() {
        let (
            mut scenario_val,
            app,
            channel_fees,
            mut channel_registry,
            clock,
            invite_config,
            owned_user_admin,
            owned_user_server,
            owned_user_config,
            shared_user_admin,
            shared_user_server,
            user_fees,
            user_registry,
            user_invite_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let name = utf8(b"CHANNEL-name");

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let _channel_address = channel_actions::create<SUI>(
                &channel_fees,
                &mut channel_registry,
                &clock,
                &owned_user_admin,
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, SERVER);
        {
            let mut channel = ts::take_shared<Channel>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                POST_TO_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                POST_TO_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let data = utf8(b"data");
            let title = utf8(b"title");

            let (
                _post_address,
                _timestamp
            ) = channel_actions::post<SUI>(
                &app,
                &mut channel,
                &channel_fees,
                &clock,
                &owned_user_server,
                &owned_user_config,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(channel);

            destroy_for_testing(
                app,
                channel_fees,
                channel_registry,
                clock,
                invite_config,
                owned_user_admin,
                owned_user_server,
                owned_user_config,
                shared_user_admin,
                shared_user_server,
                user_fees,
                user_registry,
                user_invite_registry
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_channel_actions_update_admin() {
        let (
            mut scenario_val,
            app,
            channel_fees,
            mut channel_registry,
            clock,
            invite_config,
            owned_user_admin,
            owned_user_server,
            owned_user_config,
            shared_user_admin,
            shared_user_server,
            user_fees,
            user_registry,
            user_invite_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let name = utf8(b"CHANNEL-name");

        let key = string_helpers::to_lowercase(&name);

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let _channel_address = channel_actions::create<SUI>(
                &channel_fees,
                &mut channel_registry,
                &clock,
                &owned_user_admin,
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        let new_avatar = utf8(b"new-avatar");
        let new_banner = utf8(b"new-banner");
        let new_description = utf8(b"new-description");
        let new_name = utf8(b"channel-name");

        ts::next_tx(scenario, ADMIN);
        {
            let mut channel = ts::take_shared<Channel>(scenario);

            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            channel_actions::update_as_admin(
                &admin_cap,
                &mut channel,
                &clock,
                new_avatar,
                new_banner,
                new_description,
                new_name
            );

            ts::return_to_sender(scenario, admin_cap);
            ts::return_shared(channel);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let channel = ts::take_shared<Channel>(scenario);

            let retrieved_avatar = channel::get_avatar(&channel);
            assert!(retrieved_avatar == new_avatar, EChannelAvatarMismatch);

            let retrieved_banner = channel::get_banner(&channel);
            assert!(retrieved_banner == new_banner, EChannelBannerMismatch);

            let retrieved_creator = channel::get_created_by(&channel);
            assert!(retrieved_creator == ADMIN, EChannelCreatorMismatch);

            let retrieved_description = channel::get_description(&channel);
            assert!(retrieved_description == new_description, EChannelDescriptionMismatch);

            let retrieved_key = channel::get_key(&channel);
            assert!(retrieved_key == key, EChannelKeyMismatch);

            let retrieved_name = channel::get_name(&channel);
            assert!(retrieved_name == new_name, ETestChannelNameMismatch);

            ts::return_shared(channel);

            destroy_for_testing(
                app,
                channel_fees,
                channel_registry,
                clock,
                invite_config,
                owned_user_admin,
                owned_user_server,
                owned_user_config,
                shared_user_admin,
                shared_user_server,
                user_fees,
                user_registry,
                user_invite_registry
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EChannelNameMismatch)]
    fun test_channel_actions_update_admin_name_mismatch() {
        let (
            mut scenario_val,
            app,
            channel_fees,
            mut channel_registry,
            clock,
            invite_config,
            owned_user_admin,
            owned_user_server,
            owned_user_config,
            shared_user_admin,
            shared_user_server,
            user_fees,
            user_registry,
            user_invite_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let name = utf8(b"CHANNEL-name");

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let _channel_address = channel_actions::create<SUI>(
                &channel_fees,
                &mut channel_registry,
                &clock,
                &owned_user_admin,
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        let new_avatar = utf8(b"new-avatar");
        let new_banner = utf8(b"new-banner");
        let new_description = utf8(b"new-description");
        let new_name = utf8(b"new-name");

        ts::next_tx(scenario, ADMIN);
        {
            let mut channel = ts::take_shared<Channel>(scenario);

            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            channel_actions::update_as_admin(
                &admin_cap,
                &mut channel,
                &clock,
                new_avatar,
                new_banner,
                new_description,
                new_name
            );

            ts::return_to_sender(scenario, admin_cap);
            ts::return_shared(channel);

            destroy_for_testing(
                app,
                channel_fees,
                channel_registry,
                clock,
                invite_config,
                owned_user_admin,
                owned_user_server,
                owned_user_config,
                shared_user_admin,
                shared_user_server,
                user_fees,
                user_registry,
                user_invite_registry
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_channel_actions_update_owner() {
        let (
            mut scenario_val,
            app,
            channel_fees,
            mut channel_registry,
            clock,
            invite_config,
            owned_user_admin,
            owned_user_server,
            owned_user_config,
            shared_user_admin,
            shared_user_server,
            user_fees,
            user_registry,
            user_invite_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let name = utf8(b"CHANNEL-name");

        let key = string_helpers::to_lowercase(&name);

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let _channel_address = channel_actions::create<SUI>(
                &channel_fees,
                &mut channel_registry,
                &clock,
                &owned_user_admin,
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        let new_avatar = utf8(b"new-avatar");
        let new_banner = utf8(b"new-banner");
        let new_description = utf8(b"new-description");
        let new_name = utf8(b"channel-name");

        ts::next_tx(scenario, ADMIN);
        {
            let mut channel = ts::take_shared<Channel>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                UPDATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                UPDATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            channel_actions::update_as_owner<SUI>(
                &mut channel,
                &channel_fees,
                &clock,
                new_avatar,
                new_banner,
                new_description,
                new_name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(channel);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let channel = ts::take_shared<Channel>(scenario);

            let retrieved_avatar = channel::get_avatar(&channel);
            assert!(retrieved_avatar == new_avatar, EChannelAvatarMismatch);

            let retrieved_banner = channel::get_banner(&channel);
            assert!(retrieved_banner == new_banner, EChannelBannerMismatch);

            let retrieved_creator = channel::get_created_by(&channel);
            assert!(retrieved_creator == ADMIN, EChannelCreatorMismatch);

            let retrieved_description = channel::get_description(&channel);
            assert!(retrieved_description == new_description, EChannelDescriptionMismatch);

            let retrieved_key = channel::get_key(&channel);
            assert!(retrieved_key == key, EChannelKeyMismatch);

            let retrieved_name = channel::get_name(&channel);
            assert!(retrieved_name == new_name, ETestChannelNameMismatch);

            ts::return_shared(channel);

            destroy_for_testing(
                app,
                channel_fees,
                channel_registry,
                clock,
                invite_config,
                owned_user_admin,
                owned_user_server,
                owned_user_config,
                shared_user_admin,
                shared_user_server,
                user_fees,
                user_registry,
                user_invite_registry
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EChannelNameMismatch)]
    fun test_channel_actions_update_name_mismatch() {
        let (
            mut scenario_val,
            app,
            channel_fees,
            mut channel_registry,
            clock,
            invite_config,
            owned_user_admin,
            owned_user_server,
            owned_user_config,
            shared_user_admin,
            shared_user_server,
            user_fees,
            user_registry,
            user_invite_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let name = utf8(b"CHANNEL-name");

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let _channel_address = channel_actions::create<SUI>(
                &channel_fees,
                &mut channel_registry,
                &clock,
                &owned_user_admin,
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        let new_avatar = utf8(b"new-avatar");
        let new_banner = utf8(b"new-banner");
        let new_description = utf8(b"new-description");
        let new_name = utf8(b"new-name");

        ts::next_tx(scenario, ADMIN);
        {
            let mut channel = ts::take_shared<Channel>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                UPDATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                UPDATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            channel_actions::update_as_owner<SUI>(
                &mut channel,
                &channel_fees,
                &clock,
                new_avatar,
                new_banner,
                new_description,
                new_name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(channel);

            destroy_for_testing(
                app,
                channel_fees,
                channel_registry,
                clock,
                invite_config,
                owned_user_admin,
                owned_user_server,
                owned_user_config,
                shared_user_admin,
                shared_user_server,
                user_fees,
                user_registry,
                user_invite_registry
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIsNotModerator)]
    fun test_channel_actions_update_not_moderator() {
        let (
            mut scenario_val,
            app,
            channel_fees,
            mut channel_registry,
            clock,
            invite_config,
            owned_user_admin,
            owned_user_server,
            owned_user_config,
            shared_user_admin,
            shared_user_server,
            user_fees,
            user_registry,
            user_invite_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let name = utf8(b"CHANNEL-name");

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let _channel_address = channel_actions::create<SUI>(
                &channel_fees,
                &mut channel_registry,
                &clock,
                &owned_user_admin,
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        let new_avatar = utf8(b"new-avatar");
        let new_banner = utf8(b"new-banner");
        let new_description = utf8(b"new-description");
        let new_name = utf8(b"channel-name");

        ts::next_tx(scenario, SERVER);
        {
            let mut channel = ts::take_shared<Channel>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                UPDATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                UPDATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            channel_actions::update_as_owner<SUI>(
                &mut channel,
                &channel_fees,
                &clock,
                new_avatar,
                new_banner,
                new_description,
                new_name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(channel);

            destroy_for_testing(
                app,
                channel_fees,
                channel_registry,
                clock,
                invite_config,
                owned_user_admin,
                owned_user_server,
                owned_user_config,
                shared_user_admin,
                shared_user_server,
                user_fees,
                user_registry,
                user_invite_registry
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_channel_actions_update_incorrect_custom_payment() {
        let (
            mut scenario_val,
            app,
            channel_fees,
            mut channel_registry,
            clock,
            invite_config,
            owned_user_admin,
            owned_user_server,
            owned_user_config,
            shared_user_admin,
            shared_user_server,
            user_fees,
            user_registry,
            user_invite_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let name = utf8(b"CHANNEL-name");

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let _channel_address = channel_actions::create<SUI>(
                &channel_fees,
                &mut channel_registry,
                &clock,
                &owned_user_admin,
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        let new_avatar = utf8(b"new-avatar");
        let new_banner = utf8(b"new-banner");
        let new_description = utf8(b"new-description");
        let new_name = utf8(b"channel-name");

        ts::next_tx(scenario, ADMIN);
        {
            let mut channel = ts::take_shared<Channel>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                UPDATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            channel_actions::update_as_owner<SUI>(
                &mut channel,
                &channel_fees,
                &clock,
                new_avatar,
                new_banner,
                new_description,
                new_name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(channel);

            destroy_for_testing(
                app,
                channel_fees,
                channel_registry,
                clock,
                invite_config,
                owned_user_admin,
                owned_user_server,
                owned_user_config,
                shared_user_admin,
                shared_user_server,
                user_fees,
                user_registry,
                user_invite_registry
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_channel_actions_update_incorrect_sui_payment() {
        let (
            mut scenario_val,
            app,
            channel_fees,
            mut channel_registry,
            clock,
            invite_config,
            owned_user_admin,
            owned_user_server,
            owned_user_config,
            shared_user_admin,
            shared_user_server,
            user_fees,
            user_registry,
            user_invite_registry
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let name = utf8(b"CHANNEL-name");

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let _channel_address = channel_actions::create<SUI>(
                &channel_fees,
                &mut channel_registry,
                &clock,
                &owned_user_admin,
                avatar,
                banner,
                description,
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        let new_avatar = utf8(b"new-avatar");
        let new_banner = utf8(b"new-banner");
        let new_description = utf8(b"new-description");
        let new_name = utf8(b"channel-name");

        ts::next_tx(scenario, ADMIN);
        {
            let mut channel = ts::take_shared<Channel>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                UPDATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            channel_actions::update_as_owner<SUI>(
                &mut channel,
                &channel_fees,
                &clock,
                new_avatar,
                new_banner,
                new_description,
                new_name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(channel);

            destroy_for_testing(
                app,
                channel_fees,
                channel_registry,
                clock,
                invite_config,
                owned_user_admin,
                owned_user_server,
                owned_user_config,
                shared_user_admin,
                shared_user_server,
                user_fees,
                user_registry,
                user_invite_registry
            );
        };

        ts::end(scenario_val);
    }
}
