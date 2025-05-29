#[test_only]
module sage_reward::test_reward_actions {
    use std::{
        string::{utf8}
    };

    use sui::{
        clock::{Self, Clock},
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy}
    };

    use sage_admin::{
        admin::{Self, AdminCap, RewardCap},
        admin_access::{
            Self,
            UserWitnessConfig,
            InvalidWitness,
            ValidWitness,
            EWitnessMismatch
        },
        apps::{Self, App}
    };

    use sage_analytics::{
        analytics::{Self},
        analytics_actions::{Self}
    };

    use sage_reward::{
        reward_actions::{Self, ERewardsAlreadyStarted},
        reward_registry::{Self, RewardWeightsRegistry},
        reward_witness::{RewardWitness}
    };

    use sage_trust::{
        trust_access::{
            Self,
            RewardWitnessConfig
        },
        trust::{
            Self,
            MintConfig,
            ProtectedTreasury
        }
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    const SCALE_FACTOR: u64 = 1_000_000;

    // --------------- Errors ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    fun destroy_for_testing(
        app: App,
        clock: Clock,
        mint_config: MintConfig,
        protected_treasury: ProtectedTreasury,
        reward_cap: RewardCap,
        reward_weights_registry: RewardWeightsRegistry,
        reward_witness_config: RewardWitnessConfig,
        user_witness_config: UserWitnessConfig
    ) {
        destroy(app);
        destroy(clock);
        destroy(mint_config);
        destroy(protected_treasury);
        destroy(reward_cap);
        destroy(reward_weights_registry);
        destroy(reward_witness_config);
        destroy(user_witness_config);
    }

    #[test_only]
    fun setup_for_testing(): (
        Scenario,
        App,
        Clock,
        MintConfig,
        ProtectedTreasury,
        RewardCap,
        RewardWeightsRegistry,
        RewardWitnessConfig,
        UserWitnessConfig
    ) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
            apps::init_for_testing(ts::ctx(scenario));
            reward_registry::init_for_testing(ts::ctx(scenario));
            trust::init_for_testing(ts::ctx(scenario));
            trust_access::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);
        };

        ts::next_tx(scenario, ADMIN);
        let (clock, reward_cap) = {
            let clock = ts::take_shared<Clock>(scenario);
            let reward_cap = ts::take_from_sender<RewardCap>(scenario);

            (clock, reward_cap)
        };

        ts::next_tx(scenario, ADMIN);
        let reward_witness_config = {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            let mut reward_witness_config = ts::take_shared<RewardWitnessConfig>(scenario);

            admin_access::create_user_witness_config<ValidWitness>(
                &admin_cap,
                ts::ctx(scenario)
            );

            trust_access::update_reward_witness<RewardWitness>(
                &admin_cap,
                &mut reward_witness_config
            );

            ts::return_to_sender(scenario, admin_cap);

            reward_witness_config
        };

        ts::next_tx(scenario, ADMIN);
        let (
            app,
            mint_config,
            protected_treasury,
            reward_weights_registry,
            user_witness_config
        ) = {
            let app = apps::create_for_testing(
                utf8(b"sage"),
                ts::ctx(scenario)
            );

            let mint_config = scenario.take_shared<MintConfig>();
            let protected_treasury = scenario.take_shared<ProtectedTreasury>();
            let reward_weights_registry = scenario.take_shared<RewardWeightsRegistry>();
            let user_witness_config = scenario.take_shared<UserWitnessConfig>();

            (
                app,
                mint_config,
                protected_treasury,
                reward_weights_registry,
                user_witness_config
            )
        };

        (
            scenario_val,
            app,
            clock,
            mint_config,
            protected_treasury,
            reward_cap,
            reward_weights_registry,
            reward_witness_config,
            user_witness_config
        )
    }

    #[test]
    fun test_start() {
        let (
            mut scenario_val,
            app,
            clock,
            mint_config,
            protected_treasury,
            reward_cap,
            mut reward_weights_registry,
            reward_witness_config,
            user_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            reward_actions::start_epochs(
                &reward_cap,
                &clock,
                &mut reward_weights_registry,
                ts::ctx(scenario)
            );

            let length = reward_weights_registry.get_length();

            assert!(length == 1);

            let _reward_weights = reward_weights_registry.borrow_current();

            destroy_for_testing(
                app,
                clock,
                mint_config,
                protected_treasury,
                reward_cap,
                reward_weights_registry,
                reward_witness_config,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ERewardsAlreadyStarted)]
    fun test_start_fail() {
        let (
            mut scenario_val,
            app,
            clock,
            mint_config,
            protected_treasury,
            reward_cap,
            mut reward_weights_registry,
            reward_witness_config,
            user_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            reward_actions::start_epochs(
                &reward_cap,
                &clock,
                &mut reward_weights_registry,
                ts::ctx(scenario)
            );

            reward_actions::start_epochs(
                &reward_cap,
                &clock,
                &mut reward_weights_registry,
                ts::ctx(scenario)
            );      

            destroy_for_testing(
                app,
                clock,
                mint_config,
                protected_treasury,
                reward_cap,
                reward_weights_registry,
                reward_witness_config,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_complete() {
        let (
            mut scenario_val,
            app,
            mut clock,
            mint_config,
            protected_treasury,
            reward_cap,
            mut reward_weights_registry,
            reward_witness_config,
            user_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            reward_actions::start_epochs(
                &reward_cap,
                &clock,
                &mut reward_weights_registry,
                ts::ctx(scenario)
            );

            clock::increment_for_testing(
                &mut clock,
                1
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            reward_actions::complete_epoch(
                &reward_cap,
                &clock,
                &mut reward_weights_registry,
                ts::ctx(scenario)
            );

            let length = reward_weights_registry.get_length();

            assert!(length == 2);

            let _reward_weights = reward_weights_registry.borrow_current();

            destroy_for_testing(
                app,
                clock,
                mint_config,
                protected_treasury,
                reward_cap,
                reward_weights_registry,
                reward_witness_config,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_add_weight() {
        let (
            mut scenario_val,
            app,
            clock,
            mint_config,
            protected_treasury,
            reward_cap,
            mut reward_weights_registry,
            reward_witness_config,
            user_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            reward_actions::start_epochs(
                &reward_cap,
                &clock,
                &mut reward_weights_registry,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let metric = utf8(b"test");
            let value = 8;

            reward_actions::add_weight(
                &reward_cap,
                &mut reward_weights_registry,
                metric,
                value
            );

            let reward_weights = reward_weights_registry.borrow_current();

            let weight = reward_weights.get_weight(metric);

            assert!(weight == value);

            destroy_for_testing(
                app,
                clock,
                mint_config,
                protected_treasury,
                reward_cap,
                reward_weights_registry,
                reward_witness_config,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_claim_zero() {
        let (
            mut scenario_val,
            app,
            clock,
            mint_config,
            mut protected_treasury,
            reward_cap,
            mut reward_weights_registry,
            reward_witness_config,
            user_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            reward_actions::start_epochs(
                &reward_cap,
                &clock,
                &mut reward_weights_registry,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        let mut analytics = {
            let mut analytics = analytics::create_for_testing(ts::ctx(scenario));

            let (
                amount,
                coin_option
            ) = reward_actions::claim_value_for_testing(
                &mut analytics,
                &app,
                &mint_config,
                &reward_witness_config,
                &mut protected_treasury,
                
                ts::ctx(scenario)
            );

            assert!(amount == 0);
            assert!(coin_option.is_none());

            destroy(coin_option);

            analytics
        };

        ts::next_tx(scenario, ADMIN);
        {
            let metric = utf8(b"no-reward-weight");
            let claim = 0;

            analytics_actions::increment_analytics_for_testing(
                &mut analytics,
                object::id_address(&app),
                claim,
                metric
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let metric = utf8(b"no-reward-weight");
            let value = 8;

            reward_actions::add_weight(
                &reward_cap,
                &mut reward_weights_registry,
                metric,
                value
            );

            let reward_weights = reward_weights_registry.borrow_current();

            let weight = reward_weights.get_weight(metric);

            assert!(weight == value);

            destroy(analytics);

            destroy_for_testing(
                app,
                clock,
                mint_config,
                protected_treasury,
                reward_cap,
                reward_weights_registry,
                reward_witness_config,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_claim_non_zero() {
        let (
            mut scenario_val,
            app,
            clock,
            mint_config,
            mut protected_treasury,
            reward_cap,
            mut reward_weights_registry,
            reward_witness_config,
            user_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let claim = 100;
        let metric = utf8(b"reward-weight");
        let weight = claim * SCALE_FACTOR;

        ts::next_tx(scenario, ADMIN);
        {
            reward_actions::start_epochs(
                &reward_cap,
                &clock,
                &mut reward_weights_registry,
                ts::ctx(scenario)
            );

            reward_actions::add_weight(
                &reward_cap,
                &mut reward_weights_registry,
                metric,
                weight
            );
        };

        ts::next_tx(scenario, ADMIN);
        let mut analytics = {
            let mut analytics = analytics::create_for_testing(ts::ctx(scenario));

            analytics_actions::increment_analytics_for_testing(
                &mut analytics,
                object::id_address(&app),
                weight,
                metric
            );

            analytics
        };

        ts::next_tx(scenario, ADMIN);
        {
            let (
                amount,
                coin_option
            ) = reward_actions::claim_value_for_testing(
                &mut analytics,
                &app,
                &mint_config,
                &reward_witness_config,
                &mut protected_treasury,
                ts::ctx(scenario)
            );

            assert!(amount == weight);
            assert!(coin_option.is_some());

            let coin = coin_option.destroy_some();
            let balance = coin.balance();

            assert!(balance.value() == claim);

            destroy(coin);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let reward_weights = reward_weights_registry.borrow_current();

            let retrieved_weight = reward_weights.get_weight(metric);

            assert!(retrieved_weight == weight);

            destroy(analytics);

            destroy_for_testing(
                app,
                clock,
                mint_config,
                protected_treasury,
                reward_cap,
                reward_weights_registry,
                reward_witness_config,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_claim_from_user() {
        let (
            mut scenario_val,
            app,
            clock,
            mint_config,
            mut protected_treasury,
            reward_cap,
            mut reward_weights_registry,
            reward_witness_config,
            user_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            reward_actions::start_epochs(
                &reward_cap,
                &clock,
                &mut reward_weights_registry,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut analytics = analytics::create_for_testing(ts::ctx(scenario));

            let valid_witness = admin_access::create_valid_witness_for_testing();

            let (
                amount,
                coin_option
            ) = reward_actions::claim_value_for_user<ValidWitness>(
                &mut analytics,
                &app,
                &mint_config,
                &reward_witness_config,
                &mut protected_treasury,
                &valid_witness,
                &user_witness_config,
                ts::ctx(scenario)
            );

            assert!(amount == 0);
            assert!(coin_option.is_none());

            destroy(analytics);
            destroy(coin_option);

            destroy_for_testing(
                app,
                clock,
                mint_config,
                protected_treasury,
                reward_cap,
                reward_weights_registry,
                reward_witness_config,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EWitnessMismatch)]
    fun test_claim_from_user_fail() {
        let (
            mut scenario_val,
            app,
            clock,
            mint_config,
            mut protected_treasury,
            reward_cap,
            mut reward_weights_registry,
            reward_witness_config,
            user_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            reward_actions::start_epochs(
                &reward_cap,
                &clock,
                &mut reward_weights_registry,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut analytics = analytics::create_for_testing(ts::ctx(scenario));

            let invalid_witness = admin_access::create_invalid_witness_for_testing();

            let (
                amount,
                coin_option
            ) = reward_actions::claim_value_for_user<InvalidWitness>(
                &mut analytics,
                &app,
                &mint_config,
                &reward_witness_config,
                &mut protected_treasury,
                &invalid_witness,
                &user_witness_config,
                ts::ctx(scenario)
            );

            assert!(amount == 0);
            assert!(coin_option.is_none());

            destroy(analytics);
            destroy(coin_option);

            destroy_for_testing(
                app,
                clock,
                mint_config,
                protected_treasury,
                reward_cap,
                reward_weights_registry,
                reward_witness_config,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }
}
