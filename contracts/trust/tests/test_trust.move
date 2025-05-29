#[test_only]
module sage_trust::test_trust {
    use std::string::{
        to_ascii,
        utf8
    };

    use sui::{
        coin::{CoinMetadata},
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy},
        url::{new_unsafe_from_bytes}
    };

    use sage_admin::{
        admin::{
            Self,
            AdminCap,
            MintCap
        }
    };

    use sage_trust::{
        trust_access::{
            Self,
            GovernanceWitnessConfig,
            RewardWitnessConfig,
            InvalidWitness,
            ValidWitness,
            EWitnessMismatch
        },
        trust::{
            Self,
            MintConfig,
            ProtectedTreasury,
            TRUST
        }
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    const DECIMALS: u8 = 6;
    const DESCRIPTION: vector<u8> = b"";
    const ICON_URL: vector<u8> = b"";
    const NAME: vector<u8> = b"";
    const SYMBOL: vector<u8> = b"";

    const SCALE_FACTOR: u64 = 1_000_000;

    // --------------- Errors ---------------

    const ETotalSupplyMismatch: u64 = 0;

    // --------------- Test Functions ---------------

    #[test_only]
    fun destroy_for_testing(
        admin_cap: AdminCap,
        governance_witness_config: GovernanceWitnessConfig,
        mint_config: MintConfig,
        protected_treasury: ProtectedTreasury,
        reward_witness_config: RewardWitnessConfig
    ) {
        destroy(admin_cap);
        destroy(governance_witness_config);
        destroy(mint_config);
        destroy(protected_treasury);
        destroy(reward_witness_config);
    }

    #[test_only]
    fun setup_for_testing(): (
        Scenario,
        AdminCap,
        GovernanceWitnessConfig,
        MintConfig,
        ProtectedTreasury,
        RewardWitnessConfig
    ) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            trust_access::init_for_testing(ts::ctx(scenario));
            admin::init_for_testing(ts::ctx(scenario));
            trust::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let (
            admin_cap,
            governance_witness_config,
            mint_config,
            protected_treasury,
            reward_witness_config
        ) = {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            let mut governance_witness_config = ts::take_shared<GovernanceWitnessConfig>(scenario);
            let mint_config = ts::take_shared<MintConfig>(scenario);
            let protected_treasury = ts::take_shared<ProtectedTreasury>(scenario);
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
                mint_config,
                protected_treasury,
                reward_witness_config
            )
        };

        (
            scenario_val,
            admin_cap,
            governance_witness_config,
            mint_config,
            protected_treasury,
            reward_witness_config
        )
    }

    #[test]
    fun test_init() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            trust::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        {
            let protected_treasury = ts::take_shared<ProtectedTreasury>(scenario);

            assert!(protected_treasury.total_supply() == 0);

            let metadata = ts::take_immutable<CoinMetadata<TRUST>>(scenario);

            assert!(metadata.get_decimals() == DECIMALS);
            assert!(metadata.get_description() == utf8(DESCRIPTION));
            assert!(metadata.get_icon_url() == option::some(new_unsafe_from_bytes((ICON_URL))));
            assert!(metadata.get_name() == utf8(NAME));
            assert!(metadata.get_symbol() == to_ascii(utf8(SYMBOL)));

            ts::return_immutable(metadata);
            ts::return_shared(protected_treasury);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_initial_mint_config() {
        let (
            mut scenario_val,
            admin_cap,
            governance_witness_config,
            mint_config,
            protected_treasury,
            reward_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let is_enabled = mint_config.is_minting_enabled();

            assert!(is_enabled);

            let max_supply_option = mint_config.max_supply();

            assert!(max_supply_option.is_none());

            destroy_for_testing(
                admin_cap,
                governance_witness_config,
                mint_config,
                protected_treasury,
                reward_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_update_config_admin() {
        let (
            mut scenario_val,
            admin_cap,
            governance_witness_config,
            mut mint_config,
            protected_treasury,
            reward_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mint_cap = scenario.take_from_sender<MintCap>();

            trust::update_mint_config_admin(
                &mint_cap,
                &mut mint_config,
                false,
                option::some(5)
            );

            let is_enabled = mint_config.is_minting_enabled();

            assert!(!is_enabled);

            let max_supply_option = mint_config.max_supply();

            assert!(max_supply_option.is_some());
            assert!(max_supply_option.destroy_some() == 5);

            destroy(mint_cap);

            destroy_for_testing(
                admin_cap,
                governance_witness_config,
                mint_config,
                protected_treasury,
                reward_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_update_config_governance() {
        let (
            mut scenario_val,
            admin_cap,
            governance_witness_config,
            mut mint_config,
            protected_treasury,
            reward_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let valid_witness = trust_access::create_valid_witness();

            trust::update_mint_config_for_governance<ValidWitness>(
                &valid_witness,
                &governance_witness_config,
                &mut mint_config,
                false,
                option::some(5)
            );

            let is_enabled = mint_config.is_minting_enabled();

            assert!(!is_enabled);

            let max_supply_option = mint_config.max_supply();

            assert!(max_supply_option.is_some());
            assert!(max_supply_option.destroy_some() == 5);

            destroy_for_testing(
                admin_cap,
                governance_witness_config,
                mint_config,
                protected_treasury,
                reward_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EWitnessMismatch)]
    fun test_update_config_governance_witness_mismatch() {
        let (
            mut scenario_val,
            admin_cap,
            governance_witness_config,
            mut mint_config,
            protected_treasury,
            reward_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let invalid_witness = trust_access::create_invalid_witness();

            trust::update_mint_config_for_governance<InvalidWitness>(
                &invalid_witness,
                &governance_witness_config,
                &mut mint_config,
                false,
                option::some(5)
            );

            destroy_for_testing(
                admin_cap,
                governance_witness_config,
                mint_config,
                protected_treasury,
                reward_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_mint_and_burn() {
        let (
            mut scenario_val,
            admin_cap,
            governance_witness_config,
            mint_config,
            mut protected_treasury,
            reward_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let reward_witness = trust_access::create_valid_witness();

            let coin = trust::mint<ValidWitness>(
                &mint_config,
                &reward_witness,
                &reward_witness_config,
                &mut protected_treasury,
                5 * SCALE_FACTOR,
                ts::ctx(scenario)
            );

            let balance = coin.balance();

            assert!(balance.value() == 5);

            trust::burn<ValidWitness>(
                &reward_witness,
                &mut protected_treasury,
                &reward_witness_config,
                coin
            );

            destroy_for_testing(
                admin_cap,
                governance_witness_config,
                mint_config,
                protected_treasury,
                reward_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_mint_not_allowed() {
        let (
            mut scenario_val,
            admin_cap,
            governance_witness_config,
            mut mint_config,
            mut protected_treasury,
            reward_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mint_cap = scenario.take_from_sender<MintCap>();

            trust::update_mint_config_admin(
                &mint_cap,
                &mut mint_config,
                false,
                option::none()
            );

            let reward_witness = trust_access::create_valid_witness();

            let coin = trust::mint<ValidWitness>(
                &mint_config,
                &reward_witness,
                &reward_witness_config,
                &mut protected_treasury,
                5,
                ts::ctx(scenario)
            );

            let balance = coin.balance();

            assert!(balance.value() == 0);

            trust::burn<ValidWitness>(
                &reward_witness,
                &mut protected_treasury,
                &reward_witness_config,
                coin
            );

            destroy(mint_cap);

            destroy_for_testing(
                admin_cap,
                governance_witness_config,
                mint_config,
                protected_treasury,
                reward_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_mint_max_supply() {
        let (
            mut scenario_val,
            admin_cap,
            governance_witness_config,
            mut mint_config,
            mut protected_treasury,
            reward_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let mint_cap = scenario.take_from_sender<MintCap>();

            trust::update_mint_config_admin(
                &mint_cap,
                &mut mint_config,
                true,
                option::some(5)
            );

            let reward_witness = trust_access::create_valid_witness();

            let coin = trust::mint<ValidWitness>(
                &mint_config,
                &reward_witness,
                &reward_witness_config,
                &mut protected_treasury,
                (49 / 10) * SCALE_FACTOR,
                ts::ctx(scenario)
            );

            let balance = coin.balance();

            assert!(balance.value() == ((49 / 10)));

            destroy(coin);

            let coin = trust::mint<ValidWitness>(
                &mint_config,
                &reward_witness,
                &reward_witness_config,
                &mut protected_treasury,
                5 * SCALE_FACTOR,
                ts::ctx(scenario)
            );

            let balance = coin.balance();

            assert!(balance.value() == 0);

            destroy(coin);

            let coin = trust::mint<ValidWitness>(
                &mint_config,
                &reward_witness,
                &reward_witness_config,
                &mut protected_treasury,
                (2 / 10) * SCALE_FACTOR,
                ts::ctx(scenario)
            );

            let balance = coin.balance();

            assert!(balance.value() == 0);

            destroy(coin);

            let coin = trust::mint<ValidWitness>(
                &mint_config,
                &reward_witness,
                &reward_witness_config,
                &mut protected_treasury,
                (1 / 10) * SCALE_FACTOR,
                ts::ctx(scenario)
            );

            let balance = coin.balance();

            assert!(balance.value() == (1 / 10));

            destroy(coin);
            destroy(mint_cap);

            destroy_for_testing(
                admin_cap,
                governance_witness_config,
                mint_config,
                protected_treasury,
                reward_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EWitnessMismatch)]
    fun test_mint_witness_mismatch() {
        let (
            mut scenario_val,
            admin_cap,
            governance_witness_config,
            mint_config,
            mut protected_treasury,
            reward_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let reward_witness = trust_access::create_invalid_witness();

            let coin = trust::mint<InvalidWitness>(
                &mint_config,
                &reward_witness,
                &reward_witness_config,
                &mut protected_treasury,
                5,
                ts::ctx(scenario)
            );

            destroy(coin);

            destroy_for_testing(
                admin_cap,
                governance_witness_config,
                mint_config,
                protected_treasury,
                reward_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EWitnessMismatch)]
    fun test_burn_witness_mismatch() {
        let (
            mut scenario_val,
            admin_cap,
            governance_witness_config,
            mint_config,
            mut protected_treasury,
            reward_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let reward_witness = trust_access::create_valid_witness();

            let coin = trust::mint<ValidWitness>(
                &mint_config,
                &reward_witness,
                &reward_witness_config,
                &mut protected_treasury,
                5,
                ts::ctx(scenario)
            );

            let reward_witness = trust_access::create_invalid_witness();

            trust::burn<InvalidWitness>(
                &reward_witness,
                &mut protected_treasury,
                &reward_witness_config,
                coin
            );

            destroy_for_testing(
                admin_cap,
                governance_witness_config,
                mint_config,
                protected_treasury,
                reward_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_total_supply() {
        let (
            mut scenario_val,
            admin_cap,
            governance_witness_config,
            mint_config,
            mut protected_treasury,
            reward_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let amount = 5;
            let reward_witness = trust_access::create_valid_witness();

            let coin = trust::mint<ValidWitness>(
                &mint_config,
                &reward_witness,
                &reward_witness_config,
                &mut protected_treasury,
                amount * SCALE_FACTOR,
                ts::ctx(scenario)
            );

            let supply = trust::total_supply(
                &protected_treasury
            );

            assert!(supply == amount, ETotalSupplyMismatch);

            destroy(coin);

            destroy_for_testing(
                admin_cap,
                governance_witness_config,
                mint_config,
                protected_treasury,
                reward_witness_config
            );
        };

        ts::end(scenario_val);
    }
}
