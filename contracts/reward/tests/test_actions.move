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
        access::{
            Self as trust_access,
            TrustConfig
        },
        trust::{
            Self,
            ProtectedTreasury
        }
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    fun destroy_for_testing(
        app: App,
        clock: Clock,
        protected_treasury: ProtectedTreasury,
        reward_cap: RewardCap,
        reward_weights_registry: RewardWeightsRegistry,
        trust_config: TrustConfig
    ) {
        destroy(app);
        destroy(clock);
        destroy(protected_treasury);
        destroy(reward_cap);
        destroy(reward_weights_registry);
        destroy(trust_config);
    }

    #[test_only]
    fun setup_for_testing(): (
        Scenario,
        App,
        Clock,
        ProtectedTreasury,
        RewardCap,
        RewardWeightsRegistry,
        TrustConfig
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
        let trust_config = {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            let mut trust_config = ts::take_shared<TrustConfig>(scenario);

            trust_access::update<RewardWitness>(
                &admin_cap,
                &mut trust_config
            );

            ts::return_to_sender(scenario, admin_cap);

            trust_config
        };

        ts::next_tx(scenario, ADMIN);
        let (
            app,
            protected_treasury,
            reward_weights_registry
        ) = {
            let mut app = apps::create_for_testing(
                utf8(b"sage"),
                ts::ctx(scenario)
            );

            let protected_treasury = scenario.take_shared<ProtectedTreasury>();
            let reward_weights_registry = scenario.take_shared<RewardWeightsRegistry>();

            (
                app,
                protected_treasury,
                reward_weights_registry
            )
        };

        (
            scenario_val,
            app,
            clock,
            protected_treasury,
            reward_cap,
            reward_weights_registry,
            trust_config
        )
    }

    #[test]
    fun test_start() {
        let (
            mut scenario_val,
            app,
            clock,
            protected_treasury,
            reward_cap,
            mut reward_weights_registry,
            trust_config
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
                protected_treasury,
                reward_cap,
                reward_weights_registry,
                trust_config
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
            protected_treasury,
            reward_cap,
            mut reward_weights_registry,
            trust_config
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
                protected_treasury,
                reward_cap,
                reward_weights_registry,
                trust_config
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
            protected_treasury,
            reward_cap,
            mut reward_weights_registry,
            trust_config
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
                protected_treasury,
                reward_cap,
                reward_weights_registry,
                trust_config
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
            protected_treasury,
            reward_cap,
            mut reward_weights_registry,
            trust_config
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
                protected_treasury,
                reward_cap,
                reward_weights_registry,
                trust_config
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
            mut protected_treasury,
            reward_cap,
            mut reward_weights_registry,
            trust_config
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
            ) = reward_actions::claim_value(
                &mut analytics,
                &app,
                &mut protected_treasury,
                &trust_config,
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
                protected_treasury,
                reward_cap,
                reward_weights_registry,
                trust_config
            );
        };

        ts::end(scenario_val);
    }
}
