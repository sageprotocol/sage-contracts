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
        access::{
            Self,
            ChannelConfig,
            UserOwnedConfig,
            UserWitnessConfig,
            ETypeMismatch
        },
        admin::{
            Self,
            AdminCap,
            FeeCap,
            InviteCap,
            RewardCap
        },
        admin_actions::{Self},
        apps::{Self, App},
        fees::{Self}
    };

    use sage_analytics::{
        analytics::{Self}
    };

    use sage_post::{
        post::{Self, Post},
        post_fees::{Self, PostFees}
    };

    use sage_reward::{
        reward_actions::{Self},
        reward_registry::{Self, RewardWeightsRegistry}
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
            ENotSelf,
            ESuppliedAuthorMismatch,
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
        user_shared::{Self, UserShared},
        user_witness::{UserWitness}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;
    const OTHER: address = @0xbabe;
    const SERVER: address = @server;
    const TREASURY: address = @treasury;

    const METRIC_COMMENT_GIVEN: vector<u8> = b"comment-given";
    const METRIC_COMMENT_RECEIVED: vector<u8> = b"comment-received";
    const METRIC_FAVORITED_POST: vector<u8> = b"favorited-post";
    const METRIC_FOLLOWED_USER: vector<u8> = b"followed-user";
    const METRIC_LIKED_POST: vector<u8> = b"liked-post";
    const METRIC_POST_FAVORITED: vector<u8> = b"post-favorited";
    const METRIC_POST_LIKED: vector<u8> = b"post-liked";
    const METRIC_USER_FOLLOWED: vector<u8> = b"user-followed";
    const METRIC_USER_FRIENDS: vector<u8> = b"user-friends";
    const METRIC_USER_TEXT_POST: vector<u8> = b"user-text-posts";

    const WEIGHT_COMMENT_GIVEN: u64 = 1;
    const WEIGHT_COMMENT_RECEIVED: u64 = 2;
    const WEIGHT_FAVORITED_USER_POST: u64 = 3;
    const WEIGHT_FOLLOWED_USER: u64 = 4;
    const WEIGHT_USER_FOLLOWED: u64 = 5;
    const WEIGHT_USER_FRIENDS: u64 = 6;
    const WEIGHT_USER_LIKED_POST: u64 = 7;
    const WEIGHT_USER_POST_FAVORITED: u64 = 8;
    const WEIGHT_USER_POST_LIKED: u64 = 9;
    const WEIGHT_USER_TEXT_POST: u64 = 10;

    const CREATE_INVITE_CUSTOM_FEE: u64 = 1;
    const CREATE_INVITE_SUI_FEE: u64 = 2;
    const CREATE_USER_CUSTOM_FEE: u64 = 3;
    const CREATE_USER_SUI_FEE: u64 = 4;
    const FOLLOW_USER_CUSTOM_FEE: u64 = 5;
    const FOLLOW_USER_SUI_FEE: u64 = 6;
    const FRIEND_USER_CUSTOM_FEE: u64 = 7;
    const FRIEND_USER_SUI_FEE: u64 = 8;
    const POST_TO_USER_CUSTOM_FEE: u64 = 9;
    const POST_TO_USER_SUI_FEE: u64 = 10;
    const UNFOLLOW_USER_CUSTOM_FEE: u64 = 11;
    const UNFOLLOW_USER_SUI_FEE: u64 = 12;
    const UNFRIEND_USER_CUSTOM_FEE: u64 = 13;
    const UNFRIEND_USER_SUI_FEE: u64 = 14;
    const UPDATE_USER_CUSTOM_FEE: u64 = 15;
    const UPDATE_USER_SUI_FEE: u64 = 16;

    const LIKE_POST_CUSTOM_FEE: u64 = 21;
    const LIKE_POST_SUI_FEE: u64 = 22;
    const POST_FROM_POST_CUSTOM_FEE: u64 = 23;
    const POST_FROM_POST_SUI_FEE: u64 = 24;

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
    const EUserMember: u64 = 16;
    const EUserNotMember: u64 = 17;

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
        post_fees: PostFees,
        reward_weights_registry: RewardWeightsRegistry,
        user_registry: UserRegistry,
        user_invite_registry: UserInviteRegistry,
        user_fees: UserFees,
        user_witness_config: UserWitnessConfig
    ) {
        destroy(app);
        ts::return_shared(clock);
        destroy(invite_config);
        destroy(owned_user_config);
        destroy(post_fees);
        destroy(reward_weights_registry);
        destroy(user_registry);
        destroy(user_invite_registry);
        destroy(user_fees);
        destroy(user_witness_config);
    }

    #[test_only]
    fun setup_for_testing(): (
        Scenario,
        App,
        Clock,
        InviteConfig,
        PostFees,
        RewardWeightsRegistry,
        UserOwnedConfig,
        UserRegistry,
        UserInviteRegistry,
        UserFees,
        UserWitnessConfig
    ) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
            apps::init_for_testing(ts::ctx(scenario));
            reward_registry::init_for_testing(ts::ctx(scenario));
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
            reward_weights_registry,
            user_registry,
            user_invite_registry
        ) = {
            let invite_config = scenario.take_shared<InviteConfig>();
            let reward_weights_registry = scenario.take_shared<RewardWeightsRegistry>();
            let user_registry = scenario.take_shared<UserRegistry>();
            let user_invite_registry = scenario.take_shared<UserInviteRegistry>();

            let mut app = apps::create_for_testing(
                utf8(b"sage"),
                ts::ctx(scenario)
            );

            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            let clock = ts::take_shared<Clock>(scenario);

            access::create_owned_user_config<UserOwned>(
                &admin_cap,
                ts::ctx(scenario)
            );

            access::create_user_witness_config<UserWitness>(
                &admin_cap,
                ts::ctx(scenario)
            );

            post_fees::create<SUI>(
                &fee_cap,
                &mut app,
                LIKE_POST_CUSTOM_FEE,
                LIKE_POST_SUI_FEE,
                POST_FROM_POST_CUSTOM_FEE,
                POST_FROM_POST_SUI_FEE,
                ts::ctx(scenario)
            );

            user_fees::create<SUI>(
                &fee_cap,
                &mut app,
                CREATE_INVITE_CUSTOM_FEE,
                CREATE_INVITE_SUI_FEE,
                CREATE_USER_CUSTOM_FEE,
                CREATE_USER_SUI_FEE,
                FOLLOW_USER_CUSTOM_FEE,
                FOLLOW_USER_SUI_FEE,
                FRIEND_USER_CUSTOM_FEE,
                FRIEND_USER_SUI_FEE,
                POST_TO_USER_CUSTOM_FEE,
                POST_TO_USER_SUI_FEE,
                UNFOLLOW_USER_CUSTOM_FEE,
                UNFOLLOW_USER_SUI_FEE,
                UNFRIEND_USER_CUSTOM_FEE,
                UNFRIEND_USER_SUI_FEE,
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
                reward_weights_registry,
                user_registry,
                user_invite_registry
            )
        };

        ts::next_tx(scenario, ADMIN);
        let (
            owned_user_config,
            post_fees,
            user_fees,
            user_witness_config
         ) = {
            let owned_user_config = ts::take_shared<UserOwnedConfig>(scenario);
            let post_fees = ts::take_shared<PostFees>(scenario);
            let user_fees = ts::take_shared<UserFees>(scenario);
            let user_witness_config = ts::take_shared<UserWitnessConfig>(scenario);

            (
                owned_user_config,
                post_fees,
                user_fees,
                user_witness_config
            )
        };

        (
            scenario_val,
            app,
            clock,
            invite_config,
            post_fees,
            reward_weights_registry,
            owned_user_config,
            user_registry,
            user_invite_registry,
            user_fees,
            user_witness_config
        )
    }

    #[test]
    fun test_user_actions_init() {
        let (
            mut scenario_val,
            app,
            clock,
            invite_config,
            post_fees,
            reward_weights_registry,
            owned_user_config,
            user_registry,
            user_invite_registry,
            user_fees,
            user_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
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
    fun test_user_actions_favorite_channel() {
        let (
            mut scenario_val,
            app,
            clock,
            invite_config,
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
            access::create_channel_config<ValidChannel>(
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
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
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
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
            access::create_channel_config<ValidChannel>(
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
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_actions_favorite_post() {
        let (
            mut scenario_val,
            app,
            clock,
            invite_config,
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
        let (
            mut owned_user_admin,
            mut shared_user_admin
         ) = {
            let owned_user = ts::take_from_sender<UserOwned>(scenario);
            let shared_user = ts::take_shared<UserShared>(scenario);

            (
                owned_user,
                shared_user
            )
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
        {
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
                _timestamp
            ) = user_actions::post<SUI>(
                &app,
                &clock,
                &mut owned_user_admin,
                &reward_weights_registry,
                &mut shared_user_admin,
                &user_fees,
                &user_witness_config,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let post = ts::take_shared<Post>(scenario);

            user_actions::add_favorite_post(
                &app,
                &clock,
                &mut owned_user_admin,
                &post,
                &reward_weights_registry,
                &mut shared_user_admin,
                &user_witness_config,
                ts::ctx(scenario)
            );

            let length = user_owned::get_post_favorites_length(
                &app,
                &owned_user_admin
            );

            assert!(length == 1, EFavoritesMismatch);

            user_actions::remove_favorite_post(
                &app,
                &clock,
                &mut owned_user_admin,
                &post,
                ts::ctx(scenario)
            );

            let length = user_owned::get_post_favorites_length(
                &app,
                &owned_user_admin
            );

            assert!(length == 0, EFavoritesMismatch);

            let current_epoch = reward_registry::get_current(&reward_weights_registry);

            let analytics_author = user_shared::borrow_or_create_analytics_mut(
                &mut shared_user_admin,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let does_exist = analytics::field_exists(
                analytics_author,
                utf8(b"post-favorited")
            );

            assert!(!does_exist);

            let num_post_favorites = analytics::get_field(
                analytics_author,
                utf8(b"post-favorited")
            );

            assert!(num_post_favorites == 0);

            let analytics_self = user_owned::borrow_or_create_analytics_mut(
                &mut owned_user_admin,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let does_exist = analytics::field_exists(
                analytics_self,
                utf8(b"favorited-post")
            );

            assert!(!does_exist);

            let num_favorited_posts = analytics::get_field(
                analytics_self,
                utf8(b"favorited-post")
            );

            assert!(num_favorited_posts == 0);

            destroy(admin_cap);
            destroy(post);
            destroy(owned_user_admin);
            destroy(shared_user_admin);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_actions_favorite_post_rewards() {
        let (
            mut scenario_val,
            mut app,
            clock,
            invite_config,
            post_fees,
            mut reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");

        ts::next_tx(scenario, ADMIN);
        let admin_cap = {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            let reward_cap = ts::take_from_sender<RewardCap>(scenario);

            admin_actions::update_app_rewards(
                &reward_cap,
                &mut app,
                true
            );

            reward_actions::start_epochs(
                &reward_cap,
                &clock,
                &mut reward_weights_registry,
                ts::ctx(scenario)
            );

            reward_actions::add_weight(
                &reward_cap,
                &mut reward_weights_registry,
                utf8(METRIC_FAVORITED_POST),
                WEIGHT_FAVORITED_USER_POST
            );

            reward_actions::add_weight(
                &reward_cap,
                &mut reward_weights_registry,
                utf8(METRIC_POST_FAVORITED),
                WEIGHT_USER_POST_FAVORITED
            );

            ts::return_to_sender(scenario, reward_cap);

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
        let (
            mut owned_user_admin,
            mut shared_user_admin
         ) = {
            let owned_user = ts::take_from_sender<UserOwned>(scenario);
            let shared_user = ts::take_shared<UserShared>(scenario);

            (
                owned_user,
                shared_user
            )
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

        ts::next_tx(scenario, OTHER);
        let (
            mut owned_user_other,
            mut shared_user_other
         ) = {
            let owned_user = ts::take_from_sender<UserOwned>(scenario);
            let shared_user = ts::take_shared<UserShared>(scenario);

            (
                owned_user,
                shared_user
            )
        };

        ts::next_tx(scenario, ADMIN);
        {
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
                _timestamp
            ) = user_actions::post<SUI>(
                &app,
                &clock,
                &mut owned_user_admin,
                &reward_weights_registry,
                &mut shared_user_admin,
                &user_fees,
                &user_witness_config,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, OTHER);
        let post_admin = {
            let post = ts::take_shared<Post>(scenario);

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
                _timestamp
            ) = user_actions::post<SUI>(
                &app,
                &clock,
                &mut owned_user_other,
                &reward_weights_registry,
                &mut shared_user_other,
                &user_fees,
                &user_witness_config,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            post
        };

        ts::next_tx(scenario, ADMIN);
        let (
            current_epoch,
            post_other
         ) = {
            let post_other = ts::take_shared<Post>(scenario);

            user_actions::add_favorite_post(
                &app,
                &clock,
                &mut owned_user_admin,
                &post_admin,
                &reward_weights_registry,
                &mut shared_user_admin,
                &user_witness_config,
                ts::ctx(scenario)
            );

            let current_epoch = reward_registry::get_current(&reward_weights_registry);

            let analytics_author = user_shared::borrow_or_create_analytics_mut(
                &mut shared_user_admin,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let does_exist = analytics::field_exists(
                analytics_author,
                utf8(METRIC_POST_FAVORITED)
            );

            assert!(!does_exist);

            let num_post_favorites = analytics::get_field(
                analytics_author,
                utf8(METRIC_POST_FAVORITED)
            );

            assert!(num_post_favorites == 0);

            let claim = analytics::get_claim(
                analytics_author,
                object::id_address(&app)
            );

            assert!(claim == 0);

            let analytics_self = user_owned::borrow_or_create_analytics_mut(
                &mut owned_user_admin,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let does_exist = analytics::field_exists(
                analytics_self,
                utf8(METRIC_FAVORITED_POST)
            );

            assert!(!does_exist);

            let num_favorited_posts = analytics::get_field(
                analytics_self,
                utf8(METRIC_FAVORITED_POST)
            );

            assert!(num_favorited_posts == 0);

            let claim = analytics::get_claim(
                analytics_self,
                object::id_address(&app)
            );

            assert!(claim == 0);

            (
                current_epoch,
                post_other
            )
        };

        ts::next_tx(scenario, ADMIN);
        {
            user_actions::add_favorite_post(
                &app,
                &clock,
                &mut owned_user_admin,
                &post_other,
                &reward_weights_registry,
                &mut shared_user_other,
                &user_witness_config,
                ts::ctx(scenario)
            );

            user_actions::remove_favorite_post(
                &app,
                &clock,
                &mut owned_user_admin,
                &post_other,
                ts::ctx(scenario)
            );

            let analytics_author = user_shared::borrow_or_create_analytics_mut(
                &mut shared_user_other,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let does_exist = analytics::field_exists(
                analytics_author,
                utf8(METRIC_POST_FAVORITED)
            );

            assert!(does_exist);

            let num_post_favorites = analytics::get_field(
                analytics_author,
                utf8(METRIC_POST_FAVORITED)
            );

            assert!(num_post_favorites == 1);

            let claim = analytics::get_claim(
                analytics_author,
                object::id_address(&app)
            );

            assert!(claim == WEIGHT_USER_POST_FAVORITED);

            let analytics_self = user_owned::borrow_or_create_analytics_mut(
                &mut owned_user_admin,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let does_exist = analytics::field_exists(
                analytics_self,
                utf8(METRIC_FAVORITED_POST)
            );

            assert!(does_exist);

            let num_favorited_posts = analytics::get_field(
                analytics_self,
                utf8(METRIC_FAVORITED_POST)
            );

            assert!(num_favorited_posts == 1);

            let claim = analytics::get_claim(
                analytics_self,
                object::id_address(&app)
            );

            assert!(claim == WEIGHT_FAVORITED_USER_POST);
        };

        ts::next_tx(scenario, ADMIN);
        {
            user_actions::add_favorite_post(
                &app,
                &clock,
                &mut owned_user_admin,
                &post_other,
                &reward_weights_registry,
                &mut shared_user_other,
                &user_witness_config,
                ts::ctx(scenario)
            );

            let analytics_author = user_shared::borrow_or_create_analytics_mut(
                &mut shared_user_other,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let does_exist = analytics::field_exists(
                analytics_author,
                utf8(METRIC_POST_FAVORITED)
            );

            assert!(does_exist);

            let num_post_favorites = analytics::get_field(
                analytics_author,
                utf8(METRIC_POST_FAVORITED)
            );

            assert!(num_post_favorites == 1);

            let claim = analytics::get_claim(
                analytics_author,
                object::id_address(&app)
            );

            assert!(claim == WEIGHT_USER_POST_FAVORITED);

            let analytics_self = user_owned::borrow_or_create_analytics_mut(
                &mut owned_user_admin,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let does_exist = analytics::field_exists(
                analytics_self,
                utf8(METRIC_FAVORITED_POST)
            );

            assert!(does_exist);

            let num_favorited_posts = analytics::get_field(
                analytics_self,
                utf8(METRIC_FAVORITED_POST)
            );

            assert!(num_favorited_posts == 1);

            let claim = analytics::get_claim(
                analytics_self,
                object::id_address(&app)
            );

            assert!(claim == WEIGHT_FAVORITED_USER_POST);

            destroy(admin_cap);
            destroy(post_admin);
            destroy(post_other);
            destroy(owned_user_admin);
            destroy(owned_user_other);
            destroy(shared_user_admin);
            destroy(shared_user_other);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ESuppliedAuthorMismatch)]
    fun test_user_actions_favorite_post_author_mismatch() {
        let (
            mut scenario_val,
            app,
            clock,
            invite_config,
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
        let mut shared_user_other = {
            let shared_user = ts::take_shared<UserShared>(scenario);

            shared_user
        };

        ts::next_tx(scenario, ADMIN);
        {
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
                _timestamp
            ) = user_actions::post<SUI>(
                &app,
                &clock,
                &mut owned_user_admin,
                &reward_weights_registry,
                &mut shared_user_other,
                &user_fees,
                &user_witness_config,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let post = ts::take_shared<Post>(scenario);

            user_actions::add_favorite_post(
                &app,
                &clock,
                &mut owned_user_admin,
                &post,
                &reward_weights_registry,
                &mut shared_user_other,
                &user_witness_config,
                ts::ctx(scenario)
            );

            destroy(admin_cap);
            destroy(post);
            destroy(owned_user_admin);
            destroy(shared_user_other);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
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
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
            destroy(owned_user_admin);
            destroy(shared_user_other);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
            );
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
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
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
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
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
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
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
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
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
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
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
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
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
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
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
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
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
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
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
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
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
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
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
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
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
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
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
            post_fees,
            reward_weights_registry,
            owned_user_config,
            user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
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
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
                FOLLOW_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                FOLLOW_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let mut owned_user = ts::take_from_sender<UserOwned>(scenario);

            user_actions::follow<SUI>(
                &app,
                &clock,
                &mut owned_user,
                &reward_weights_registry,
                &mut other_shared_user,
                &user_fees,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let current_epoch = reward_registry::get_current(
                &reward_weights_registry
            );

            let analytics = user_owned::borrow_or_create_analytics_mut(
                &mut owned_user,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let analytics_exists = analytics::field_exists(
                analytics,
                utf8(b"user-followed")
            );

            assert!(!analytics_exists);

            let analytics = user_shared::borrow_or_create_analytics_mut(
                &mut other_shared_user,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let analytics_exists = analytics::field_exists(
                analytics,
                utf8(b"user-follows")
            );

            assert!(!analytics_exists);

            let follows = user_shared::borrow_follows_mut(
                &mut other_shared_user,
                object::id_address(&app),
                ts::ctx(scenario)
            );

            let is_member = membership::is_member(
                follows,
                ADMIN
            );

            assert!(is_member, EUserNotMember);

            let member_length = membership::get_member_length(
                follows
            );

            assert!(member_length == 1, EUserMembershipCountMismatch);

            let custom_payment = mint_for_testing<SUI>(
                UNFOLLOW_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                UNFOLLOW_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::unfollow<SUI>(
                &app,
                &clock,
                &mut other_shared_user,
                &user_fees,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let membership = user_shared::borrow_follows_mut(
                &mut other_shared_user,
                ADMIN,
                ts::ctx(scenario)
            );

            let is_member = membership::is_member(
                membership,
                ADMIN
            );

            assert!(!is_member, EUserNotMember);

            let member_length = membership::get_member_length(
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
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_actions_follows_rewards() {
        let (
            mut scenario_val,
            mut app,
            clock,
            invite_config,
            post_fees,
            mut reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
            let reward_cap = ts::take_from_sender<RewardCap>(scenario);

            admin_actions::update_app_rewards(
                &reward_cap,
                &mut app,
                true
            );

            reward_actions::start_epochs(
                &reward_cap,
                &clock,
                &mut reward_weights_registry,
                ts::ctx(scenario)
            );

            reward_actions::add_weight(
                &reward_cap,
                &mut reward_weights_registry,
                utf8(METRIC_FOLLOWED_USER),
                WEIGHT_FOLLOWED_USER
            );

            reward_actions::add_weight(
                &reward_cap,
                &mut reward_weights_registry,
                utf8(METRIC_USER_FOLLOWED),
                WEIGHT_USER_FOLLOWED
            );

            ts::return_to_sender(scenario, reward_cap);

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
        let (
            mut owned_user,
            current_epoch
         ) = {
            let custom_payment = mint_for_testing<SUI>(
                FOLLOW_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                FOLLOW_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let mut owned_user = ts::take_from_sender<UserOwned>(scenario);

            user_actions::follow<SUI>(
                &app,
                &clock,
                &mut owned_user,
                &reward_weights_registry,
                &mut other_shared_user,
                &user_fees,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let current_epoch = reward_registry::get_current(
                &reward_weights_registry
            );

            let analytics_self = user_owned::borrow_or_create_analytics_mut(
                &mut owned_user,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let analytics_exists = analytics::field_exists(
                analytics_self,
                utf8(METRIC_FOLLOWED_USER)
            );

            assert!(analytics_exists);

            let claim = analytics::get_claim(
                analytics_self,
                object::id_address(&app)
            );

            assert!(claim == WEIGHT_FOLLOWED_USER);

            let analytics_friend = user_shared::borrow_or_create_analytics_mut(
                &mut other_shared_user,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let analytics_exists = analytics::field_exists(
                analytics_friend,
                utf8(METRIC_USER_FOLLOWED)
            );

            assert!(analytics_exists);

            let claim = analytics::get_claim(
                analytics_friend,
                object::id_address(&app)
            );

            assert!(claim == WEIGHT_USER_FOLLOWED);

            (
                owned_user,
                current_epoch
            )
        };

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                UNFOLLOW_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                UNFOLLOW_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::unfollow<SUI>(
                &app,
                &clock,
                &mut other_shared_user,
                &user_fees,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                FOLLOW_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                FOLLOW_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::follow<SUI>(
                &app,
                &clock,
                &mut owned_user,
                &reward_weights_registry,
                &mut other_shared_user,
                &user_fees,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let analytics_self = user_owned::borrow_or_create_analytics_mut(
                &mut owned_user,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let num_followed = analytics::get_field(
                analytics_self,
                utf8(METRIC_FOLLOWED_USER)
            );

            assert!(num_followed == 1);

            let claim = analytics::get_claim(
                analytics_self,
                object::id_address(&app)
            );

            assert!(claim == WEIGHT_FOLLOWED_USER);

            let analytics_friend = user_shared::borrow_or_create_analytics_mut(
                &mut other_shared_user,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let num_follows = analytics::get_field(
                analytics_friend,
                utf8(METRIC_USER_FOLLOWED)
            );

            assert!(num_follows == 1);

            let claim = analytics::get_claim(
                analytics_friend,
                object::id_address(&app)
            );

            assert!(claim == WEIGHT_USER_FOLLOWED);

            ts::return_to_sender(scenario, owned_user);
            ts::return_shared(other_shared_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
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
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
                FOLLOW_USER_SUI_FEE,
                ts::ctx(scenario)
            );
            
            let mut owned_user = ts::take_from_sender<UserOwned>(scenario);
            let mut other_shared_user = ts::take_shared<UserShared>(scenario);

            user_actions::follow<SUI>(
                &app,
                &clock,
                &mut owned_user,
                &reward_weights_registry,
                &mut other_shared_user,
                &user_fees,
                &user_witness_config,
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
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
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
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
            let mut owned_user = ts::take_from_sender<UserOwned>(scenario);
            let mut other_shared_user = ts::take_shared<UserShared>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                FOLLOW_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            user_actions::follow<SUI>(
                &app,
                &clock,
                &mut owned_user,
                &reward_weights_registry,
                &mut other_shared_user,
                &user_fees,
                &user_witness_config,
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
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
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
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
            let mut owned_user = ts::take_from_sender<UserOwned>(scenario);
            let mut shared_user = ts::take_shared<UserShared>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                FOLLOW_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                FOLLOW_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::follow<SUI>(
                &app,
                &clock,
                &mut owned_user,
                &reward_weights_registry,
                &mut shared_user,
                &user_fees,
                &user_witness_config,
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
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
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
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
            let mut owned_user = ts::take_from_sender<UserOwned>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                FOLLOW_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                FOLLOW_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::follow<SUI>(
                &app,
                &clock,
                &mut owned_user,
                &reward_weights_registry,
                &mut other_shared_user,
                &user_fees,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                UNFOLLOW_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::unfollow<SUI>(
                &app,
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
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
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
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
            let mut owned_user = ts::take_from_sender<UserOwned>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                FOLLOW_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                FOLLOW_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::follow<SUI>(
                &app,
                &clock,
                &mut owned_user,
                &reward_weights_registry,
                &mut other_shared_user,
                &user_fees,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                UNFOLLOW_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            user_actions::unfollow<SUI>(
                &app,
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
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_actions_friend_request() {
        let (
            mut scenario_val,
            app,
            clock,
            invite_config,
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
        let mut shared_user = {
            let custom_payment = mint_for_testing<SUI>(
                FRIEND_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                FRIEND_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let mut shared_user = ts::take_shared<UserShared>(scenario);

            user_actions::friend_user<SUI>(
                &app,
                &clock,
                &reward_weights_registry,
                &user_fees,
                &mut other_shared_user,
                &mut shared_user,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let friends = user_shared::borrow_friend_requests_mut(
                &mut shared_user,
                object::id_address(&app),
                ts::ctx(scenario)
            );

            let is_member = membership::is_member(
                friends,
                OTHER
            );

            assert!(!is_member, EUserMember);

            let member_length = membership::get_member_length(
                friends
            );

            assert!(member_length == 0, EUserMembershipCountMismatch);
            
            shared_user
        };

        ts::next_tx(scenario, ADMIN);
        {
            let friend_friends = user_shared::borrow_friend_requests_mut(
                &mut other_shared_user,
                object::id_address(&app),
                ts::ctx(scenario)
            );

            let is_member = membership::is_member(
                friend_friends,
                ADMIN
            );

            assert!(is_member, EUserNotMember);

            let member_length = membership::get_member_length(
                friend_friends
            );

            assert!(member_length == 1, EUserMembershipCountMismatch);
        };

        ts::next_tx(scenario, ADMIN);
        {
            user_actions::remove_friend_request(
                &app,
                &clock,
                &mut other_shared_user,
                ADMIN,
                ts::ctx(scenario)
            );

            let friends = user_shared::borrow_friend_requests_mut(
                &mut shared_user,
                object::id_address(&app),
                ts::ctx(scenario)
            );

            let is_member = membership::is_member(
                friends,
                OTHER
            );

            assert!(!is_member, EUserMember);

            let member_length = membership::get_member_length(
                friends
            );

            assert!(member_length == 0, EUserMembershipCountMismatch);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let friend_friends = user_shared::borrow_friend_requests_mut(
                &mut other_shared_user,
                object::id_address(&app),
                ts::ctx(scenario)
            );

            let is_member = membership::is_member(
                friend_friends,
                ADMIN
            );

            assert!(!is_member, EUserMember);

            let member_length = membership::get_member_length(
                friend_friends
            );

            assert!(member_length == 0, EUserMembershipCountMismatch);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                FRIEND_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                FRIEND_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::friend_user<SUI>(
                &app,
                &clock,
                &reward_weights_registry,
                &user_fees,
                &mut other_shared_user,
                &mut shared_user,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, OTHER);
        {
            user_actions::remove_friend_request(
                &app,
                &clock,
                &mut other_shared_user,
                ADMIN,
                ts::ctx(scenario)
            );

            let friends = user_shared::borrow_friend_requests_mut(
                &mut shared_user,
                object::id_address(&app),
                ts::ctx(scenario)
            );

            let is_member = membership::is_member(
                friends,
                ADMIN
            );

            assert!(!is_member, EUserMember);

            let member_length = membership::get_member_length(
                friends
            );

            assert!(member_length == 0, EUserMembershipCountMismatch);
        };

        ts::next_tx(scenario, OTHER);
        {
            let friend_friends = user_shared::borrow_friend_requests_mut(
                &mut other_shared_user,
                object::id_address(&app),
                ts::ctx(scenario)
            );

            let is_member = membership::is_member(
                friend_friends,
                ADMIN
            );

            assert!(!is_member, EUserMember);

            let member_length = membership::get_member_length(
                friend_friends
            );

            assert!(member_length == 0, EUserMembershipCountMismatch);

            ts::return_shared(shared_user);
            ts::return_shared(other_shared_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ENotSelf)]
    fun test_user_actions_friend_request_remove_not_self() {
        let (
            mut scenario_val,
            app,
            clock,
            invite_config,
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
        let mut other_shared_user = {
            let custom_payment = mint_for_testing<SUI>(
                FRIEND_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                FRIEND_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let mut shared_user = ts::take_shared<UserShared>(scenario);

            user_actions::friend_user<SUI>(
                &app,
                &clock,
                &reward_weights_registry,
                &user_fees,
                &mut other_shared_user,
                &mut shared_user,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(shared_user);

            other_shared_user
        };

        ts::next_tx(scenario, SERVER);
        {
            user_actions::remove_friend_request(
                &app,
                &clock,
                &mut other_shared_user,
                ADMIN,
                ts::ctx(scenario)
            );

            ts::return_shared(other_shared_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_actions_friend() {
        let (
            mut scenario_val,
            app,
            clock,
            invite_config,
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
        let mut shared_user = {
            let custom_payment = mint_for_testing<SUI>(
                FRIEND_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                FRIEND_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let mut shared_user = ts::take_shared<UserShared>(scenario);

            user_actions::friend_user<SUI>(
                &app,
                &clock,
                &reward_weights_registry,
                &user_fees,
                &mut other_shared_user,
                &mut shared_user,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            shared_user
        };

        ts::next_tx(scenario, OTHER);
        let current_epoch = {
            let custom_payment = mint_for_testing<SUI>(
                FRIEND_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                FRIEND_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::friend_user<SUI>(
                &app,
                &clock,
                &reward_weights_registry,
                &user_fees,
                &mut shared_user,
                &mut other_shared_user,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let current_epoch = reward_registry::get_current(
                &reward_weights_registry
            );

            let analytics = user_shared::borrow_or_create_analytics_mut(
                &mut shared_user,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let does_exist = analytics::field_exists(
                analytics,
                utf8(b"user-friends")
            );

            assert!(!does_exist);

            let friends = user_shared::borrow_friends_mut(
                &mut shared_user,
                object::id_address(&app),
                ts::ctx(scenario)
            );

            let is_member = membership::is_member(
                friends,
                OTHER
            );

            assert!(is_member, EUserNotMember);

            let member_length = membership::get_member_length(
                friends
            );

            assert!(member_length == 1, EUserMembershipCountMismatch);

            current_epoch
        };

        ts::next_tx(scenario, OTHER);
        {
            let analytics = user_shared::borrow_or_create_analytics_mut(
                &mut other_shared_user,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let does_exist = analytics::field_exists(
                analytics,
                utf8(b"user-friends")
            );

            assert!(!does_exist);

            let friend_friends = user_shared::borrow_friends_mut(
                &mut other_shared_user,
                object::id_address(&app),
                ts::ctx(scenario)
            );

            let is_member = membership::is_member(
                friend_friends,
                ADMIN
            );

            assert!(is_member, EUserNotMember);

            let member_length = membership::get_member_length(
                friend_friends
            );

            assert!(member_length == 1, EUserMembershipCountMismatch);
        };

        ts::next_tx(scenario, OTHER);
        {
            let custom_payment = mint_for_testing<SUI>(
                UNFRIEND_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                UNFRIEND_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::unfriend_user<SUI>(
                &app,
                &clock,
                &user_fees,
                &mut other_shared_user,
                &mut shared_user,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let friends = user_shared::borrow_friends_mut(
                &mut shared_user,
                object::id_address(&app),
                ts::ctx(scenario)
            );

            let is_member = membership::is_member(
                friends,
                OTHER
            );

            assert!(!is_member, EUserMember);

            let member_length = membership::get_member_length(
                friends
            );

            assert!(member_length == 0, EUserMembershipCountMismatch);
        };

        ts::next_tx(scenario, OTHER);
        {
            let friend_friends = user_shared::borrow_friends_mut(
                &mut other_shared_user,
                object::id_address(&app),
                ts::ctx(scenario)
            );

            let is_member = membership::is_member(
                friend_friends,
                ADMIN
            );

            assert!(!is_member, EUserMember);

            let member_length = membership::get_member_length(
                friend_friends
            );

            assert!(member_length == 0, EUserMembershipCountMismatch);
        };

        ts::next_tx(scenario, OTHER);
        {
            let custom_payment = mint_for_testing<SUI>(
                FRIEND_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                FRIEND_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::friend_user<SUI>(
                &app,
                &clock,
                &reward_weights_registry,
                &user_fees,
                &mut shared_user,
                &mut other_shared_user,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                FRIEND_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                FRIEND_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::friend_user<SUI>(
                &app,
                &clock,
                &reward_weights_registry,
                &user_fees,
                &mut other_shared_user,
                &mut shared_user,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                UNFRIEND_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                UNFRIEND_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::unfriend_user<SUI>(
                &app,
                &clock,
                &user_fees,
                &mut other_shared_user,
                &mut shared_user,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let friends = user_shared::borrow_friends_mut(
                &mut shared_user,
                object::id_address(&app),
                ts::ctx(scenario)
            );

            let is_member = membership::is_member(
                friends,
                OTHER
            );

            assert!(!is_member, EUserMember);

            let member_length = membership::get_member_length(
                friends
            );

            assert!(member_length == 0, EUserMembershipCountMismatch);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let friend_friends = user_shared::borrow_friends_mut(
                &mut other_shared_user,
                object::id_address(&app),
                ts::ctx(scenario)
            );

            let is_member = membership::is_member(
                friend_friends,
                ADMIN
            );

            assert!(!is_member, EUserMember);

            let member_length = membership::get_member_length(
                friend_friends
            );

            assert!(member_length == 0, EUserMembershipCountMismatch);
        };

        ts::next_tx(scenario, ADMIN);
        {
            ts::return_shared(shared_user);
            ts::return_shared(other_shared_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_actions_friend_rewards() {
        let (
            mut scenario_val,
            mut app,
            clock,
            invite_config,
            post_fees,
            mut reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");

        ts::next_tx(scenario, ADMIN);
        {
            let reward_cap = ts::take_from_sender<RewardCap>(scenario);

            admin_actions::update_app_rewards(
                &reward_cap,
                &mut app,
                true
            );

            reward_actions::start_epochs(
                &reward_cap,
                &clock,
                &mut reward_weights_registry,
                ts::ctx(scenario)
            );

            reward_actions::add_weight(
                &reward_cap,
                &mut reward_weights_registry,
                utf8(METRIC_USER_FRIENDS),
                WEIGHT_USER_FRIENDS
            );

            ts::return_to_sender(scenario, reward_cap);
        };

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
        let mut shared_user = {
            let custom_payment = mint_for_testing<SUI>(
                FRIEND_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                FRIEND_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let mut shared_user = ts::take_shared<UserShared>(scenario);

            user_actions::friend_user<SUI>(
                &app,
                &clock,
                &reward_weights_registry,
                &user_fees,
                &mut other_shared_user,
                &mut shared_user,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            shared_user
        };

        ts::next_tx(scenario, OTHER);
        let current_epoch = {
            let custom_payment = mint_for_testing<SUI>(
                FRIEND_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                FRIEND_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::friend_user<SUI>(
                &app,
                &clock,
                &reward_weights_registry,
                &user_fees,
                &mut shared_user,
                &mut other_shared_user,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let current_epoch = reward_registry::get_current(
                &reward_weights_registry
            );

            let analytics = user_shared::borrow_or_create_analytics_mut(
                &mut shared_user,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let does_exist = analytics::field_exists(
                analytics,
                utf8(METRIC_USER_FRIENDS)
            );

            assert!(does_exist);

            let num_friends = analytics::get_field(
                analytics,
                utf8(METRIC_USER_FRIENDS)
            );

            assert!(num_friends == 1);

            let claim = analytics::get_claim(
                analytics,
                object::id_address(&app)
            );

            assert!(claim == WEIGHT_USER_FRIENDS);

            current_epoch
        };

        ts::next_tx(scenario, OTHER);
        {
            let analytics = user_shared::borrow_or_create_analytics_mut(
                &mut other_shared_user,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let does_exist = analytics::field_exists(
                analytics,
                utf8(METRIC_USER_FRIENDS)
            );

            assert!(does_exist);

            let num_friends = analytics::get_field(
                analytics,
                utf8(METRIC_USER_FRIENDS)
            );

            assert!(num_friends == 1);

            let claim = analytics::get_claim(
                analytics,
                object::id_address(&app)
            );

            assert!(claim == WEIGHT_USER_FRIENDS);
        };

        ts::next_tx(scenario, OTHER);
        {
            let custom_payment = mint_for_testing<SUI>(
                UNFRIEND_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                UNFRIEND_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::unfriend_user<SUI>(
                &app,
                &clock,
                &user_fees,
                &mut other_shared_user,
                &mut shared_user,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, OTHER);
        {
            let custom_payment = mint_for_testing<SUI>(
                FRIEND_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                FRIEND_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::friend_user<SUI>(
                &app,
                &clock,
                &reward_weights_registry,
                &user_fees,
                &mut shared_user,
                &mut other_shared_user,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                FRIEND_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                FRIEND_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::friend_user<SUI>(
                &app,
                &clock,
                &reward_weights_registry,
                &user_fees,
                &mut other_shared_user,
                &mut shared_user,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let analytics = user_shared::borrow_or_create_analytics_mut(
                &mut other_shared_user,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let num_friends = analytics::get_field(
                analytics,
                utf8(METRIC_USER_FRIENDS)
            );

            assert!(num_friends == 1);

            let claim = analytics::get_claim(
                analytics,
                object::id_address(&app)
            );

            assert!(claim == WEIGHT_USER_FRIENDS);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let analytics = user_shared::borrow_or_create_analytics_mut(
                &mut shared_user,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let num_friends = analytics::get_field(
                analytics,
                utf8(METRIC_USER_FRIENDS)
            );

            assert!(num_friends == 1);

            let claim = analytics::get_claim(
                analytics,
                object::id_address(&app)
            );

            assert!(claim == WEIGHT_USER_FRIENDS);
        };

        ts::next_tx(scenario, ADMIN);
        {
            ts::return_shared(shared_user);
            ts::return_shared(other_shared_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ENotSelf)]
    fun test_user_actions_friend_add_not_self() {
        let (
            mut scenario_val,
            app,
            clock,
            invite_config,
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
                FRIEND_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                FRIEND_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let mut shared_user = ts::take_shared<UserShared>(scenario);

            user_actions::friend_user<SUI>(
                &app,
                &clock,
                &reward_weights_registry,
                &user_fees,
                &mut shared_user,
                &mut other_shared_user,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(shared_user);
        };

        ts::next_tx(scenario, ADMIN);
        {
            ts::return_shared(other_shared_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_user_actions_friend_incorrect_custom_payment() {
        let (
            mut scenario_val,
            app,
            clock,
            invite_config,
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                FRIEND_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let mut shared_user = ts::take_shared<UserShared>(scenario);

            user_actions::friend_user<SUI>(
                &app,
                &clock,
                &reward_weights_registry,
                &user_fees,
                &mut other_shared_user,
                &mut shared_user,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(shared_user);
        };

        ts::next_tx(scenario, ADMIN);
        {
            ts::return_shared(other_shared_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_user_actions_friend_incorrect_sui_payment() {
        let (
            mut scenario_val,
            app,
            clock,
            invite_config,
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
                FRIEND_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            let mut shared_user = ts::take_shared<UserShared>(scenario);

            user_actions::friend_user<SUI>(
                &app,
                &clock,
                &reward_weights_registry,
                &user_fees,
                &mut other_shared_user,
                &mut shared_user,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(shared_user);
        };

        ts::next_tx(scenario, ADMIN);
        {
            ts::return_shared(other_shared_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ENotSelf)]
    fun test_user_actions_unfriend_not_self() {
        let (
            mut scenario_val,
            app,
            clock,
            invite_config,
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
        let mut shared_user = {
            let custom_payment = mint_for_testing<SUI>(
                FRIEND_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                FRIEND_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let mut shared_user = ts::take_shared<UserShared>(scenario);

            user_actions::friend_user<SUI>(
                &app,
                &clock,
                &reward_weights_registry,
                &user_fees,
                &mut other_shared_user,
                &mut shared_user,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            shared_user
        };

        ts::next_tx(scenario, OTHER);
        {
            let custom_payment = mint_for_testing<SUI>(
                FRIEND_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                FRIEND_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::friend_user<SUI>(
                &app,
                &clock,
                &reward_weights_registry,
                &user_fees,
                &mut shared_user,
                &mut other_shared_user,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, SERVER);
        {
            let custom_payment = mint_for_testing<SUI>(
                UNFRIEND_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                UNFRIEND_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::unfriend_user<SUI>(
                &app,
                &clock,
                &user_fees,
                &mut other_shared_user,
                &mut shared_user,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            ts::return_shared(shared_user);
            ts::return_shared(other_shared_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_user_actions_unfriend_incorrect_custom_payment() {
        let (
            mut scenario_val,
            app,
            clock,
            invite_config,
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
        let mut shared_user = {
            let custom_payment = mint_for_testing<SUI>(
                FRIEND_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                FRIEND_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let mut shared_user = ts::take_shared<UserShared>(scenario);

            user_actions::friend_user<SUI>(
                &app,
                &clock,
                &reward_weights_registry,
                &user_fees,
                &mut other_shared_user,
                &mut shared_user,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            shared_user
        };

        ts::next_tx(scenario, OTHER);
        {
            let custom_payment = mint_for_testing<SUI>(
                FRIEND_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                FRIEND_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::friend_user<SUI>(
                &app,
                &clock,
                &reward_weights_registry,
                &user_fees,
                &mut shared_user,
                &mut other_shared_user,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, OTHER);
        {
            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                UNFRIEND_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::unfriend_user<SUI>(
                &app,
                &clock,
                &user_fees,
                &mut other_shared_user,
                &mut shared_user,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            ts::return_shared(shared_user);
            ts::return_shared(other_shared_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_user_actions_unfriend_incorrect_sui_payment() {
        let (
            mut scenario_val,
            app,
            clock,
            invite_config,
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
        let mut shared_user = {
            let custom_payment = mint_for_testing<SUI>(
                FRIEND_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                FRIEND_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let mut shared_user = ts::take_shared<UserShared>(scenario);

            user_actions::friend_user<SUI>(
                &app,
                &clock,
                &reward_weights_registry,
                &user_fees,
                &mut other_shared_user,
                &mut shared_user,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            shared_user
        };

        ts::next_tx(scenario, OTHER);
        {
            let custom_payment = mint_for_testing<SUI>(
                FRIEND_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                FRIEND_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::friend_user<SUI>(
                &app,
                &clock,
                &reward_weights_registry,
                &user_fees,
                &mut shared_user,
                &mut other_shared_user,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, OTHER);
        {
            let custom_payment = mint_for_testing<SUI>(
                UNFRIEND_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            user_actions::unfriend_user<SUI>(
                &app,
                &clock,
                &user_fees,
                &mut other_shared_user,
                &mut shared_user,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            ts::return_shared(shared_user);
            ts::return_shared(other_shared_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_actions_post() {
        let (
            mut scenario_val,
            app,
            mut clock,
            invite_config,
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
        let timestamp_1 = {
            let mut owned_user = ts::take_from_sender<UserOwned>(scenario);
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
                &mut owned_user,
                &reward_weights_registry,
                &mut shared_user,
                &user_fees,
                &user_witness_config,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            clock::increment_for_testing(
                &mut clock,
                1
            );

            ts::return_to_sender(scenario, owned_user);
            ts::return_shared(shared_user);

            timestamp
        };

        ts::next_tx(scenario, ADMIN);
        let timestamp_2 = {
            let mut owned_user = ts::take_from_sender<UserOwned>(scenario);
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
                &mut owned_user,
                &reward_weights_registry,
                &mut shared_user,
                &user_fees,
                &user_witness_config,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, owned_user);
            ts::return_shared(shared_user);

            timestamp
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut owned_user = ts::take_from_sender<UserOwned>(scenario);
            let mut shared_user = ts::take_shared<UserShared>(scenario);

            let current_epoch = reward_registry::get_current(
                &reward_weights_registry
            );

            let analytics = user_owned::borrow_or_create_analytics_mut(
                &mut owned_user,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let analytics_exists = analytics::field_exists(
                analytics,
                utf8(b"user-text-posts")
            );

            assert!(!analytics_exists);

            let posts = user_shared::take_posts(
                &mut shared_user,
                object::id_address(&app),
                ts::ctx(scenario)
            );

            let has_record = posts::has_record(
                &posts,
                timestamp_1
            );

            assert!(has_record, ENoPostsRecord);

            let has_record = posts::has_record(
                &posts,
                timestamp_2
            );

            assert!(has_record, ENoPostsRecord);

            let length = posts::get_length(&posts);

            assert!(length == 2, EPostsLengthMismatch);

            user_shared::return_posts(
                &mut shared_user,
                object::id_address(&app),
                posts
            );

            ts::return_to_sender(scenario, owned_user);
            ts::return_shared(shared_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_actions_post_rewards() {
        let (
            mut scenario_val,
            mut app,
            mut clock,
            invite_config,
            post_fees,
            mut reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let name = utf8(b"USER-name");

        ts::next_tx(scenario, ADMIN);
        {
            let reward_cap = ts::take_from_sender<RewardCap>(scenario);

            admin_actions::update_app_rewards(
                &reward_cap,
                &mut app,
                true
            );

            reward_actions::start_epochs(
                &reward_cap,
                &clock,
                &mut reward_weights_registry,
                ts::ctx(scenario)
            );

            reward_actions::add_weight(
                &reward_cap,
                &mut reward_weights_registry,
                utf8(METRIC_USER_TEXT_POST),
                WEIGHT_USER_TEXT_POST
            );

            ts::return_to_sender<RewardCap>(scenario, reward_cap);

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
            let mut owned_user = ts::take_from_sender<UserOwned>(scenario);
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
                _timestamp
            ) = user_actions::post<SUI>(
                &app,
                &clock,
                &mut owned_user,
                &reward_weights_registry,
                &mut shared_user,
                &user_fees,
                &user_witness_config,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            clock::increment_for_testing(
                &mut clock,
                1
            );

            ts::return_to_sender(scenario, owned_user);
            ts::return_shared(shared_user);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut owned_user = ts::take_from_sender<UserOwned>(scenario);
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
                _timestamp
            ) = user_actions::post<SUI>(
                &app,
                &clock,
                &mut owned_user,
                &reward_weights_registry,
                &mut shared_user,
                &user_fees,
                &user_witness_config,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, owned_user);
            ts::return_shared(shared_user);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut owned_user = ts::take_from_sender<UserOwned>(scenario);
            let shared_user = ts::take_shared<UserShared>(scenario);

            let current_epoch = reward_registry::get_current(
                &reward_weights_registry
            );

            let analytics = user_owned::borrow_or_create_analytics_mut(
                &mut owned_user,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let analytics_exists = analytics::field_exists(
                analytics,
                utf8(METRIC_USER_TEXT_POST)
            );

            assert!(analytics_exists);

            let num_posts = analytics::get_field(
                analytics,
                utf8(METRIC_USER_TEXT_POST)
            );

            assert!(num_posts == 2);

            let claim = analytics::get_claim(
                analytics,
                object::id_address(&app)
            );

            assert!(claim == (WEIGHT_USER_TEXT_POST * 2));

            ts::return_to_sender(scenario, owned_user);
            ts::return_shared(shared_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
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
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
            let mut owned_user = ts::take_from_sender<UserOwned>(scenario);
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
                &mut owned_user,
                &reward_weights_registry,
                &mut shared_user,
                &user_fees,
                &user_witness_config,
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
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
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
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
            let mut owned_user = ts::take_from_sender<UserOwned>(scenario);
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
                &mut owned_user,
                &reward_weights_registry,
                &mut shared_user,
                &user_fees,
                &user_witness_config,
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
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_actions_comment() {
        let (
            mut scenario_val,
            app,
            mut clock,
            invite_config,
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
        let (
            mut owned_user,
            mut shared_user
        ) = {
            let mut owned_user = ts::take_from_sender<UserOwned>(scenario);
            let mut shared_user = ts::take_shared<UserShared>(scenario);

            let data = utf8(b"parent-data");
            let description = utf8(b"parent-description");
            let title = utf8(b"parent-title");

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
                _timestamp
            ) = user_actions::post<SUI>(
                &app,
                &clock,
                &mut owned_user,
                &reward_weights_registry,
                &mut shared_user,
                &user_fees,
                &user_witness_config,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            clock::increment_for_testing(
                &mut clock,
                1
            );

            (
                owned_user,
                shared_user
            )
        };

        ts::next_tx(scenario, ADMIN);
        let parent_post = {
            let mut parent_post = ts::take_shared<Post>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                POST_FROM_POST_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                POST_FROM_POST_SUI_FEE,
                ts::ctx(scenario)
            );

            let data = utf8(b"child-data");
            let description = utf8(b"child-description");
            let title = utf8(b"child-title");

            let (
                _post_address,
                _self,
                _timestamp
            ) = user_actions::comment<SUI>(
                &app,
                &clock,
                &mut owned_user,
                &mut parent_post,
                &post_fees,
                &reward_weights_registry,
                &mut shared_user,
                &user_witness_config,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            parent_post
        };

        ts::next_tx(scenario, ADMIN);
        {
            let num_comments = post::get_comments_count(&parent_post);

            assert!(num_comments == 1);

            let comment = ts::take_shared<Post>(scenario);

            assert!(comment.get_depth() == 2);

            let current_epoch = reward_registry::get_current(
                &reward_weights_registry
            );

            let analytics_self = user_owned::borrow_or_create_analytics_mut(
                &mut owned_user,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let analytics_exists = analytics::field_exists(
                analytics_self,
                utf8(b"comment-given")
            );

            assert!(!analytics_exists);

            let analytics_author = user_shared::borrow_or_create_analytics_mut(
                &mut shared_user,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let analytics_exists = analytics::field_exists(
                analytics_author,
                utf8(b"comment-received")
            );

            assert!(!analytics_exists);

            destroy(comment);
            destroy(parent_post);

            ts::return_to_sender(scenario, owned_user);
            ts::return_shared(shared_user);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_actions_comment_rewards() {
        let (
            mut scenario_val,
            mut app,
            mut clock,
            invite_config,
            post_fees,
            mut reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");

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
                utf8(b"USER-name"),
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        let (
            mut owned_user_admin,
            mut shared_user_admin
        ) = {
            let owned_user = ts::take_from_sender<UserOwned>(scenario);
            let shared_user = ts::take_shared<UserShared>(scenario);

            (
                owned_user,
                shared_user
            )
        };

        ts::next_tx(scenario, OTHER);
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
                utf8(b"other"),
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, OTHER);
        let (
            mut owned_user_other,
            shared_user_other
        ) = {
            let owned_user = ts::take_from_sender<UserOwned>(scenario);
            let shared_user = ts::take_shared<UserShared>(scenario);

            (
                owned_user,
                shared_user
            )
        };

        ts::next_tx(scenario, ADMIN);
        {
            let data = utf8(b"parent-data");
            let description = utf8(b"parent-description");
            let title = utf8(b"parent-title");

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
                _timestamp
            ) = user_actions::post<SUI>(
                &app,
                &clock,
                &mut owned_user_admin,
                &reward_weights_registry,
                &mut shared_user_admin,
                &user_fees,
                &user_witness_config,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            clock::increment_for_testing(
                &mut clock,
                1
            );
        };

        ts::next_tx(scenario, OTHER);
        let mut parent_post = {
            let mut parent_post = ts::take_shared<Post>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                POST_FROM_POST_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                POST_FROM_POST_SUI_FEE,
                ts::ctx(scenario)
            );

            let data = utf8(b"child-data");
            let description = utf8(b"child-description");
            let title = utf8(b"child-title");

            let (
                _post_address,
                _self,
                _timestamp
            ) = user_actions::comment<SUI>(
                &app,
                &clock,
                &mut owned_user_other,
                &mut parent_post,
                &post_fees,
                &reward_weights_registry,
                &mut shared_user_admin,
                &user_witness_config,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            parent_post
        };

        ts::next_tx(scenario, ADMIN);
        {
            let current_epoch = reward_registry::get_current(
                &reward_weights_registry
            );

            let analytics_self = user_owned::borrow_or_create_analytics_mut(
                &mut owned_user_other,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let analytics_exists = analytics::field_exists(
                analytics_self,
                utf8(METRIC_COMMENT_GIVEN)
            );

            assert!(!analytics_exists);

            let claim = analytics::get_claim(
                analytics_self,
                object::id_address(&app)
            );

            assert!(claim == 0);

            let analytics_author = user_shared::borrow_or_create_analytics_mut(
                &mut shared_user_admin,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let analytics_exists = analytics::field_exists(
                analytics_author,
                utf8(METRIC_COMMENT_RECEIVED)
            );

            assert!(!analytics_exists);

            let claim = analytics::get_claim(
                analytics_author,
                object::id_address(&app)
            );

            assert!(claim == 0);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let reward_cap = ts::take_from_sender<RewardCap>(scenario);

            admin_actions::update_app_rewards(
                &reward_cap,
                &mut app,
                true
            );

            reward_actions::start_epochs(
                &reward_cap,
                &clock,
                &mut reward_weights_registry,
                ts::ctx(scenario)
            );

            reward_actions::add_weight(
                &reward_cap,
                &mut reward_weights_registry,
                utf8(METRIC_COMMENT_GIVEN),
                WEIGHT_COMMENT_GIVEN
            );

            reward_actions::add_weight(
                &reward_cap,
                &mut reward_weights_registry,
                utf8(METRIC_COMMENT_RECEIVED),
                WEIGHT_COMMENT_RECEIVED
            );

            ts::return_to_sender<RewardCap>(scenario, reward_cap);
        };

        ts::next_tx(scenario, ADMIN);
        {
            clock::increment_for_testing(
                &mut clock,
                1
            );

            let custom_payment = mint_for_testing<SUI>(
                POST_FROM_POST_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                POST_FROM_POST_SUI_FEE,
                ts::ctx(scenario)
            );

            let data = utf8(b"child-data");
            let description = utf8(b"child-description");
            let title = utf8(b"child-title");

            let (
                _post_address,
                _self,
                _timestamp
            ) = user_actions::comment<SUI>(
                &app,
                &clock,
                &mut owned_user_admin,
                &mut parent_post,
                &post_fees,
                &reward_weights_registry,
                &mut shared_user_admin,
                &user_witness_config,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let current_epoch = reward_registry::get_current(
                &reward_weights_registry
            );

            let analytics_self = user_owned::borrow_or_create_analytics_mut(
                &mut owned_user_other,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let analytics_exists = analytics::field_exists(
                analytics_self,
                utf8(METRIC_COMMENT_GIVEN)
            );

            assert!(!analytics_exists);

            let claim = analytics::get_claim(
                analytics_self,
                object::id_address(&app)
            );

            assert!(claim == 0);

            let analytics_author = user_shared::borrow_or_create_analytics_mut(
                &mut shared_user_admin,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let analytics_exists = analytics::field_exists(
                analytics_author,
                utf8(METRIC_COMMENT_RECEIVED)
            );

            assert!(!analytics_exists);

            let claim = analytics::get_claim(
                analytics_author,
                object::id_address(&app)
            );

            assert!(claim == 0);
        };

        ts::next_tx(scenario, OTHER);
        {
            clock::increment_for_testing(
                &mut clock,
                1
            );

            let custom_payment = mint_for_testing<SUI>(
                POST_FROM_POST_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                POST_FROM_POST_SUI_FEE,
                ts::ctx(scenario)
            );

            let data = utf8(b"child-data");
            let description = utf8(b"child-description");
            let title = utf8(b"child-title");

            let (
                _post_address,
                _self,
                _timestamp
            ) = user_actions::comment<SUI>(
                &app,
                &clock,
                &mut owned_user_other,
                &mut parent_post,
                &post_fees,
                &reward_weights_registry,
                &mut shared_user_admin,
                &user_witness_config,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let current_epoch = reward_registry::get_current(
                &reward_weights_registry
            );

            let analytics_self = user_owned::borrow_or_create_analytics_mut(
                &mut owned_user_other,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let analytics_exists = analytics::field_exists(
                analytics_self,
                utf8(METRIC_COMMENT_GIVEN)
            );

            assert!(analytics_exists);

            let num_comment_given = analytics::get_field(
                analytics_self,
                utf8(METRIC_COMMENT_GIVEN)
            );

            assert!(num_comment_given == 1);

            let claim = analytics::get_claim(
                analytics_self,
                object::id_address(&app)
            );

            assert!(claim == WEIGHT_COMMENT_GIVEN);

            let analytics_author = user_shared::borrow_or_create_analytics_mut(
                &mut shared_user_admin,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let analytics_exists = analytics::field_exists(
                analytics_author,
                utf8(METRIC_COMMENT_RECEIVED)
            );

            assert!(analytics_exists);

            let num_comment_received = analytics::get_field(
                analytics_author,
                utf8(METRIC_COMMENT_RECEIVED)
            );

            assert!(num_comment_received == 1);

            let claim = analytics::get_claim(
                analytics_author,
                object::id_address(&app)
            );

            assert!(claim == WEIGHT_COMMENT_RECEIVED);

            destroy(parent_post);

            destroy(owned_user_admin);
            destroy(owned_user_other);
            destroy(shared_user_admin);
            destroy(shared_user_other);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ESuppliedAuthorMismatch)]
    fun test_user_actions_comment_author_mismatch() {
        let (
            mut scenario_val,
            mut app,
            mut clock,
            invite_config,
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");

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
                utf8(b"USER-name"),
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        let (
            mut owned_user_admin,
            mut shared_user_admin
        ) = {
            let owned_user = ts::take_from_sender<UserOwned>(scenario);
            let shared_user = ts::take_shared<UserShared>(scenario);

            (
                owned_user,
                shared_user
            )
        };

        ts::next_tx(scenario, OTHER);
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
                utf8(b"other"),
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, OTHER);
        let (
            mut owned_user_other,
            mut shared_user_other
        ) = {
            let owned_user = ts::take_from_sender<UserOwned>(scenario);
            let shared_user = ts::take_shared<UserShared>(scenario);

            (
                owned_user,
                shared_user
            )
        };

        ts::next_tx(scenario, ADMIN);
        {
            let data = utf8(b"parent-data");
            let description = utf8(b"parent-description");
            let title = utf8(b"parent-title");

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
                _timestamp
            ) = user_actions::post<SUI>(
                &app,
                &clock,
                &mut owned_user_admin,
                &reward_weights_registry,
                &mut shared_user_admin,
                &user_fees,
                &user_witness_config,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let reward_cap = ts::take_from_sender<RewardCap>(scenario);

            admin_actions::update_app_rewards(
                &reward_cap,
                &mut app,
                true
            );

            ts::return_to_sender<RewardCap>(scenario, reward_cap);
        };

        ts::next_tx(scenario, OTHER);
        {
            let mut parent_post = ts::take_shared<Post>(scenario);

            clock::increment_for_testing(
                &mut clock,
                1
            );

            let custom_payment = mint_for_testing<SUI>(
                POST_FROM_POST_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                POST_FROM_POST_SUI_FEE,
                ts::ctx(scenario)
            );

            let data = utf8(b"child-data");
            let description = utf8(b"child-description");
            let title = utf8(b"child-title");

            let (
                _post_address,
                _self,
                _timestamp
            ) = user_actions::comment<SUI>(
                &app,
                &clock,
                &mut owned_user_other,
                &mut parent_post,
                &post_fees,
                &reward_weights_registry,
                &mut shared_user_other,
                &user_witness_config,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            destroy(parent_post);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy(owned_user_admin);
            destroy(owned_user_other);
            destroy(shared_user_admin);
            destroy(shared_user_other);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_actions_like_post() {
        let (
            mut scenario_val,
            mut app,
            clock,
            invite_config,
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");

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
                utf8(b"USER-name"),
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        let (
            mut owned_user_admin,
            mut shared_user_admin
        ) = {
            let owned_user = ts::take_from_sender<UserOwned>(scenario);
            let shared_user = ts::take_shared<UserShared>(scenario);

            (
                owned_user,
                shared_user
            )
        };

        ts::next_tx(scenario, OTHER);
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
                utf8(b"other"),
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, OTHER);
        let (
            mut owned_user_other,
            shared_user_other
        ) = {
            let owned_user = ts::take_from_sender<UserOwned>(scenario);
            let shared_user = ts::take_shared<UserShared>(scenario);

            (
                owned_user,
                shared_user
            )
        };

        ts::next_tx(scenario, ADMIN);
        {
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
                _timestamp
            ) = user_actions::post<SUI>(
                &app,
                &clock,
                &mut owned_user_admin,
                &reward_weights_registry,
                &mut shared_user_admin,
                &user_fees,
                &user_witness_config,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        let royalties = {
            let royalties = fees::create_for_testing<SUI>(
                &mut app,
                0,
                TREASURY,
                0,
                TREASURY,
                ts::ctx(scenario)
            );

            royalties
        };

        ts::next_tx(scenario, OTHER);
        let post = {
            let mut post = ts::take_shared<Post>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                LIKE_POST_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                LIKE_POST_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::like_post<SUI>(
                &app,
                &clock,
                &mut owned_user_other,
                &mut post,
                &post_fees,
                &reward_weights_registry,
                &royalties,
                &mut shared_user_admin,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            post
        };

        ts::next_tx(scenario, ADMIN);
        {
            let num_likes = post::get_likes_count(&post);

            assert!(num_likes == 1);

            let current_epoch = reward_registry::get_current(
                &reward_weights_registry
            );

            let analytics_author = user_shared::borrow_or_create_analytics_mut(
                &mut shared_user_admin,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let analytics_exists = analytics::field_exists(
                analytics_author,
                utf8(b"post-liked")
            );

            assert!(!analytics_exists);

            let analytics_liker = user_owned::borrow_or_create_analytics_mut(
                &mut owned_user_other,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let analytics_exists = analytics::field_exists(
                analytics_liker,
                utf8(b"liked-post")
            );

            assert!(!analytics_exists);

            destroy(owned_user_admin);
            destroy(shared_user_admin);
            destroy(owned_user_other);
            destroy(shared_user_other);

            destroy(post);
            destroy(royalties);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

      #[test]
    fun test_user_actions_like_post_rewards() {
        let (
            mut scenario_val,
            mut app,
            clock,
            invite_config,
            post_fees,
            mut reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");

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
                utf8(b"USER-name"),
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        let (
            mut owned_user_admin,
            mut shared_user_admin
        ) = {
            let owned_user = ts::take_from_sender<UserOwned>(scenario);
            let shared_user = ts::take_shared<UserShared>(scenario);

            (
                owned_user,
                shared_user
            )
        };

        ts::next_tx(scenario, OTHER);
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
                utf8(b"other"),
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, OTHER);
        let (
            mut owned_user_other,
            shared_user_other
        ) = {
            let owned_user = ts::take_from_sender<UserOwned>(scenario);
            let shared_user = ts::take_shared<UserShared>(scenario);

            (
                owned_user,
                shared_user
            )
        };

        ts::next_tx(scenario, ADMIN);
        {
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
                _timestamp
            ) = user_actions::post<SUI>(
                &app,
                &clock,
                &mut owned_user_admin,
                &reward_weights_registry,
                &mut shared_user_admin,
                &user_fees,
                &user_witness_config,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let reward_cap = ts::take_from_sender<RewardCap>(scenario);

            admin_actions::update_app_rewards(
                &reward_cap,
                &mut app,
                true
            );

            reward_actions::start_epochs(
                &reward_cap,
                &clock,
                &mut reward_weights_registry,
                ts::ctx(scenario)
            );

            reward_actions::add_weight(
                &reward_cap,
                &mut reward_weights_registry,
                utf8(METRIC_LIKED_POST),
                WEIGHT_USER_LIKED_POST
            );

            reward_actions::add_weight(
                &reward_cap,
                &mut reward_weights_registry,
                utf8(METRIC_POST_LIKED),
                WEIGHT_USER_POST_LIKED
            );

            ts::return_to_sender<RewardCap>(scenario, reward_cap);
        };

        ts::next_tx(scenario, ADMIN);
        let royalties = {
            let royalties = fees::create_for_testing<SUI>(
                &mut app,
                0,
                TREASURY,
                0,
                TREASURY,
                ts::ctx(scenario)
            );

            royalties
        };

        ts::next_tx(scenario, ADMIN);
        let mut post = {
            let mut post = ts::take_shared<Post>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                LIKE_POST_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                LIKE_POST_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::like_post<SUI>(
                &app,
                &clock,
                &mut owned_user_admin,
                &mut post,
                &post_fees,
                &reward_weights_registry,
                &royalties,
                &mut shared_user_admin,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            post
        };

        ts::next_tx(scenario, ADMIN);
        {
            let num_likes = post::get_likes_count(&post);

            assert!(num_likes == 1);

            let current_epoch = reward_registry::get_current(
                &reward_weights_registry
            );

            let analytics_author = user_shared::borrow_or_create_analytics_mut(
                &mut shared_user_admin,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let analytics_exists = analytics::field_exists(
                analytics_author,
                utf8(METRIC_POST_LIKED)
            );

            assert!(!analytics_exists);

            let num_liked = analytics::get_field(
                analytics_author,
                utf8(METRIC_POST_LIKED)
            );

            assert!(num_liked == 0);

            let claim_author = analytics::get_claim(
                analytics_author,
                object::id_address(&app)
            );

            assert!(claim_author == 0);

            let analytics_liker = user_owned::borrow_or_create_analytics_mut(
                &mut owned_user_other,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let analytics_exists = analytics::field_exists(
                analytics_liker,
                utf8(METRIC_LIKED_POST)
            );

            assert!(!analytics_exists);

            let num_liked = analytics::get_field(
                analytics_liker,
                utf8(METRIC_LIKED_POST)
            );

            assert!(num_liked == 0);

            let claim_liker = analytics::get_claim(
                analytics_liker,
                object::id_address(&app)
            );

            assert!(claim_liker == 0);
        };

        ts::next_tx(scenario, OTHER);
        {
            let custom_payment = mint_for_testing<SUI>(
                LIKE_POST_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                LIKE_POST_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::like_post<SUI>(
                &app,
                &clock,
                &mut owned_user_other,
                &mut post,
                &post_fees,
                &reward_weights_registry,
                &royalties,
                &mut shared_user_admin,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let num_likes = post::get_likes_count(&post);

            assert!(num_likes == 2);

            let current_epoch = reward_registry::get_current(
                &reward_weights_registry
            );

            let analytics_author = user_shared::borrow_or_create_analytics_mut(
                &mut shared_user_admin,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let analytics_exists = analytics::field_exists(
                analytics_author,
                utf8(METRIC_POST_LIKED)
            );

            assert!(analytics_exists);

            let num_liked = analytics::get_field(
                analytics_author,
                utf8(METRIC_POST_LIKED)
            );

            assert!(num_liked == 1);

            let claim_author = analytics::get_claim(
                analytics_author,
                object::id_address(&app)
            );

            assert!(claim_author == WEIGHT_USER_POST_LIKED);

            let analytics_liker = user_owned::borrow_or_create_analytics_mut(
                &mut owned_user_other,
                &user_witness_config,
                object::id_address(&app),
                current_epoch,
                ts::ctx(scenario)
            );

            let analytics_exists = analytics::field_exists(
                analytics_liker,
                utf8(METRIC_LIKED_POST)
            );

            assert!(analytics_exists);

            let num_liked = analytics::get_field(
                analytics_liker,
                utf8(METRIC_LIKED_POST)
            );

            assert!(num_liked == 1);

            let claim_liker = analytics::get_claim(
                analytics_liker,
                object::id_address(&app)
            );

            assert!(claim_liker == WEIGHT_USER_LIKED_POST);

            destroy(owned_user_admin);
            destroy(shared_user_admin);
            destroy(owned_user_other);
            destroy(shared_user_other);

            destroy(post);
            destroy(royalties);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ESuppliedAuthorMismatch)]
    fun test_user_actions_like_post_rewards_author_mismatch() {
        let (
            mut scenario_val,
            mut app,
            clock,
            invite_config,
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");

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
                utf8(b"USER-name"),
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        let (
            mut owned_user_admin,
            mut shared_user_admin
        ) = {
            let owned_user = ts::take_from_sender<UserOwned>(scenario);
            let shared_user = ts::take_shared<UserShared>(scenario);

            (
                owned_user,
                shared_user
            )
        };

        ts::next_tx(scenario, OTHER);
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
                utf8(b"other"),
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, OTHER);
        let (
            mut owned_user_other,
            mut shared_user_other
        ) = {
            let owned_user = ts::take_from_sender<UserOwned>(scenario);
            let shared_user = ts::take_shared<UserShared>(scenario);

            (
                owned_user,
                shared_user
            )
        };

        ts::next_tx(scenario, ADMIN);
        {
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
                _timestamp
            ) = user_actions::post<SUI>(
                &app,
                &clock,
                &mut owned_user_admin,
                &reward_weights_registry,
                &mut shared_user_admin,
                &user_fees,
                &user_witness_config,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        let royalties = {
            let royalties = fees::create_for_testing<SUI>(
                &mut app,
                0,
                TREASURY,
                0,
                TREASURY,
                ts::ctx(scenario)
            );

            royalties
        };

        ts::next_tx(scenario, OTHER);
        {
            let mut post = ts::take_shared<Post>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                LIKE_POST_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                LIKE_POST_SUI_FEE,
                ts::ctx(scenario)
            );

            user_actions::like_post<SUI>(
                &app,
                &clock,
                &mut owned_user_other,
                &mut post,
                &post_fees,
                &reward_weights_registry,
                &royalties,
                &mut shared_user_other,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            destroy(owned_user_admin);
            destroy(shared_user_admin);
            destroy(owned_user_other);
            destroy(shared_user_other);

            destroy(post);
            destroy(royalties);

            destroy_for_testing(
                app,
                clock,
                invite_config,
                owned_user_config,
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
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
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
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
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
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
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
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
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
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
            post_fees,
            reward_weights_registry,
            owned_user_config,
            mut user_registry,
            mut user_invite_registry,
            user_fees,
            user_witness_config
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
                post_fees,
                reward_weights_registry,
                user_registry,
                user_invite_registry,
                user_fees,
                user_witness_config
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
