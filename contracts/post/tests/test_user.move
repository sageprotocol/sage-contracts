#[test_only]
module sage_post::test_user_posts {
    use std::string::{utf8};

    use sui::{
        clock::{Self, Clock},
        coin::{mint_for_testing},
        sui::{SUI},
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy}
    };

    use sage_admin::{
        admin::{Self},
        apps::{Self, App}
    };

    use sage_post::{
        post::{Self},
        user_posts::{Self, UserPostsRegistry}
    };

    use sage_user::{
        user_actions::{Self},
        user_invite::{Self, InviteConfig, UserInviteRegistry},
        user_membership::{Self, UserMembershipRegistry},
        user_fees::{Self, UserFees},
        user_registry::{Self, UserRegistry}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

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

    const EUserPostsExists: u64 = 0;
    const EUserPostsDoesNotExist: u64 = 1;
    const EUserPostMismatch: u64 = 2;

    // --------------- Test Functions ---------------

    #[test_only]
    fun destroy_for_testing(
        app: App,
        invite_config: InviteConfig,
        user_registry: UserRegistry,
        user_invite_registry: UserInviteRegistry,
        user_membership_registry: UserMembershipRegistry,
        user_posts_registry: UserPostsRegistry,
        user_fees: UserFees
    ) {
        destroy(app);
        destroy(invite_config);
        destroy(user_registry);
        destroy(user_invite_registry);
        destroy(user_membership_registry);
        destroy(user_posts_registry);
        destroy(user_fees);
    }

    #[test_only]
    fun setup_for_testing(): (
        Scenario,
        App,
        InviteConfig,
        UserRegistry,
        UserInviteRegistry,
        UserMembershipRegistry,
        UserPostsRegistry,
        UserFees
    ) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
            user_posts::init_for_testing(ts::ctx(scenario));
            user_registry::init_for_testing(ts::ctx(scenario));
            user_invite::init_for_testing(ts::ctx(scenario));
            user_membership::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let (
            app,
            invite_config,
            user_registry,
            user_invite_registry,
            user_membership_registry,
            user_posts_registry,
            user_fees
         ) = {
            let user_registry = scenario.take_shared<UserRegistry>();
            let user_invite_registry = scenario.take_shared<UserInviteRegistry>();
            let user_membership_registry = scenario.take_shared<UserMembershipRegistry>();
            let user_posts_registry = scenario.take_shared<UserPostsRegistry>();

            let invite_config = scenario.take_shared<InviteConfig>();

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

            (
                app,
                invite_config,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                user_posts_registry,
                user_fees
            )
        };

        (
            scenario_val,
            app,
            invite_config,
            user_registry,
            user_invite_registry,
            user_membership_registry,
            user_posts_registry,
            user_fees
        )
    }

    #[test]
    fun test_user_posts_init() {
        let (
            mut scenario_val,
            app,
            invite_config,
            user_registry,
            user_invite_registry,
            user_membership_registry,
            user_posts_registry_val,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                app,
                invite_config,
                user_registry,
                user_invite_registry,
                user_membership_registry,
                user_posts_registry_val,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

     #[test]
    fun test_user_posts_create() {
        let (
            mut scenario_val,
            app,
            invite_config,
            mut user_registry_val,
            mut user_invite_registry_val,
            mut user_membership_registry_val,
            mut user_posts_registry_val,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let user_registry = &mut user_registry_val;
        let user_invite_registry = &mut user_invite_registry_val;
        let user_membership_registry = &mut user_membership_registry_val;
        let user_posts_registry = &mut user_posts_registry_val;

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
                utf8(b""),
                utf8(b""),
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let has_record = user_posts::has_record(
                user_posts_registry,
                name
            );

            assert!(!has_record, EUserPostsExists);

            user_posts::create_for_testing(
                user_posts_registry,
                name
            );

            let has_record = user_posts::has_record(
                user_posts_registry,
                name
            );

            assert!(has_record, EUserPostsDoesNotExist);

            ts::return_shared(clock);

            destroy_for_testing(
                app,
                invite_config,
                user_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                user_posts_registry_val,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_posts_add() {
        let (
            mut scenario_val,
            app,
            invite_config,
            mut user_registry_val,
            mut user_invite_registry_val,
            mut user_membership_registry_val,
            mut user_posts_registry_val,
            user_fees
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let user_registry = &mut user_registry_val;
        let user_invite_registry = &mut user_invite_registry_val;
        let user_membership_registry = &mut user_membership_registry_val;
        let user_posts_registry = &mut user_posts_registry_val;

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
                utf8(b""),
                utf8(b""),
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                name,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            user_posts::create_for_testing(
                user_posts_registry,
                name
            );

            let timestamp: u64 = 999;
            let address: address = @0xaaa;

            let (_post, post_key) = post::create(
                address,
                utf8(b"data"),
                utf8(b"description"),
                utf8(b"title"),
                timestamp,
                ts::ctx(scenario)
            );

            user_posts::add(
                user_posts_registry,
                name,
                post_key
            );

            let has_post = user_posts::has_post(
                user_posts_registry,
                name,
                post_key
            );

            assert!(has_post, EUserPostMismatch);

            ts::return_shared(clock);

            destroy_for_testing(
                app,
                invite_config,
                user_registry_val,
                user_invite_registry_val,
                user_membership_registry_val,
                user_posts_registry_val,
                user_fees
            );
        };

        ts::end(scenario_val);
    }
}
