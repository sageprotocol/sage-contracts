#[test_only]
module sage_trust::test_trust_access {
    use sui::{
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy}
    };

    use sage_admin::{
        admin::{Self, AdminCap}
    };

    use sage_trust::{
        trust_access::{
            Self,
            GovernanceWitnessConfig,
            RewardWitnessConfig,
            InvalidWitness,
            ValidWitness,
            EIsFinalized,
            EWitnessMismatch
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
        governance_witness_config: GovernanceWitnessConfig,
        reward_witness_config: RewardWitnessConfig
    ) {
        destroy(admin_cap);
        destroy(governance_witness_config);
        destroy(reward_witness_config);
    }

    #[test_only]
    fun setup_for_testing(): (
        Scenario,
        AdminCap,
        GovernanceWitnessConfig,
        RewardWitnessConfig
    ) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            trust_access::init_for_testing(ts::ctx(scenario));
            admin::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let (
            admin_cap,
            governance_witness_config,
            reward_witness_config
        ) = {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            let mut governance_witness_config = ts::take_shared<GovernanceWitnessConfig>(scenario);
            let mut reward_witness_config = ts::take_shared<RewardWitnessConfig>(scenario);

            trust_access::update_governance_witness<ValidWitness>(
                &admin_cap,
                &mut governance_witness_config
            );
            trust_access::update_reward_witness<ValidWitness>(
                &admin_cap,
                &mut reward_witness_config
            );

            (
                admin_cap,
                governance_witness_config,
                reward_witness_config
            )
        };

        (
            scenario_val,
            admin_cap,
            governance_witness_config,
            reward_witness_config
        )
    }

    #[test]
    fun test_init() {
        let (
            mut scenario_val,
            admin_cap,
            governance_witness_config,
            reward_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                admin_cap,
                governance_witness_config,
                reward_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_assert_governance_witness_pass() {
        let (
            mut scenario_val,
            admin_cap,
            governance_witness_config,
            reward_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let governance_witness = trust_access::create_valid_witness();

            trust_access::assert_governance_witness<ValidWitness>(
                &governance_witness,
                &governance_witness_config
            );

            destroy_for_testing(
                admin_cap,
                governance_witness_config,
                reward_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EWitnessMismatch)]
    fun test_assert_governance_witness_fail() {
        let (
            mut scenario_val,
            admin_cap,
            governance_witness_config,
            reward_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let governance_witness = trust_access::create_invalid_witness();

            trust_access::assert_governance_witness<InvalidWitness>(
                &governance_witness,
                &governance_witness_config
            );

            destroy_for_testing(
                admin_cap,
                governance_witness_config,
                reward_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIsFinalized)]
    fun test_governance_witness_update_fail() {
        let (
            mut scenario_val,
            admin_cap,
            mut governance_witness_config,
            reward_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            trust_access::update_governance_witness<InvalidWitness>(
                &admin_cap,
                &mut governance_witness_config
            );

            destroy_for_testing(
                admin_cap,
                governance_witness_config,
                reward_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_verify_governance_witness() {
        let (
            mut scenario_val,
            admin_cap,
            governance_witness_config,
            reward_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let invalid_witness = trust_access::create_invalid_witness();

            let is_verified = trust_access::verify_governance_witness<InvalidWitness>(
                &invalid_witness,
                &governance_witness_config
            );

            assert!(!is_verified, EWitnessVerificationMismatch);

            let valid_witness = trust_access::create_valid_witness();

            let is_verified = trust_access::verify_governance_witness<ValidWitness>(
                &valid_witness,
                &governance_witness_config
            );

            assert!(is_verified, EWitnessVerificationMismatch);

            destroy_for_testing(
                admin_cap,
                governance_witness_config,
                reward_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_assert_reward_witness_pass() {
        let (
            mut scenario_val,
            admin_cap,
            governance_witness_config,
            reward_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let reward_witness = trust_access::create_valid_witness();

            trust_access::assert_reward_witness<ValidWitness>(
                &reward_witness,
                &reward_witness_config
            );

            destroy_for_testing(
                admin_cap,
                governance_witness_config,
                reward_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EWitnessMismatch)]
    fun test_assert_reward_witness_fail() {
        let (
            mut scenario_val,
            admin_cap,
            governance_witness_config,
            reward_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let reward_witness = trust_access::create_invalid_witness();

            trust_access::assert_reward_witness<InvalidWitness>(
                &reward_witness,
                &reward_witness_config
            );

            destroy_for_testing(
                admin_cap,
                governance_witness_config,
                reward_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIsFinalized)]
    fun test_reward_witness_update_fail() {
        let (
            mut scenario_val,
            admin_cap,
            governance_witness_config,
            mut reward_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            trust_access::update_reward_witness<InvalidWitness>(
                &admin_cap,
                &mut reward_witness_config
            );

            destroy_for_testing(
                admin_cap,
                governance_witness_config,
                reward_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_verify_reward_witness() {
        let (
            mut scenario_val,
            admin_cap,
            governance_witness_config,
            reward_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let invalid_witness = trust_access::create_invalid_witness();

            let is_verified = trust_access::verify_reward_witness<InvalidWitness>(
                &invalid_witness,
                &reward_witness_config
            );

            assert!(!is_verified, EWitnessVerificationMismatch);

            let valid_witness = trust_access::create_valid_witness();

            let is_verified = trust_access::verify_reward_witness<ValidWitness>(
                &valid_witness,
                &reward_witness_config
            );

            assert!(is_verified, EWitnessVerificationMismatch);

            destroy_for_testing(
                admin_cap,
                governance_witness_config,
                reward_witness_config
            );
        };

        ts::end(scenario_val);
    }
}
