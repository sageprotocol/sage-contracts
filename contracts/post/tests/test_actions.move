#[test_only]
module sage_post::test_post_actions {
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
            ChannelWitnessConfig,
            GroupWitnessConfig,
            UserOwnedConfig,
            UserWitnessConfig,
            ValidType,
            InvalidWitness,
            ValidWitness,
            EWitnessMismatch
        },
        admin::{
            Self,
            AdminCap,
            FeeCap
        },
        apps::{Self, App},
        fees::{Self, Royalties}
    };

    use sage_post::{
        post::{Self, Post},
        post_actions::{Self},
        post_fees::{
            Self,
            EIncorrectCustomPayment,
            EIncorrectSuiPayment,
            PostFees
        }
    };

    use sage_shared::{
        likes::{Self},
        posts::{Self}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;
    const TREASURY: address = @0xFADE;

    const LIKE_POST_CUSTOM_FEE: u64 = 1;
    const LIKE_POST_SUI_FEE: u64 = 2;
    const POST_FROM_POST_CUSTOM_FEE: u64 = 3;
    const POST_FROM_POST_SUI_FEE: u64 = 4;

    const INCORRECT_FEE: u64 = 100;

    // --------------- Errors ---------------

    const EAuthorMismatch: u64 = 0;
    const EHasPostsRecord: u64 = 1;
    const ELikesMismatch: u64 = 2;
    const ENoLikeRecord: u64 = 3;
    const EPostsLengthMismatch: u64 = 4;
    const ETimestampMismatch: u64 = 5;

    // --------------- Test Functions ---------------

    #[test_only]
    fun destroy_for_testing(
        app: App,
        channel_witness_config: ChannelWitnessConfig,
        clock: Clock,
        group_witness_config: GroupWitnessConfig,
        owned_user_config: UserOwnedConfig,
        user_witness_config: UserWitnessConfig,
        post_fees: PostFees,
        royalties: Royalties,
        valid_type: ValidType
    ) {
        destroy(app);
        destroy(channel_witness_config);
        ts::return_shared(clock);
        destroy(group_witness_config);
        destroy(owned_user_config);
        destroy(user_witness_config);
        destroy(post_fees);
        destroy(royalties);
        destroy(valid_type);
    }

    #[test_only]
    fun setup_for_testing(): (
        Scenario,
        App,
        ChannelWitnessConfig,
        Clock,
        GroupWitnessConfig,
        UserOwnedConfig,
        UserWitnessConfig,
        PostFees,
        Royalties,
        ValidType,
        ValidWitness
    ) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            access::create_owned_user_config<ValidType>(
                &admin_cap,
                ts::ctx(scenario)
            );

            access::create_channel_witness_config<ValidWitness>(
                &admin_cap,
                ts::ctx(scenario)
            );
            access::create_group_witness_config<ValidWitness>(
                &admin_cap,
                ts::ctx(scenario)
            );
            access::create_user_witness_config<ValidWitness>(
                &admin_cap,
                ts::ctx(scenario)
            );

            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);

            ts::return_to_sender(scenario, admin_cap);
        };

        ts::next_tx(scenario, ADMIN);
        let (
            app,
            channel_witness_config,
            clock,
            group_witness_config,
            owned_user_config,
            user_witness_config,
            royalties,
            valid_type,
            valid_witness
        ) = {
            let mut app = apps::create_for_testing(
                utf8(b"sage"),
                ts::ctx(scenario)
            );
            
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            let clock = ts::take_shared<Clock>(scenario);

            let owned_user_config = ts::take_shared<UserOwnedConfig>(
                scenario
            );

            let channel_witness_config = ts::take_shared<ChannelWitnessConfig>(
                scenario
            );
            let group_witness_config = ts::take_shared<GroupWitnessConfig>(
                scenario
            );
            let user_witness_config = ts::take_shared<UserWitnessConfig>(
                scenario
            );

            let royalties = fees::create_for_testing<SUI>(
                &mut app,
                0,
                TREASURY,
                0,
                TREASURY,
                ts::ctx(scenario)
            );

            let valid_type = access::create_valid_type_for_testing(
                ts::ctx(scenario)
            );

            let valid_witness = access::create_valid_witness_for_testing();

            post_fees::create<SUI>(
                &fee_cap,
                &mut app,
                LIKE_POST_CUSTOM_FEE,
                LIKE_POST_SUI_FEE,
                POST_FROM_POST_CUSTOM_FEE,
                POST_FROM_POST_SUI_FEE,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, fee_cap);

            (
                app,
                channel_witness_config,
                clock,
                group_witness_config,
                owned_user_config,
                user_witness_config,
                royalties,
                valid_type,
                valid_witness
            )
        };

        ts::next_tx(scenario, ADMIN);
        let post_fees = {
            let post_fees = ts::take_shared<PostFees>(scenario);

            post_fees
        };

        (
            scenario_val,
            app,
            channel_witness_config,
            clock,
            group_witness_config,
            owned_user_config,
            user_witness_config,
            post_fees,
            royalties,
            valid_type,
            valid_witness
        )
    }

    #[test]
    fun test_post_actions_init() {
        let (
            mut scenario_val,
            app,
            channel_witness_config,
            clock,
            group_witness_config,
            owned_user_config,
            user_witness_config,
            post_fees,
            royalties,
            valid_type,
            _valid_witness
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                app,
                channel_witness_config,
                clock,
                group_witness_config,
                owned_user_config,
                user_witness_config,
                post_fees,
                royalties,
                valid_type
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_post_actions_create_for_channel() {
        let (
            mut scenario_val,
            app,
            channel_witness_config,
            clock,
            group_witness_config,
            owned_user_config,
            user_witness_config,
            post_fees,
            royalties,
            valid_type,
            valid_witness
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        let timestamp = {
            let owned_user = access::create_valid_type_for_testing(
                ts::ctx(scenario)
            );

            let mut posts = posts::create(ts::ctx(scenario));

            let data = utf8(b"data");
            let description = utf8(b"description");
            let title = utf8(b"title");

            let (
                _post_address,
                self,
                timestamp
            ) = post_actions::create_for_channel<ValidWitness>(
                &app,
                &valid_witness,
                &channel_witness_config,
                &clock,
                &mut posts,
                data,
                description,
                title,
                ts::ctx(scenario)
            );

            let has_record = posts::has_record(
                &posts,
                timestamp
            );

            assert!(has_record, EHasPostsRecord);
            assert!(self == ADMIN, EAuthorMismatch);

            let length = posts::get_length(&posts);

            assert!(length == 1, EPostsLengthMismatch);

            destroy(owned_user);
            destroy(posts);

            timestamp
        };

        ts::next_tx(scenario, ADMIN);
        {
            let post = ts::take_shared<Post>(scenario);

            let retrieved_created_at = post::get_created_at(&post);

            assert!(retrieved_created_at == timestamp, ETimestampMismatch);

            let retrieved_updated_at = post::get_updated_at(&post);

            assert!(retrieved_updated_at == timestamp, ETimestampMismatch);

            ts::return_shared(post);

            destroy_for_testing(
                app,
                channel_witness_config,
                clock,
                group_witness_config,
                owned_user_config,
                user_witness_config,
                post_fees,
                royalties,
                valid_type
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EWitnessMismatch)]
    fun test_post_actions_create_for_channel_witness_fail() {
        let (
            mut scenario_val,
            app,
            channel_witness_config,
            clock,
            group_witness_config,
            owned_user_config,
            user_witness_config,
            post_fees,
            royalties,
            valid_type,
            _valid_witness
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let owned_user = access::create_invalid_type_for_testing(
                ts::ctx(scenario)
            );

            let mut posts = posts::create(ts::ctx(scenario));

            let data = utf8(b"data");
            let description = utf8(b"description");
            let title = utf8(b"title");

            let invalid_witness = access::create_invalid_witness_for_testing();

            let (
                _post_address,
                _self,
                _timestamp
            ) = post_actions::create_for_channel<InvalidWitness>(
                &app,
                &invalid_witness,
                &channel_witness_config,
                &clock,
                &mut posts,
                data,
                description,
                title,
                ts::ctx(scenario)
            );

            destroy(owned_user);
            destroy(posts);

            destroy_for_testing(
                app,
                channel_witness_config,
                clock,
                group_witness_config,
                owned_user_config,
                user_witness_config,
                post_fees,
                royalties,
                valid_type
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_post_actions_create_for_group() {
        let (
            mut scenario_val,
            app,
            channel_witness_config,
            clock,
            group_witness_config,
            owned_user_config,
            user_witness_config,
            post_fees,
            royalties,
            valid_type,
            valid_witness
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        let timestamp = {
            let owned_user = access::create_valid_type_for_testing(
                ts::ctx(scenario)
            );

            let mut posts = posts::create(ts::ctx(scenario));

            let data = utf8(b"data");
            let description = utf8(b"description");
            let title = utf8(b"title");

            let (
                _post_address,
                self,
                timestamp
            ) = post_actions::create_for_group<ValidWitness>(
                &app,
                &clock,
                &valid_witness,
                &group_witness_config,
                &mut posts,
                data,
                description,
                title,
                ts::ctx(scenario)
            );

            let has_record = posts::has_record(
                &posts,
                timestamp
            );

            assert!(has_record, EHasPostsRecord);
            assert!(self == ADMIN, EAuthorMismatch);

            let length = posts::get_length(&posts);

            assert!(length == 1, EPostsLengthMismatch);

            destroy(owned_user);
            destroy(posts);

            timestamp
        };

        ts::next_tx(scenario, ADMIN);
        {
            let post = ts::take_shared<Post>(scenario);

            let retrieved_created_at = post::get_created_at(&post);

            assert!(retrieved_created_at == timestamp, ETimestampMismatch);

            let retrieved_updated_at = post::get_updated_at(&post);

            assert!(retrieved_updated_at == timestamp, ETimestampMismatch);

            ts::return_shared(post);

            destroy_for_testing(
                app,
                channel_witness_config,
                clock,
                group_witness_config,
                owned_user_config,
                user_witness_config,
                post_fees,
                royalties,
                valid_type
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EWitnessMismatch)]
    fun test_post_actions_create_for_group_witness_fail() {
        let (
            mut scenario_val,
            app,
            channel_witness_config,
            clock,
            group_witness_config,
            owned_user_config,
            user_witness_config,
            post_fees,
            royalties,
            valid_type,
            _valid_witness
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let owned_user = access::create_invalid_type_for_testing(
                ts::ctx(scenario)
            );

            let mut posts = posts::create(ts::ctx(scenario));

            let data = utf8(b"data");
            let description = utf8(b"description");
            let title = utf8(b"title");

            let invalid_witness = access::create_invalid_witness_for_testing();

            let (
                _post_address,
                _self,
                _timestamp
            ) = post_actions::create_for_group<InvalidWitness>(
                &app,
                &clock,
                &invalid_witness,
                &group_witness_config,
                &mut posts,
                data,
                description,
                title,
                ts::ctx(scenario)
            );

            destroy(owned_user);
            destroy(posts);

            destroy_for_testing(
                app,
                channel_witness_config,
                clock,
                group_witness_config,
                owned_user_config,
                user_witness_config,
                post_fees,
                royalties,
                valid_type
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_post_actions_create_for_user() {
        let (
            mut scenario_val,
            app,
            channel_witness_config,
            clock,
            group_witness_config,
            owned_user_config,
            user_witness_config,
            post_fees,
            royalties,
            valid_type,
            valid_witness
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        let timestamp = {
            let owned_user = access::create_valid_type_for_testing(
                ts::ctx(scenario)
            );

            let mut posts = posts::create(ts::ctx(scenario));

            let data = utf8(b"data");
            let description = utf8(b"description");
            let title = utf8(b"title");

            let (
                _post_address,
                self,
                timestamp
            ) = post_actions::create_for_user<ValidWitness>(
                &app,
                &clock,
                &mut posts,
                &valid_witness,
                &user_witness_config,
                data,
                description,
                title,
                ts::ctx(scenario)
            );

            let has_record = posts::has_record(
                &posts,
                timestamp
            );

            assert!(has_record, EHasPostsRecord);
            assert!(self == ADMIN, EAuthorMismatch);

            let length = posts::get_length(&posts);

            assert!(length == 1, EPostsLengthMismatch);

            destroy(owned_user);
            destroy(posts);

            timestamp
        };

        ts::next_tx(scenario, ADMIN);
        {
            let post = ts::take_shared<Post>(scenario);

            let retrieved_created_at = post::get_created_at(&post);

            assert!(retrieved_created_at == timestamp, ETimestampMismatch);

            let retrieved_updated_at = post::get_updated_at(&post);

            assert!(retrieved_updated_at == timestamp, ETimestampMismatch);

            ts::return_shared(post);

            destroy_for_testing(
                app,
                channel_witness_config,
                clock,
                group_witness_config,
                owned_user_config,
                user_witness_config,
                post_fees,
                royalties,
                valid_type
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EWitnessMismatch)]
    fun test_post_actions_create_for_user_witness_fail() {
        let (
            mut scenario_val,
            app,
            channel_witness_config,
            clock,
            group_witness_config,
            owned_user_config,
            user_witness_config,
            post_fees,
            royalties,
            valid_type,
            _valid_witness
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let owned_user = access::create_invalid_type_for_testing(
                ts::ctx(scenario)
            );

            let mut posts = posts::create(ts::ctx(scenario));

            let data = utf8(b"data");
            let description = utf8(b"description");
            let title = utf8(b"title");

            let invalid_witness = access::create_invalid_witness_for_testing();

            let (
                _post_address,
                _self,
                _timestamp
            ) = post_actions::create_for_user<InvalidWitness>(
                &app,
                &clock,
                &mut posts,
                &invalid_witness,
                &user_witness_config,
                data,
                description,
                title,
                ts::ctx(scenario)
            );

            destroy(owned_user);
            destroy(posts);

            destroy_for_testing(
                app,
                channel_witness_config,
                clock,
                group_witness_config,
                owned_user_config,
                user_witness_config,
                post_fees,
                royalties,
                valid_type
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_post_actions_comment() {
        let (
            mut scenario_val,
            app,
            channel_witness_config,
            clock,
            group_witness_config,
            owned_user_config,
            user_witness_config,
            post_fees,
            royalties,
            valid_type,
            valid_witness
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        let owned_user = {
            let owned_user = access::create_valid_type_for_testing(
                ts::ctx(scenario)
            );

            let mut posts = posts::create(ts::ctx(scenario));

            let data = utf8(b"data");
            let description = utf8(b"description");
            let title = utf8(b"title");

            let (
                _post_address,
                _self,
                _timestamp
            ) = post_actions::create_for_channel<ValidWitness>(
                &app,
                &valid_witness,
                &channel_witness_config,
                &clock,
                &mut posts,
                data,
                description,
                title,
                ts::ctx(scenario)
            );

            destroy(posts);

            owned_user
        };

        ts::next_tx(scenario, ADMIN);
        let (
            self,
            timestamp
        ) = {
            let mut parent_post = ts::take_shared<Post>(scenario);

            let data = utf8(b"data");
            let description = utf8(b"description");
            let title = utf8(b"title");

            let custom_payment = mint_for_testing<SUI>(
                POST_FROM_POST_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                POST_FROM_POST_SUI_FEE,
                ts::ctx(scenario)
            );

            let (
                _comment_address,
                self,
                timestamp
            ) = post_actions::comment_for_user<SUI, ValidWitness>(
                &app,
                &clock,
                &mut parent_post,
                &post_fees,
                &valid_witness,
                &user_witness_config,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(parent_post);

            (self, timestamp)
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut comment = ts::take_shared<Post>(scenario);

            let retrieved_author = post::get_author(&comment);

            assert!(self == retrieved_author, EAuthorMismatch);

            let retrieved_created_at = post::get_created_at(&comment);

            assert!(retrieved_created_at == timestamp, ETimestampMismatch);

            let retrieved_updated_at = post::get_updated_at(&comment);

            assert!(retrieved_updated_at == timestamp, ETimestampMismatch);

            let posts = post::borrow_posts_mut(&mut comment);

            let has_record = posts::has_record(posts, timestamp);

            assert!(has_record, EHasPostsRecord);

            let length = posts::get_length(posts);

            assert!(length == 1, EPostsLengthMismatch);

            ts::return_shared(comment);

            destroy(owned_user);

            destroy_for_testing(
                app,
                channel_witness_config,
                clock,
                group_witness_config,
                owned_user_config,
                user_witness_config,
                post_fees,
                royalties,
                valid_type
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EWitnessMismatch)]
    fun test_post_actions_comment_witness_fail() {
        let (
            mut scenario_val,
            app,
            channel_witness_config,
            clock,
            group_witness_config,
            owned_user_config,
            user_witness_config,
            post_fees,
            royalties,
            valid_type,
            valid_witness
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let owned_user = access::create_valid_type_for_testing(
                ts::ctx(scenario)
            );

            let mut posts = posts::create(ts::ctx(scenario));

            let data = utf8(b"data");
            let description = utf8(b"description");
            let title = utf8(b"title");

            let (
                _post_address,
                _self,
                _timestamp
            ) = post_actions::create_for_channel<ValidWitness>(
                &app,
                &valid_witness,
                &channel_witness_config,
                &clock,
                &mut posts,
                data,
                description,
                title,
                ts::ctx(scenario)
            );

            destroy(owned_user);
            destroy(posts);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut parent_post = ts::take_shared<Post>(scenario);

            let data = utf8(b"data");
            let description = utf8(b"description");
            let title = utf8(b"title");

            let owned_user = access::create_invalid_type_for_testing(
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                POST_FROM_POST_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                POST_FROM_POST_SUI_FEE,
                ts::ctx(scenario)
            );

            let invalid_witness = access::create_invalid_witness_for_testing();

            let (
                _comment_address,
                _self,
                _timestamp
            ) = post_actions::comment_for_user<SUI, InvalidWitness>(
                &app,
                &clock,
                &mut parent_post,
                &post_fees,
                &invalid_witness,
                &user_witness_config,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(parent_post);

            destroy(owned_user);

            destroy_for_testing(
                app,
                channel_witness_config,
                clock,
                group_witness_config,
                owned_user_config,
                user_witness_config,
                post_fees,
                royalties,
                valid_type
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_post_actions_comment_incorrect_custom_payment() {
        let (
            mut scenario_val,
            app,
            channel_witness_config,
            clock,
            group_witness_config,
            owned_user_config,
            user_witness_config,
            post_fees,
            royalties,
            valid_type,
            valid_witness
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        let owned_user = {
            let owned_user = access::create_valid_type_for_testing(
                ts::ctx(scenario)
            );

            let mut posts = posts::create(ts::ctx(scenario));

            let data = utf8(b"data");
            let description = utf8(b"description");
            let title = utf8(b"title");

            let (
                _post_address,
                _self,
                _timestamp
            ) = post_actions::create_for_channel<ValidWitness>(
                &app,
                &valid_witness,
                &channel_witness_config,
                &clock,
                &mut posts,
                data,
                description,
                title,
                ts::ctx(scenario)
            );

            destroy(posts);

            owned_user
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut parent_post = ts::take_shared<Post>(scenario);

            let data = utf8(b"data");
            let description = utf8(b"description");
            let title = utf8(b"title");

            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                POST_FROM_POST_SUI_FEE,
                ts::ctx(scenario)
            );

            let (
                _comment_address,
                _self,
                _timestamp
            ) = post_actions::comment_for_user<SUI, ValidWitness>(
                &app,
                &clock,
                &mut parent_post,
                &post_fees,
                &valid_witness,
                &user_witness_config,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            destroy(owned_user);

            ts::return_shared(parent_post);

            destroy_for_testing(
                app,
                channel_witness_config,
                clock,
                group_witness_config,
                owned_user_config,
                user_witness_config,
                post_fees,
                royalties,
                valid_type
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_post_actions_comment_incorrect_sui_payment() {
        let (
            mut scenario_val,
            app,
            channel_witness_config,
            clock,
            group_witness_config,
            owned_user_config,
            user_witness_config,
            post_fees,
            royalties,
            valid_type,
            valid_witness
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        let owned_user = {
            let owned_user = access::create_valid_type_for_testing(
                ts::ctx(scenario)
            );

            let mut posts = posts::create(ts::ctx(scenario));

            let data = utf8(b"data");
            let description = utf8(b"description");
            let title = utf8(b"title");

            let (
                _post_address,
                _self,
                _timestamp
            ) = post_actions::create_for_channel<ValidWitness>(
                &app,
                &valid_witness,
                &channel_witness_config,
                &clock,
                &mut posts,
                data,
                description,
                title,
                ts::ctx(scenario)
            );

            destroy(posts);

            owned_user
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut parent_post = ts::take_shared<Post>(scenario);

            let data = utf8(b"data");
            let description = utf8(b"description");
            let title = utf8(b"title");

            let custom_payment = mint_for_testing<SUI>(
                POST_FROM_POST_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            let (
                _comment_address,
                _self,
                _timestamp
            ) = post_actions::comment_for_user<SUI, ValidWitness>(
                &app,
                &clock,
                &mut parent_post,
                &post_fees,
                &valid_witness,
                &user_witness_config,
                data,
                description,
                title,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            destroy(owned_user);
            
            ts::return_shared(parent_post);

            destroy_for_testing(
                app,
                channel_witness_config,
                clock,
                group_witness_config,
                owned_user_config,
                user_witness_config,
                post_fees,
                royalties,
                valid_type
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_post_actions_like() {
        let (
            mut scenario_val,
            app,
            channel_witness_config,
            clock,
            group_witness_config,
            owned_user_config,
            user_witness_config,
            post_fees,
            royalties,
            valid_type,
            valid_witness
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        let owned_user = {
            let owned_user = access::create_valid_type_for_testing(
                ts::ctx(scenario)
            );

            let mut posts = posts::create(ts::ctx(scenario));

            let data = utf8(b"data");
            let description = utf8(b"description");
            let title = utf8(b"title");

            let (
                _post_address,
                _self,
                _timestamp
            ) = post_actions::create_for_channel<ValidWitness>(
                &app,
                &valid_witness,
                &channel_witness_config,
                &clock,
                &mut posts,
                data,
                description,
                title,
                ts::ctx(scenario)
            );

            destroy(posts);

            owned_user
        };

        ts::next_tx(scenario, ADMIN);
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

            post_actions::like_for_user<SUI, ValidWitness>(
                &clock,
                &mut post,
                &post_fees,
                &royalties,
                &valid_witness,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            let likes = post::borrow_likes_mut(&mut post);

            let has_liked = likes::has_liked(
                likes,
                ADMIN
            );

            assert!(has_liked, ENoLikeRecord);

            let length = likes::get_length(likes);

            assert!(length == 1, ELikesMismatch);

            destroy(owned_user);

            ts::return_shared(post);

            destroy_for_testing(
                app,
                channel_witness_config,
                clock,
                group_witness_config,
                owned_user_config,
                user_witness_config,
                post_fees,
                royalties,
                valid_type
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EWitnessMismatch)]
    fun test_post_actions_like_witness_fail() {
        let (
            mut scenario_val,
            app,
            channel_witness_config,
            clock,
            group_witness_config,
            owned_user_config,
            user_witness_config,
            post_fees,
            royalties,
            valid_type,
            valid_witness
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let owned_user = access::create_valid_type_for_testing(
                ts::ctx(scenario)
            );

            let mut posts = posts::create(ts::ctx(scenario));

            let data = utf8(b"data");
            let description = utf8(b"description");
            let title = utf8(b"title");

            let (
                _post_address,
                _self,
                _timestamp
            ) = post_actions::create_for_channel<ValidWitness>(
                &app,
                &valid_witness,
                &channel_witness_config,
                &clock,
                &mut posts,
                data,
                description,
                title,
                ts::ctx(scenario)
            );

            destroy(owned_user);
            destroy(posts);
        };

        ts::next_tx(scenario, ADMIN);
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

            let invalid_witness = access::create_invalid_witness_for_testing();

            post_actions::like_for_user<SUI, InvalidWitness>(
                &clock,
                &mut post,
                &post_fees,
                &royalties,
                &invalid_witness,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            ts::return_shared(post);

            destroy_for_testing(
                app,
                channel_witness_config,
                clock,
                group_witness_config,
                owned_user_config,
                user_witness_config,
                post_fees,
                royalties,
                valid_type
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_post_actions_like_incorrect_custom_payment() {
        let (
            mut scenario_val,
            app,
            channel_witness_config,
            clock,
            group_witness_config,
            owned_user_config,
            user_witness_config,
            post_fees,
            royalties,
            valid_type,
            valid_witness
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        let owned_user = {
            let owned_user = access::create_valid_type_for_testing(
                ts::ctx(scenario)
            );

            let mut posts = posts::create(ts::ctx(scenario));

            let data = utf8(b"data");
            let description = utf8(b"description");
            let title = utf8(b"title");

            let (
                _post_address,
                _self,
                _timestamp
            ) = post_actions::create_for_channel<ValidWitness>(
                &app,
                &valid_witness,
                &channel_witness_config,
                &clock,
                &mut posts,
                data,
                description,
                title,
                ts::ctx(scenario)
            );

            destroy(posts);

            owned_user
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut post = ts::take_shared<Post>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                LIKE_POST_SUI_FEE,
                ts::ctx(scenario)
            );

            post_actions::like_for_user<SUI, ValidWitness>(
                &clock,
                &mut post,
                &post_fees,
                &royalties,
                &valid_witness,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            destroy(owned_user);

            ts::return_shared(post);

            destroy_for_testing(
                app,
                channel_witness_config,
                clock,
                group_witness_config,
                owned_user_config,
                user_witness_config,
                post_fees,
                royalties,
                valid_type
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_post_actions_like_incorrect_sui_payment() {
        let (
            mut scenario_val,
            app,
            channel_witness_config,
            clock,
            group_witness_config,
            owned_user_config,
            user_witness_config,
            post_fees,
            royalties,
            valid_type,
            valid_witness
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        let owned_user = {
            let owned_user = access::create_valid_type_for_testing(
                ts::ctx(scenario)
            );

            let mut posts = posts::create(ts::ctx(scenario));

            let data = utf8(b"data");
            let description = utf8(b"description");
            let title = utf8(b"title");

            let (
                _post_address,
                _self,
                _timestamp
            ) = post_actions::create_for_channel<ValidWitness>(
                &app,
                &valid_witness,
                &channel_witness_config,
                &clock,
                &mut posts,
                data,
                description,
                title,
                ts::ctx(scenario)
            );


            destroy(posts);

            owned_user
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut post = ts::take_shared<Post>(scenario);

            let custom_payment = mint_for_testing<SUI>(
                LIKE_POST_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            post_actions::like_for_user<SUI, ValidWitness>(
                &clock,
                &mut post,
                &post_fees,
                &royalties,
                &valid_witness,
                &user_witness_config,
                custom_payment,
                sui_payment,
                ts::ctx(scenario)
            );

            destroy(owned_user);

            ts::return_shared(post);

            destroy_for_testing(
                app,
                channel_witness_config,
                clock,
                group_witness_config,
                owned_user_config,
                user_witness_config,
                post_fees,
                royalties,
                valid_type
            );
        };

        ts::end(scenario_val);
    }
}
