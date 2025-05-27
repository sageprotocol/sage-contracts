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
        admin::{Self, AdminCap}
    };

    use sage_trust::{
        access::{
            Self,
            RewardWitnessConfig,
            InvalidWitness,
            ValidWitness,
            ETypeMismatch
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

    const DECIMALS: u8 = 9;
    const DESCRIPTION: vector<u8> = b"";
    const ICON_URL: vector<u8> = b"";
    const NAME: vector<u8> = b"";
    const SYMBOL: vector<u8> = b"";

    // --------------- Errors ---------------

    const ETotalSupplyMismatch: u64 = 0;

    // --------------- Test Functions ---------------

    #[test_only]
    fun destroy_for_testing(
        admin_cap: AdminCap,
        mint_config: MintConfig,
        protected_treasury: ProtectedTreasury,
        reward_witness_config: RewardWitnessConfig
    ) {
        destroy(admin_cap);
        destroy(mint_config);
        destroy(protected_treasury);
        destroy(reward_witness_config);
    }

    #[test_only]
    fun setup_for_testing(): (
        Scenario,
        AdminCap,
        MintConfig,
        ProtectedTreasury,
        RewardWitnessConfig
    ) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            access::init_for_testing(ts::ctx(scenario));
            admin::init_for_testing(ts::ctx(scenario));
            trust::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let (
            admin_cap,
            mint_config,
            protected_treasury,
            reward_witness_config
        ) = {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            let mint_config = ts::take_shared<MintConfig>(scenario);
            let protected_treasury = ts::take_shared<ProtectedTreasury>(scenario);
            let mut reward_witness_config = ts::take_shared<RewardWitnessConfig>(scenario);

            access::update<ValidWitness>(
                &admin_cap,
                &mut reward_witness_config
            );

            (
                admin_cap,
                mint_config,
                protected_treasury,
                reward_witness_config
            )
        };

        (
            scenario_val,
            admin_cap,
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
    fun test_mint_and_burn() {
        let (
            mut scenario_val,
            admin_cap,
            mint_config,
            mut protected_treasury,
            reward_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let reward_witness = access::create_valid_witness();

            let coin = trust::mint<ValidWitness>(
                &mint_config,
                &reward_witness,
                &reward_witness_config,
                &mut protected_treasury,
                5,
                ts::ctx(scenario)
            );

            trust::burn<ValidWitness>(
                &reward_witness,
                &mut protected_treasury,
                &reward_witness_config,
                coin
            );

            destroy_for_testing(
                admin_cap,
                mint_config,
                protected_treasury,
                reward_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ETypeMismatch)]
    fun test_mint_fail() {
        let (
            mut scenario_val,
            admin_cap,
            mint_config,
            mut protected_treasury,
            reward_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let reward_witness = access::create_invalid_witness();

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
                mint_config,
                protected_treasury,
                reward_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ETypeMismatch)]
    fun test_burn_fail() {
        let (
            mut scenario_val,
            admin_cap,
            mint_config,
            mut protected_treasury,
            reward_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let reward_witness = access::create_valid_witness();

            let coin = trust::mint<ValidWitness>(
                &mint_config,
                &reward_witness,
                &reward_witness_config,
                &mut protected_treasury,
                5,
                ts::ctx(scenario)
            );

            let reward_witness = access::create_invalid_witness();

            trust::burn<InvalidWitness>(
                &reward_witness,
                &mut protected_treasury,
                &reward_witness_config,
                coin
            );

            destroy_for_testing(
                admin_cap,
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
            mint_config,
            mut protected_treasury,
            reward_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let amount = 5;
            let reward_witness = access::create_valid_witness();

            let coin = trust::mint<ValidWitness>(
                &mint_config,
                &reward_witness,
                &reward_witness_config,
                &mut protected_treasury,
                amount,
                ts::ctx(scenario)
            );

            let supply = trust::total_supply(
                &protected_treasury
            );

            assert!(supply == amount, ETotalSupplyMismatch);

            destroy(coin);

            destroy_for_testing(
                admin_cap,
                mint_config,
                protected_treasury,
                reward_witness_config
            );
        };

        ts::end(scenario_val);
    }
}
