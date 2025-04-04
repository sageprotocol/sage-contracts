#[test_only]
module sage_admin::test_types {
    use sui::{
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy}
    };

    use sage_admin::{
        admin::{
            Self,
            AdminCap,
        },
        types::{
            Self,
            ChannelConfig,
            UserOwnedConfig,
            InvalidType,
            ValidType,
            ETypeMismatch
        }
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    const ETestTypeMismatch: u64 = 0;

    // --------------- Test Functions ---------------

    #[test_only]
    fun destroy_for_testing(
        admin_cap: AdminCap,
        channel_config: ChannelConfig,
        owned_user_config: UserOwnedConfig
    ) {
        destroy(admin_cap);
        destroy(channel_config);
        destroy(owned_user_config);
    }

    #[test_only]
    fun setup_for_testing(): (
        Scenario,
        AdminCap,
        ChannelConfig,
        UserOwnedConfig
    ) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            admin::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let admin_cap = {
            let admin_cap = scenario.take_from_sender<AdminCap>();

            types::create_channel_config<ValidType>(
                &admin_cap,
                ts::ctx(scenario)
            );

            types::create_owned_user_config<ValidType>(
                &admin_cap,
                ts::ctx(scenario)
            );

            admin_cap
        };

        ts::next_tx(scenario, ADMIN);
        let (
            channel_config,
            owned_user_config
        ) = {
            let channel_config = scenario.take_shared<ChannelConfig>();
            let owned_user_config = scenario.take_shared<UserOwnedConfig>();

            (
                channel_config,
                owned_user_config
            )
        };

        (
            scenario_val,
            admin_cap,
            channel_config,
            owned_user_config
        )
    }

    #[test]
    fun test_init() {
        let (
            mut scenario_val,
            admin_cap,
            channel_config,
            owned_user_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                admin_cap,
                channel_config,
                owned_user_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_verify_type() {
        let (
            mut scenario_val,
            admin_cap,
            mut channel_config,
            mut owned_user_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        let invalid_type = {
            let invalid_type = types::create_invalid_type_for_testing(
                ts::ctx(scenario)
            );

            let is_verified = types::verify_channel<InvalidType>(
                &channel_config,
                &invalid_type
            );

            assert!(!is_verified, ETestTypeMismatch);

            let is_verified = types::verify_channel<InvalidType>(
                &channel_config,
                &invalid_type
            );

            assert!(!is_verified, ETestTypeMismatch);

            let valid_type = types::create_valid_type_for_testing(
                ts::ctx(scenario)
            );

            let is_verified = types::verify_channel<ValidType>(
                &channel_config,
                &valid_type
            );

            assert!(is_verified, ETestTypeMismatch);

            let is_verified = types::verify_channel<ValidType>(
                &channel_config,
                &valid_type
            );

            assert!(is_verified, ETestTypeMismatch);

            types::update_channel_type<InvalidType>(
                &admin_cap,
                &mut channel_config
            );

            types::update_owned_user_type<InvalidType>(
                &admin_cap,
                &mut owned_user_config
            );

            destroy(valid_type);

            invalid_type
        };

        ts::next_tx(scenario, ADMIN);
        {
            let is_verified = types::verify_channel<InvalidType>(
                &channel_config,
                &invalid_type
            );

            assert!(is_verified, ETestTypeMismatch);

            let is_verified = types::verify_channel<InvalidType>(
                &channel_config,
                &invalid_type
            );

            assert!(is_verified, ETestTypeMismatch);

            destroy(invalid_type);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                admin_cap,
                channel_config,
                owned_user_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ETypeMismatch)]
    fun test_assert_channel_type() {
        let (
            mut scenario_val,
            admin_cap,
            channel_config,
            owned_user_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let invalid_type = types::create_invalid_type_for_testing(
                ts::ctx(scenario)
            );

            types::assert_channel<InvalidType>(
                &channel_config,
                &invalid_type
            );

            destroy(invalid_type);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                admin_cap,
                channel_config,
                owned_user_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ETypeMismatch)]
    fun test_assert_owned_user_type() {
        let (
            mut scenario_val,
            admin_cap,
            channel_config,
            owned_user_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let invalid_type = types::create_invalid_type_for_testing(
                ts::ctx(scenario)
            );

            types::assert_owned_user<InvalidType>(
                &owned_user_config,
                &invalid_type
            );

            destroy(invalid_type);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                admin_cap,
                channel_config,
                owned_user_config
            );
        };

        ts::end(scenario_val);
    }
}
