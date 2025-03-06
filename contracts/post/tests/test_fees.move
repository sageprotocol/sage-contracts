#[test_only]
module sage_post::test_post_fees {
    use std::string::{utf8};

    use sui::{
        coin::{burn_for_testing, mint_for_testing},
        sui::{SUI},
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy}
    };

    use sage_admin::{
        admin::{
            Self,
            FeeCap
        },
        apps::{Self}
    };

    use sage_post::{
        post_fees::{
            Self,
            PostFees,
            EIncorrectCoinType,
            EIncorrectCustomPayment,
            EIncorrectSuiPayment
        }
    };

    #[test_only]
    public struct FAKE_FEE_COIN has drop {}

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    const LIKE_POST_CUSTOM_FEE: u64 = 1;
    const LIKE_POST_SUI_FEE: u64 = 2;
    const POST_FROM_POST_CUSTOM_FEE: u64 = 3;
    const POST_FROM_POST_SUI_FEE: u64 = 4;
    const INCORRECT_FEE: u64 = 100;

    // --------------- Errors ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    fun destroy_for_testing(
        fee_cap: FeeCap,
        post_fees: PostFees
    ) {
        ts::return_to_address(ADMIN, fee_cap);
        destroy(post_fees)
    }

    #[test_only]
    fun setup_for_testing<CoinType>(): (
        Scenario,
        FeeCap,
        PostFees
    ) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
            apps::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let fee_cap = {
            let mut app = apps::create_for_testing(
                utf8(b"sage"),
                ts::ctx(scenario)
            );

            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            post_fees::create<CoinType>(
                &fee_cap,
                &mut app,
                LIKE_POST_CUSTOM_FEE,
                LIKE_POST_SUI_FEE,
                POST_FROM_POST_CUSTOM_FEE,
                POST_FROM_POST_SUI_FEE,
                ts::ctx(scenario)
            );

            destroy(app);

            fee_cap
        };

        ts::next_tx(scenario, ADMIN);
        let post_fees = {
            let post_fees = ts::take_shared<PostFees>(scenario);

            post_fees
        };

        (
            scenario_val,
            fee_cap,
            post_fees
        )
    }

    #[test]
    fun test_init() {
        let (
            mut scenario_val,
            fee_cap,
            post_fees
        ) = setup_for_testing<SUI>();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                fee_cap,
                post_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_create() {
        let (
            mut scenario_val,
            fee_cap,
            post_fees
        ) = setup_for_testing<SUI>();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                LIKE_POST_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                LIKE_POST_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = post_fees::assert_like_post_payment<SUI>(
                &post_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            let custom_payment = mint_for_testing<SUI>(
                POST_FROM_POST_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                POST_FROM_POST_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = post_fees::assert_post_from_post_payment<SUI>(
                &post_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            destroy_for_testing(
                fee_cap,
                post_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_like_post_custom_fail() {
        let (
            mut scenario_val,
            fee_cap,
            post_fees
        ) = setup_for_testing<SUI>();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                LIKE_POST_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = post_fees::assert_like_post_payment<SUI>(
                &post_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            destroy_for_testing(
                fee_cap,
                post_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_like_post_sui_fail() {
        let (
            mut scenario_val,
            fee_cap,
            post_fees
        ) = setup_for_testing<SUI>();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                LIKE_POST_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = post_fees::assert_like_post_payment<SUI>(
                &post_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            destroy_for_testing(
                fee_cap,
                post_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_post_from_post_custom_fail() {
        let (
            mut scenario_val,
            fee_cap,
            post_fees
        ) = setup_for_testing<SUI>();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                POST_FROM_POST_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = post_fees::assert_post_from_post_payment<SUI>(
                &post_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            destroy_for_testing(
                fee_cap,
                post_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_post_from_post_sui_fail() {
        let (
            mut scenario_val,
            fee_cap,
            post_fees
        ) = setup_for_testing<SUI>();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                POST_FROM_POST_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = post_fees::assert_post_from_post_payment<SUI>(
                &post_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            destroy_for_testing(
                fee_cap,
                post_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCoinType)]
    fun test_fee_coin_type() {
        let (
            mut scenario_val,
            fee_cap,
            post_fees
        ) = setup_for_testing<FAKE_FEE_COIN>();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                LIKE_POST_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                LIKE_POST_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = post_fees::assert_like_post_payment<SUI>(
                &post_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            destroy_for_testing(
                fee_cap,
                post_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_update() {
        let (
            mut scenario_val,
            fee_cap,
            mut post_fees
        ) = setup_for_testing<SUI>();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            post_fees::update<SUI>(
                &fee_cap,
                &mut post_fees,
                INCORRECT_FEE,
                INCORRECT_FEE,
                INCORRECT_FEE,
                INCORRECT_FEE
            );

            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = post_fees::assert_like_post_payment<SUI>(
                &post_fees,
                custom_payment,
                sui_payment
            );

            let (custom_payment, sui_payment) = post_fees::assert_post_from_post_payment<SUI>(
                &post_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            destroy_for_testing(
                fee_cap,
                post_fees
            );
        };

        ts::end(scenario_val);
    }
}
