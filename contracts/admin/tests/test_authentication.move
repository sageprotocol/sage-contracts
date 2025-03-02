#[test_only]
module sage_admin::test_authentication {
    use sui::{
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy}
    };

    use sage_admin::{
        admin::{
            Self,
            AdminCap,
        },
        authentication::{
            Self,
            AuthenticationConfig,
            InvalidAuthSoul,
            ValidAuthSoul,
            ENotAuthenticated
        }
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    const EAuthMismatch: u64 = 0;

    // --------------- Test Functions ---------------

    #[test_only]
    fun setup_for_testing(): (
        Scenario,
        AuthenticationConfig
    ) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
            authentication::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let authentication_config = {
            scenario.take_shared<AuthenticationConfig>()
        };

        (
            scenario_val,
            authentication_config
        )
    }

    #[test]
    fun test_init() {
        let (
            mut scenario_val,
            authentication_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy(authentication_config);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_verify_authentication_no_setting() {
        let (
            mut scenario_val,
            authentication_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        let valid_auth_soul = {
            let valid_auth_soul = authentication::create_valid_auth_soul(
                ts::ctx(scenario)
            );

            let is_authenticated = authentication::verify_authentication<ValidAuthSoul>(
                &authentication_config,
                &valid_auth_soul
            );

            assert!(!is_authenticated, EAuthMismatch);

            valid_auth_soul
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy(authentication_config);
            destroy(valid_auth_soul);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_verify_authentication_with_setting() {
        let (
            mut scenario_val,
            mut authentication_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        let (
            invalid_auth_soul,
            valid_auth_soul
        ) = {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            authentication::update_soul<ValidAuthSoul>(
                &admin_cap,
                &mut authentication_config
            );

            let invalid_auth_soul = authentication::create_invalid_auth_soul(
                ts::ctx(scenario)
            );

            let is_authenticated = authentication::verify_authentication<InvalidAuthSoul>(
                &authentication_config,
                &invalid_auth_soul
            );

            assert!(!is_authenticated, EAuthMismatch);

            let valid_auth_soul = authentication::create_valid_auth_soul(
                ts::ctx(scenario)
            );

            let is_authenticated = authentication::verify_authentication<ValidAuthSoul>(
                &authentication_config,
                &valid_auth_soul
            );

            assert!(is_authenticated, EAuthMismatch);

            ts::return_to_sender(scenario, admin_cap);

            (
                invalid_auth_soul,
                valid_auth_soul
            )
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy(authentication_config);
            destroy(invalid_auth_soul);
            destroy(valid_auth_soul);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ENotAuthenticated)]
    fun test_assert_authentication() {
        let (
            mut scenario_val,
            mut authentication_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        let invalid_auth_soul = {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            authentication::update_soul<ValidAuthSoul>(
                &admin_cap,
                &mut authentication_config
            );

            let invalid_auth_soul = authentication::create_invalid_auth_soul(
                ts::ctx(scenario)
            );

            authentication::assert_authentication<InvalidAuthSoul>(
                &authentication_config,
                &invalid_auth_soul
            );

            ts::return_to_sender(scenario, admin_cap);

            invalid_auth_soul
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy(authentication_config);
            destroy(invalid_auth_soul);
        };

        ts::end(scenario_val);
    }
}
