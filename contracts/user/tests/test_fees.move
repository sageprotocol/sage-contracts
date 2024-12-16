#[test_only]
module sage_user::test_user_fees {
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
        apps::{Self, App}
    };

    use sage_user::{
        user_fees::{
            Self,
            EIncorrectCoinType,
            EIncorrectCustomPayment,
            EIncorrectSuiPayment
        }
    };

    #[test_only]
    public struct FAKE_FEE_COIN has drop {}

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    const CREATE_INVITE_CUSTOM_FEE: u64 = 1;
    const CREATE_INVITE_SUI_FEE: u64 = 2;
    const CREATE_USER_CUSTOM_FEE: u64 = 3;
    const CREATE_USER_SUI_FEE: u64 = 4;
    const JOIN_USER_CUSTOM_FEE: u64 = 5;
    const JOIN_USER_SUI_FEE: u64 = 6;
    const LEAVE_USER_CUSTOM_FEE: u64 = 7;
    const LEAVE_USER_SUI_FEE: u64 = 8;
    const UPDATE_USER_CUSTOM_FEE: u64 = 9;
    const UPDATE_USER_SUI_FEE: u64 = 10;
    const INCORRECT_FEE: u64 = 100;

    // --------------- Errors ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    fun destroy_for_testing(
        app: App
    ) {
        destroy(app);
    }

    #[test_only]
    fun setup_for_testing(): (
        Scenario,
        App,
    ) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
            apps::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let app = {
            let app = apps::create_for_testing(
                utf8(b"sage"),
                ts::ctx(scenario)
            );

            app
        };

        (
            scenario_val,
            app
        )
    }

    #[test]
    fun test_init() {
        let (
            mut scenario_val,
            app
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                app
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_create() {
        let (
            mut scenario_val,
            mut app
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            let user_fees = user_fees::create_for_testing<SUI>(
                &mut app,
                CREATE_INVITE_CUSTOM_FEE,
                CREATE_INVITE_SUI_FEE,
                CREATE_USER_CUSTOM_FEE,
                CREATE_USER_SUI_FEE,
                JOIN_USER_CUSTOM_FEE,
                JOIN_USER_SUI_FEE,
                LEAVE_USER_CUSTOM_FEE,
                LEAVE_USER_SUI_FEE,
                UPDATE_USER_CUSTOM_FEE,
                UPDATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                CREATE_INVITE_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_INVITE_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = user_fees::assert_create_invite_payment<SUI>(
                &user_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = user_fees::assert_create_user_payment<SUI>(
                &user_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            let custom_payment = mint_for_testing<SUI>(
                JOIN_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                JOIN_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = user_fees::assert_join_user_payment<SUI>(
                &user_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            let custom_payment = mint_for_testing<SUI>(
                LEAVE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                LEAVE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = user_fees::assert_leave_user_payment<SUI>(
                &user_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            let custom_payment = mint_for_testing<SUI>(
                UPDATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                UPDATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = user_fees::assert_update_user_payment<SUI>(
                &user_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            ts::return_to_sender(scenario, fee_cap);

            destroy_for_testing(
                app
            );

            destroy(user_fees);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_create_invite_custom_fail() {
        let (
            mut scenario_val,
            mut app
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            let user_fees = user_fees::create_for_testing<SUI>(
                &mut app,
                CREATE_INVITE_CUSTOM_FEE,
                CREATE_INVITE_SUI_FEE,
                CREATE_USER_CUSTOM_FEE,
                CREATE_USER_SUI_FEE,
                JOIN_USER_CUSTOM_FEE,
                JOIN_USER_SUI_FEE,
                LEAVE_USER_CUSTOM_FEE,
                LEAVE_USER_SUI_FEE,
                UPDATE_USER_CUSTOM_FEE,
                UPDATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_INVITE_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = user_fees::assert_create_invite_payment<SUI>(
                &user_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            ts::return_to_sender(scenario, fee_cap);

            destroy_for_testing(
                app
            );

            destroy(user_fees);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_create_invite_sui_fail() {
        let (
            mut scenario_val,
            mut app
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            let user_fees = user_fees::create_for_testing<SUI>(
                &mut app,
                CREATE_INVITE_CUSTOM_FEE,
                CREATE_INVITE_SUI_FEE,
                CREATE_USER_CUSTOM_FEE,
                CREATE_USER_SUI_FEE,
                JOIN_USER_CUSTOM_FEE,
                JOIN_USER_SUI_FEE,
                LEAVE_USER_CUSTOM_FEE,
                LEAVE_USER_SUI_FEE,
                UPDATE_USER_CUSTOM_FEE,
                UPDATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                CREATE_INVITE_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = user_fees::assert_create_invite_payment<SUI>(
                &user_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            ts::return_to_sender(scenario, fee_cap);

            destroy_for_testing(
                app
            );

            destroy(user_fees);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_create_user_custom_fail() {
        let (
            mut scenario_val,
            mut app
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            let user_fees = user_fees::create_for_testing<SUI>(
                &mut app,
                CREATE_INVITE_CUSTOM_FEE,
                CREATE_INVITE_SUI_FEE,
                CREATE_USER_CUSTOM_FEE,
                CREATE_USER_SUI_FEE,
                JOIN_USER_CUSTOM_FEE,
                JOIN_USER_SUI_FEE,
                LEAVE_USER_CUSTOM_FEE,
                LEAVE_USER_SUI_FEE,
                UPDATE_USER_CUSTOM_FEE,
                UPDATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = user_fees::assert_create_user_payment<SUI>(
                &user_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            ts::return_to_sender(scenario, fee_cap);

            destroy_for_testing(
                app
            );

            destroy(user_fees);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_create_user_sui_fail() {
        let (
            mut scenario_val,
            mut app
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            let user_fees = user_fees::create_for_testing<SUI>(
                &mut app,
                CREATE_INVITE_CUSTOM_FEE,
                CREATE_INVITE_SUI_FEE,
                CREATE_USER_CUSTOM_FEE,
                CREATE_USER_SUI_FEE,
                JOIN_USER_CUSTOM_FEE,
                JOIN_USER_SUI_FEE,
                LEAVE_USER_CUSTOM_FEE,
                LEAVE_USER_SUI_FEE,
                UPDATE_USER_CUSTOM_FEE,
                UPDATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                CREATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = user_fees::assert_create_user_payment<SUI>(
                &user_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            ts::return_to_sender(scenario, fee_cap);

            destroy_for_testing(
                app
            );

            destroy(user_fees);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_join_user_custom_fail() {
        let (
            mut scenario_val,
            mut app
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            let user_fees = user_fees::create_for_testing<SUI>(
                &mut app,
                CREATE_INVITE_CUSTOM_FEE,
                CREATE_INVITE_SUI_FEE,
                CREATE_USER_CUSTOM_FEE,
                CREATE_USER_SUI_FEE,
                JOIN_USER_CUSTOM_FEE,
                JOIN_USER_SUI_FEE,
                LEAVE_USER_CUSTOM_FEE,
                LEAVE_USER_SUI_FEE,
                UPDATE_USER_CUSTOM_FEE,
                UPDATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                JOIN_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = user_fees::assert_join_user_payment<SUI>(
                &user_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            ts::return_to_sender(scenario, fee_cap);

            destroy_for_testing(
                app
            );

            destroy(user_fees);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_join_user_sui_fail() {
        let (
            mut scenario_val,
            mut app
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            let user_fees = user_fees::create_for_testing<SUI>(
                &mut app,
                CREATE_INVITE_CUSTOM_FEE,
                CREATE_INVITE_SUI_FEE,
                CREATE_USER_CUSTOM_FEE,
                CREATE_USER_SUI_FEE,
                JOIN_USER_CUSTOM_FEE,
                JOIN_USER_SUI_FEE,
                LEAVE_USER_CUSTOM_FEE,
                LEAVE_USER_SUI_FEE,
                UPDATE_USER_CUSTOM_FEE,
                UPDATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                JOIN_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = user_fees::assert_join_user_payment<SUI>(
                &user_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            ts::return_to_sender(scenario, fee_cap);

            destroy_for_testing(
                app
            );

            destroy(user_fees);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_leave_user_custom_fail() {
        let (
            mut scenario_val,
            mut app
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            let user_fees = user_fees::create_for_testing<SUI>(
                &mut app,
                CREATE_INVITE_CUSTOM_FEE,
                CREATE_INVITE_SUI_FEE,
                CREATE_USER_CUSTOM_FEE,
                CREATE_USER_SUI_FEE,
                JOIN_USER_CUSTOM_FEE,
                JOIN_USER_SUI_FEE,
                LEAVE_USER_CUSTOM_FEE,
                LEAVE_USER_SUI_FEE,
                UPDATE_USER_CUSTOM_FEE,
                UPDATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                LEAVE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = user_fees::assert_leave_user_payment<SUI>(
                &user_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            ts::return_to_sender(scenario, fee_cap);

            destroy_for_testing(
                app
            );

            destroy(user_fees);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_leave_user_sui_fail() {
        let (
            mut scenario_val,
            mut app
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            let user_fees = user_fees::create_for_testing<SUI>(
                &mut app,
                CREATE_INVITE_CUSTOM_FEE,
                CREATE_INVITE_SUI_FEE,
                CREATE_USER_CUSTOM_FEE,
                CREATE_USER_SUI_FEE,
                JOIN_USER_CUSTOM_FEE,
                JOIN_USER_SUI_FEE,
                LEAVE_USER_CUSTOM_FEE,
                LEAVE_USER_SUI_FEE,
                UPDATE_USER_CUSTOM_FEE,
                UPDATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                LEAVE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = user_fees::assert_leave_user_payment<SUI>(
                &user_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            ts::return_to_sender(scenario, fee_cap);

            destroy_for_testing(
                app
            );

            destroy(user_fees);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_update_user_custom_fail() {
        let (
            mut scenario_val,
            mut app
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            let user_fees = user_fees::create_for_testing<SUI>(
                &mut app,
                CREATE_INVITE_CUSTOM_FEE,
                CREATE_INVITE_SUI_FEE,
                CREATE_USER_CUSTOM_FEE,
                CREATE_USER_SUI_FEE,
                JOIN_USER_CUSTOM_FEE,
                JOIN_USER_SUI_FEE,
                LEAVE_USER_CUSTOM_FEE,
                LEAVE_USER_SUI_FEE,
                UPDATE_USER_CUSTOM_FEE,
                UPDATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                UPDATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = user_fees::assert_update_user_payment<SUI>(
                &user_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            ts::return_to_sender(scenario, fee_cap);

            destroy_for_testing(
                app
            );

            destroy(user_fees);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_update_user_sui_fail() {
        let (
            mut scenario_val,
            mut app
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            let user_fees = user_fees::create_for_testing<SUI>(
                &mut app,
                CREATE_INVITE_CUSTOM_FEE,
                CREATE_INVITE_SUI_FEE,
                CREATE_USER_CUSTOM_FEE,
                CREATE_USER_SUI_FEE,
                JOIN_USER_CUSTOM_FEE,
                JOIN_USER_SUI_FEE,
                LEAVE_USER_CUSTOM_FEE,
                LEAVE_USER_SUI_FEE,
                UPDATE_USER_CUSTOM_FEE,
                UPDATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                UPDATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = user_fees::assert_update_user_payment<SUI>(
                &user_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            ts::return_to_sender(scenario, fee_cap);

            destroy_for_testing(
                app
            );

            destroy(user_fees);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCoinType)]
    fun test_fee_coin_type() {
        let (
            mut scenario_val,
            mut app
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            let user_fees = user_fees::create_for_testing<FAKE_FEE_COIN>(
                &mut app,
                CREATE_INVITE_CUSTOM_FEE,
                CREATE_INVITE_SUI_FEE,
                CREATE_USER_CUSTOM_FEE,
                CREATE_USER_SUI_FEE,
                JOIN_USER_CUSTOM_FEE,
                JOIN_USER_SUI_FEE,
                LEAVE_USER_CUSTOM_FEE,
                LEAVE_USER_SUI_FEE,
                UPDATE_USER_CUSTOM_FEE,
                UPDATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                UPDATE_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                UPDATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = user_fees::assert_update_user_payment<SUI>(
                &user_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            ts::return_to_sender(scenario, fee_cap);

            destroy_for_testing(
                app
            );

            destroy(user_fees);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_update() {
        let (
            mut scenario_val,
            mut app
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            let mut user_fees = user_fees::create_for_testing<SUI>(
                &mut app,
                CREATE_INVITE_CUSTOM_FEE,
                CREATE_INVITE_SUI_FEE,
                CREATE_USER_CUSTOM_FEE,
                CREATE_USER_SUI_FEE,
                JOIN_USER_CUSTOM_FEE,
                JOIN_USER_SUI_FEE,
                LEAVE_USER_CUSTOM_FEE,
                LEAVE_USER_SUI_FEE,
                UPDATE_USER_CUSTOM_FEE,
                UPDATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            user_fees::update<SUI>(
                &fee_cap,
                &mut user_fees,
                INCORRECT_FEE,
                INCORRECT_FEE,
                INCORRECT_FEE,
                INCORRECT_FEE,
                INCORRECT_FEE,
                INCORRECT_FEE,
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

            let (custom_payment, sui_payment) = user_fees::assert_create_invite_payment<SUI>(
                &user_fees,
                custom_payment,
                sui_payment
            );

            let (custom_payment, sui_payment) = user_fees::assert_create_user_payment<SUI>(
                &user_fees,
                custom_payment,
                sui_payment
            );

            let (custom_payment, sui_payment) = user_fees::assert_join_user_payment<SUI>(
                &user_fees,
                custom_payment,
                sui_payment
            );

            let (custom_payment, sui_payment) = user_fees::assert_leave_user_payment<SUI>(
                &user_fees,
                custom_payment,
                sui_payment
            );

            let (custom_payment, sui_payment) = user_fees::assert_update_user_payment<SUI>(
                &user_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            ts::return_to_sender(scenario, fee_cap);

            destroy_for_testing(
                app
            );

            destroy(user_fees);
        };

        ts::end(scenario_val);
    }
}
