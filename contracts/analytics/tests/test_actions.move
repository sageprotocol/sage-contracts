#[test_only]
module sage_analytics::test_analytics_actions {
    use std::{
        string::{utf8}
    };

    use sui::{
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy}
    };

    use sage_admin::{
        admin_access::{
            Self,
            ChannelWitnessConfig,
            GroupWitnessConfig,
            UserWitnessConfig,
            InvalidWitness,
            ValidWitness,
            EWitnessMismatch
        },
        admin::{Self, AdminCap},
        apps::{Self, App}
    };

    use sage_analytics::{
        analytics::{Self},
        analytics_actions::{Self}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    fun destroy_for_testing(
        app: App,
        channel_witness_config: ChannelWitnessConfig,
        group_witness_config: GroupWitnessConfig,
        user_witness_config: UserWitnessConfig
    ) {
        destroy(app);
        destroy(channel_witness_config);
        destroy(group_witness_config);
        destroy(user_witness_config);
    }

    #[test_only]
    fun setup_for_testing(): (
        Scenario,
        App,
        ChannelWitnessConfig,
        GroupWitnessConfig,
        UserWitnessConfig
    ) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
            apps::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            admin_access::create_channel_witness_config<ValidWitness>(
                &admin_cap,
                ts::ctx(scenario)
            );
            admin_access::create_group_witness_config<ValidWitness>(
                &admin_cap,
                ts::ctx(scenario)
            );
            admin_access::create_user_witness_config<ValidWitness>(
                &admin_cap,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, admin_cap);
        };

        ts::next_tx(scenario, ADMIN);
        let (
            app,
            channel_witness_config,
            group_witness_config,
            user_witness_config
        ) = {
            let app = apps::create_for_testing(
                utf8(b"sage"),
                ts::ctx(scenario)
            );

            let channel_witness_config = ts::take_shared<ChannelWitnessConfig>(scenario);
            let group_witness_config = ts::take_shared<GroupWitnessConfig>(scenario);
            let user_witness_config = ts::take_shared<UserWitnessConfig>(scenario);

            (
                app,
                channel_witness_config,
                group_witness_config,
                user_witness_config
            )
        };

        (
            scenario_val,
            app,
            channel_witness_config,
            group_witness_config,
            user_witness_config
        )
    }

    #[test]
    fun test_create() {
        let (
            mut scenario_val,
            app,
            channel_witness_config,
            group_witness_config,
            user_witness_config
        ) = setup_for_testing();
        
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let valid_witness = admin_access::create_valid_witness_for_testing();

            let analytics = analytics_actions::create_analytics_for_channel<ValidWitness>(
                &valid_witness,
                &channel_witness_config,
                ts::ctx(scenario)
            );

            destroy(analytics);

            let analytics = analytics_actions::create_analytics_for_group<ValidWitness>(
                &valid_witness,
                &group_witness_config,
                ts::ctx(scenario)
            );

            destroy(analytics);

            let analytics = analytics_actions::create_analytics_for_user<ValidWitness>(
                &valid_witness,
                &user_witness_config,
                ts::ctx(scenario)
            );

            destroy(analytics);

            destroy_for_testing(
                app,
                channel_witness_config,
                group_witness_config,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EWitnessMismatch)]
    fun test_create_channel_fail() {
        let (
            mut scenario_val,
            app,
            channel_witness_config,
            group_witness_config,
            user_witness_config
        ) = setup_for_testing();
        
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let invalid_witness = admin_access::create_invalid_witness_for_testing();

            let analytics = analytics_actions::create_analytics_for_channel<InvalidWitness>(
                &invalid_witness,
                &channel_witness_config,
                ts::ctx(scenario)
            );

            destroy(analytics);

            destroy_for_testing(
                app,
                channel_witness_config,
                group_witness_config,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EWitnessMismatch)]
    fun test_create_group_fail() {
        let (
            mut scenario_val,
            app,
            channel_witness_config,
            group_witness_config,
            user_witness_config
        ) = setup_for_testing();
        
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let invalid_witness = admin_access::create_invalid_witness_for_testing();

            let analytics = analytics_actions::create_analytics_for_group<InvalidWitness>(
                &invalid_witness,
                &group_witness_config,
                ts::ctx(scenario)
            );

            destroy(analytics);

            destroy_for_testing(
                app,
                channel_witness_config,
                group_witness_config,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EWitnessMismatch)]
    fun test_create_user_fail() {
        let (
            mut scenario_val,
            app,
            channel_witness_config,
            group_witness_config,
            user_witness_config
        ) = setup_for_testing();
        
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let invalid_witness = admin_access::create_invalid_witness_for_testing();

            let analytics = analytics_actions::create_analytics_for_user<InvalidWitness>(
                &invalid_witness,
                &user_witness_config,
                ts::ctx(scenario)
            );

            destroy(analytics);

            destroy_for_testing(
                app,
                channel_witness_config,
                group_witness_config,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_increment_analytics() {
        let (
            mut scenario_val,
            app,
            channel_witness_config,
            group_witness_config,
            user_witness_config
        ) = setup_for_testing();
        
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mut analytics = analytics::create(ts::ctx(scenario));

            let key = utf8(b"analytics");

            let value = analytics::get_field(
                &analytics,
                key
            );

            assert!(value == 0);

            analytics_actions::increment_analytics_for_testing(
                &mut analytics,
                object::id_address(&app),
                5,
                key
            );

            let value = analytics::get_field(
                &analytics,
                key
            );

            assert!(value == 1);

            analytics_actions::increment_analytics_for_testing(
                &mut analytics,
                object::id_address(&app),
                5,
                key
            );

            let value = analytics::get_field(
                &analytics,
                key
            );

            assert!(value == 2);

            analytics_actions::increment_analytics_for_testing(
                &mut analytics,
                object::id_address(&app),
                5,
                key
            );

            let value = analytics::get_field(
                &analytics,
                key
            );

            assert!(value == 3);

            destroy(analytics);

            destroy_for_testing(
                app,
                channel_witness_config,
                group_witness_config,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_increment_channel_analytics() {
        let (
            mut scenario_val,
            app,
            channel_witness_config,
            group_witness_config,
            user_witness_config
        ) = setup_for_testing();
        
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let valid_witness = admin_access::create_valid_witness_for_testing();

            let mut analytics = analytics_actions::create_analytics_for_channel<ValidWitness>(
                &valid_witness,
                &channel_witness_config,
                ts::ctx(scenario)
            );

            let key = utf8(b"analytics");

            analytics_actions::increment_analytics_for_channel<ValidWitness>(
                &mut analytics,
                &app,
                &valid_witness,
                &channel_witness_config,
                10,
                key
            );

            let value = analytics::get_field(
                &analytics,
                key
            );

            assert!(value == 1);

            destroy(analytics);

            destroy_for_testing(
                app,
                channel_witness_config,
                group_witness_config,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EWitnessMismatch)]
    fun test_increment_channel_analytics_fail() {
        let (
            mut scenario_val,
            app,
            channel_witness_config,
            group_witness_config,
            user_witness_config
        ) = setup_for_testing();
        
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let valid_witness = admin_access::create_valid_witness_for_testing();

            let mut analytics = analytics_actions::create_analytics_for_channel<ValidWitness>(
                &valid_witness,
                &channel_witness_config,
                ts::ctx(scenario)
            );

            let invalid_witness = admin_access::create_invalid_witness_for_testing();

            let key = utf8(b"analytics");

            analytics_actions::increment_analytics_for_channel<InvalidWitness>(
                &mut analytics,
                &app,
                &invalid_witness,
                &channel_witness_config,
                10,
                key
            );

            destroy(analytics);

            destroy_for_testing(
                app,
                channel_witness_config,
                group_witness_config,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_increment_group_analytics() {
        let (
            mut scenario_val,
            app,
            channel_witness_config,
            group_witness_config,
            user_witness_config
        ) = setup_for_testing();
        
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let valid_witness = admin_access::create_valid_witness_for_testing();

            let mut analytics = analytics_actions::create_analytics_for_group<ValidWitness>(
                &valid_witness,
                &group_witness_config,
                ts::ctx(scenario)
            );

            let key = utf8(b"analytics");

            analytics_actions::increment_analytics_for_group<ValidWitness>(
                &mut analytics,
                &app,
                &valid_witness,
                &group_witness_config,
                10,
                key
            );

            let value = analytics::get_field(
                &analytics,
                key
            );

            assert!(value == 1);

            destroy(analytics);

            destroy_for_testing(
                app,
                channel_witness_config,
                group_witness_config,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EWitnessMismatch)]
    fun test_increment_group_analytics_fail() {
        let (
            mut scenario_val,
            app,
            channel_witness_config,
            group_witness_config,
            user_witness_config
        ) = setup_for_testing();
        
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let valid_witness = admin_access::create_valid_witness_for_testing();

            let mut analytics = analytics_actions::create_analytics_for_group<ValidWitness>(
                &valid_witness,
                &group_witness_config,
                ts::ctx(scenario)
            );

            let invalid_witness = admin_access::create_invalid_witness_for_testing();

            let key = utf8(b"analytics");

            analytics_actions::increment_analytics_for_group<InvalidWitness>(
                &mut analytics,
                &app,
                &invalid_witness,
                &group_witness_config,
                10,
                key
            );

            destroy(analytics);

            destroy_for_testing(
                app,
                channel_witness_config,
                group_witness_config,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_increment_user_analytics() {
        let (
            mut scenario_val,
            app,
            channel_witness_config,
            group_witness_config,
            user_witness_config
        ) = setup_for_testing();
        
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let valid_witness = admin_access::create_valid_witness_for_testing();

            let mut analytics = analytics_actions::create_analytics_for_user<ValidWitness>(
                &valid_witness,
                &user_witness_config,
                ts::ctx(scenario)
            );

            let key = utf8(b"analytics");

            analytics_actions::increment_analytics_for_user<ValidWitness>(
                &mut analytics,
                &app,
                &valid_witness,
                &user_witness_config,
                10,
                key
            );

            let value = analytics::get_field(
                &analytics,
                key
            );

            assert!(value == 1);

            destroy(analytics);

            destroy_for_testing(
                app,
                channel_witness_config,
                group_witness_config,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EWitnessMismatch)]
    fun test_increment_user_analytics_fail() {
        let (
            mut scenario_val,
            app,
            channel_witness_config,
            group_witness_config,
            user_witness_config
        ) = setup_for_testing();
        
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let valid_witness = admin_access::create_valid_witness_for_testing();

            let mut analytics = analytics_actions::create_analytics_for_user<ValidWitness>(
                &valid_witness,
                &user_witness_config,
                ts::ctx(scenario)
            );

            let invalid_witness = admin_access::create_invalid_witness_for_testing();

            let key = utf8(b"analytics");

            analytics_actions::increment_analytics_for_user<InvalidWitness>(
                &mut analytics,
                &app,
                &invalid_witness,
                &user_witness_config,
                10,
                key
            );

            destroy(analytics);

            destroy_for_testing(
                app,
                channel_witness_config,
                group_witness_config,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }
}
