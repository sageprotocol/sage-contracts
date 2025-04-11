#[test_only]
module sage_trust::test_access {
    use sui::{
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy}
    };

    use sage_admin::{
        admin::{Self, AdminCap}
    };

    use sage_trust::{
        access::{
            Self,
            TrustConfig,
            InvalidWitness,
            ValidWitness,
            EIsFinalized,
            ETypeMismatch
        }
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    const EWitnessVerificationMismatch: u64 = 0;

    // --------------- Test Functions ---------------

    #[test_only]
    fun destroy_for_testing(
        admin_cap: AdminCap,
        trust_config: TrustConfig
    ) {
        destroy(admin_cap);
        destroy(trust_config);
    }

    #[test_only]
    fun setup_for_testing(): (
        Scenario,
        AdminCap,
        TrustConfig
    ) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            access::init_for_testing(ts::ctx(scenario));
            admin::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let (
            admin_cap,
            trust_config
        ) = {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            let mut trust_config = ts::take_shared<TrustConfig>(scenario);

            access::update<ValidWitness>(
                &admin_cap,
                &mut trust_config
            );

            (
                admin_cap,
                trust_config
            )
        };

        (
            scenario_val,
            admin_cap,
            trust_config
        )
    }

    #[test]
    fun test_init() {
        let (
            mut scenario_val,
            admin_cap,
            trust_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                admin_cap,
                trust_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_assert_witness_pass() {
        let (
            mut scenario_val,
            admin_cap,
            trust_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let reward_witness = access::create_valid_witness();

            access::assert_reward_witness<ValidWitness>(
                reward_witness,
                &trust_config
            );

            destroy_for_testing(
                admin_cap,
                trust_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ETypeMismatch)]
    fun test_assert_witness_fail() {
        let (
            mut scenario_val,
            admin_cap,
            trust_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let reward_witness = access::create_invalid_witness();

            access::assert_reward_witness<InvalidWitness>(
                reward_witness,
                &trust_config
            );

            destroy_for_testing(
                admin_cap,
                trust_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIsFinalized)]
    fun test_update_fail() {
        let (
            mut scenario_val,
            admin_cap,
            mut trust_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            access::update<InvalidWitness>(
                &admin_cap,
                &mut trust_config
            );

            destroy_for_testing(
                admin_cap,
                trust_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_verify_witness() {
        let (
            mut scenario_val,
            admin_cap,
            trust_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let invalid_witness = access::create_invalid_witness();

            let is_verified = access::verify_reward_witness<InvalidWitness>(
                invalid_witness,
                &trust_config
            );

            assert!(!is_verified, EWitnessVerificationMismatch);

            let valid_witness = access::create_valid_witness();

            let is_verified = access::verify_reward_witness<ValidWitness>(
                valid_witness,
                &trust_config
            );

            assert!(is_verified, EWitnessVerificationMismatch);

            destroy_for_testing(
                admin_cap,
                trust_config
            );
        };

        ts::end(scenario_val);
    }
}
