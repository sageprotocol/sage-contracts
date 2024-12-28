#[test_only]
module sage_channel::test_channel_fees {
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

    use sage_channel::{
        channel_fees::{
            Self,
            ChannelFees,
            EIncorrectCoinType,
            EIncorrectCustomPayment,
            EIncorrectSuiPayment
        }
    };

    #[test_only]
    public struct FAKE_FEE_COIN has drop {}

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    const ADD_MODERATOR_CUSTOM_FEE: u64 = 1;
    const ADD_MODERATOR_SUI_FEE: u64 = 2;
    const CREATE_CHANNEL_CUSTOM_FEE: u64 = 3;
    const CREATE_CHANNEL_SUI_FEE: u64 = 4;
    const JOIN_CHANNEL_CUSTOM_FEE: u64 = 5;
    const JOIN_CHANNEL_SUI_FEE: u64 = 6;
    const LEAVE_CHANNEL_CUSTOM_FEE: u64 = 7;
    const LEAVE_CHANNEL_SUI_FEE: u64 = 8;
    const REMOVE_MODERATOR_CUSTOM_FEE: u64 = 9;
    const REMOVE_MODERATOR_SUI_FEE: u64 = 10;
    const UPDATE_CHANNEL_CUSTOM_FEE: u64 = 11;
    const UPDATE_CHANNEL_SUI_FEE: u64 = 12;
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

            channel_fees::create<SUI>(
                &fee_cap,
                &mut app,
                ADD_MODERATOR_CUSTOM_FEE,
                ADD_MODERATOR_SUI_FEE,
                CREATE_CHANNEL_CUSTOM_FEE,
                CREATE_CHANNEL_SUI_FEE,
                JOIN_CHANNEL_CUSTOM_FEE,
                JOIN_CHANNEL_SUI_FEE,
                LEAVE_CHANNEL_CUSTOM_FEE,
                LEAVE_CHANNEL_SUI_FEE,
                REMOVE_MODERATOR_CUSTOM_FEE,
                REMOVE_MODERATOR_SUI_FEE,
                UPDATE_CHANNEL_CUSTOM_FEE,
                UPDATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, fee_cap);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let channel_fees = ts::take_shared<ChannelFees>(
                scenario
            );

            let custom_payment = mint_for_testing<SUI>(
                ADD_MODERATOR_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                ADD_MODERATOR_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = channel_fees::assert_add_moderator_owner_payment<SUI>(
                &channel_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            let custom_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = channel_fees::assert_create_channel_payment<SUI>(
                &channel_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            let custom_payment = mint_for_testing<SUI>(
                JOIN_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                JOIN_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = channel_fees::assert_join_channel_payment<SUI>(
                &channel_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            let custom_payment = mint_for_testing<SUI>(
                LEAVE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                LEAVE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = channel_fees::assert_leave_channel_payment<SUI>(
                &channel_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            let custom_payment = mint_for_testing<SUI>(
                REMOVE_MODERATOR_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                REMOVE_MODERATOR_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = channel_fees::assert_remove_moderator_owner_payment<SUI>(
                &channel_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            let custom_payment = mint_for_testing<SUI>(
                UPDATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                UPDATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = channel_fees::assert_update_channel_payment<SUI>(
                &channel_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            ts::return_shared(channel_fees);

            destroy_for_testing(
                app
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_add_moderator_custom_fail() {
        let (
            mut scenario_val,
            mut app
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            let channel_fees = channel_fees::create_for_testing<SUI>(
                &mut app,
                ADD_MODERATOR_CUSTOM_FEE,
                ADD_MODERATOR_SUI_FEE,
                CREATE_CHANNEL_CUSTOM_FEE,
                CREATE_CHANNEL_SUI_FEE,
                JOIN_CHANNEL_CUSTOM_FEE,
                JOIN_CHANNEL_SUI_FEE,
                LEAVE_CHANNEL_CUSTOM_FEE,
                LEAVE_CHANNEL_SUI_FEE,
                REMOVE_MODERATOR_CUSTOM_FEE,
                REMOVE_MODERATOR_SUI_FEE,
                UPDATE_CHANNEL_CUSTOM_FEE,
                UPDATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                ADD_MODERATOR_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = channel_fees::assert_add_moderator_owner_payment<SUI>(
                &channel_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            ts::return_to_sender(scenario, fee_cap);

            destroy_for_testing(
                app
            );

            destroy(channel_fees);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_add_moderator_sui_fail() {
        let (
            mut scenario_val,
            mut app
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            let channel_fees = channel_fees::create_for_testing<SUI>(
                &mut app,
                ADD_MODERATOR_CUSTOM_FEE,
                ADD_MODERATOR_SUI_FEE,
                CREATE_CHANNEL_CUSTOM_FEE,
                CREATE_CHANNEL_SUI_FEE,
                JOIN_CHANNEL_CUSTOM_FEE,
                JOIN_CHANNEL_SUI_FEE,
                LEAVE_CHANNEL_CUSTOM_FEE,
                LEAVE_CHANNEL_SUI_FEE,
                REMOVE_MODERATOR_CUSTOM_FEE,
                REMOVE_MODERATOR_SUI_FEE,
                UPDATE_CHANNEL_CUSTOM_FEE,
                UPDATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                ADD_MODERATOR_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = channel_fees::assert_add_moderator_owner_payment<SUI>(
                &channel_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            ts::return_to_sender(scenario, fee_cap);

            destroy_for_testing(
                app
            );

            destroy(channel_fees);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_create_channel_custom_fail() {
        let (
            mut scenario_val,
            mut app
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            let channel_fees = channel_fees::create_for_testing<SUI>(
                &mut app,
                ADD_MODERATOR_CUSTOM_FEE,
                ADD_MODERATOR_SUI_FEE,
                CREATE_CHANNEL_CUSTOM_FEE,
                CREATE_CHANNEL_SUI_FEE,
                JOIN_CHANNEL_CUSTOM_FEE,
                JOIN_CHANNEL_SUI_FEE,
                LEAVE_CHANNEL_CUSTOM_FEE,
                LEAVE_CHANNEL_SUI_FEE,
                REMOVE_MODERATOR_CUSTOM_FEE,
                REMOVE_MODERATOR_SUI_FEE,
                UPDATE_CHANNEL_CUSTOM_FEE,
                UPDATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = channel_fees::assert_create_channel_payment<SUI>(
                &channel_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            ts::return_to_sender(scenario, fee_cap);

            destroy_for_testing(
                app
            );

            destroy(channel_fees);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_create_channel_sui_fail() {
        let (
            mut scenario_val,
            mut app
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            let channel_fees = channel_fees::create_for_testing<SUI>(
                &mut app,
                ADD_MODERATOR_CUSTOM_FEE,
                ADD_MODERATOR_SUI_FEE,
                CREATE_CHANNEL_CUSTOM_FEE,
                CREATE_CHANNEL_SUI_FEE,
                JOIN_CHANNEL_CUSTOM_FEE,
                JOIN_CHANNEL_SUI_FEE,
                LEAVE_CHANNEL_CUSTOM_FEE,
                LEAVE_CHANNEL_SUI_FEE,
                REMOVE_MODERATOR_CUSTOM_FEE,
                REMOVE_MODERATOR_SUI_FEE,
                UPDATE_CHANNEL_CUSTOM_FEE,
                UPDATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                CREATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = channel_fees::assert_create_channel_payment<SUI>(
                &channel_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            ts::return_to_sender(scenario, fee_cap);

            destroy_for_testing(
                app
            );

            destroy(channel_fees);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_join_channel_custom_fail() {
        let (
            mut scenario_val,
            mut app
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            let channel_fees = channel_fees::create_for_testing<SUI>(
                &mut app,
                ADD_MODERATOR_CUSTOM_FEE,
                ADD_MODERATOR_SUI_FEE,
                CREATE_CHANNEL_CUSTOM_FEE,
                CREATE_CHANNEL_SUI_FEE,
                JOIN_CHANNEL_CUSTOM_FEE,
                JOIN_CHANNEL_SUI_FEE,
                LEAVE_CHANNEL_CUSTOM_FEE,
                LEAVE_CHANNEL_SUI_FEE,
                REMOVE_MODERATOR_CUSTOM_FEE,
                REMOVE_MODERATOR_SUI_FEE,
                UPDATE_CHANNEL_CUSTOM_FEE,
                UPDATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                JOIN_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = channel_fees::assert_join_channel_payment<SUI>(
                &channel_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            ts::return_to_sender(scenario, fee_cap);

            destroy_for_testing(
                app
            );

            destroy(channel_fees);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_join_channel_sui_fail() {
        let (
            mut scenario_val,
            mut app
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            let channel_fees = channel_fees::create_for_testing<SUI>(
                &mut app,
                ADD_MODERATOR_CUSTOM_FEE,
                ADD_MODERATOR_SUI_FEE,
                CREATE_CHANNEL_CUSTOM_FEE,
                CREATE_CHANNEL_SUI_FEE,
                JOIN_CHANNEL_CUSTOM_FEE,
                JOIN_CHANNEL_SUI_FEE,
                LEAVE_CHANNEL_CUSTOM_FEE,
                LEAVE_CHANNEL_SUI_FEE,
                REMOVE_MODERATOR_CUSTOM_FEE,
                REMOVE_MODERATOR_SUI_FEE,
                UPDATE_CHANNEL_CUSTOM_FEE,
                UPDATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                JOIN_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = channel_fees::assert_join_channel_payment<SUI>(
                &channel_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            ts::return_to_sender(scenario, fee_cap);

            destroy_for_testing(
                app
            );

            destroy(channel_fees);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_leave_channel_custom_fail() {
        let (
            mut scenario_val,
            mut app
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            let channel_fees = channel_fees::create_for_testing<SUI>(
                &mut app,
                ADD_MODERATOR_CUSTOM_FEE,
                ADD_MODERATOR_SUI_FEE,
                CREATE_CHANNEL_CUSTOM_FEE,
                CREATE_CHANNEL_SUI_FEE,
                JOIN_CHANNEL_CUSTOM_FEE,
                JOIN_CHANNEL_SUI_FEE,
                LEAVE_CHANNEL_CUSTOM_FEE,
                LEAVE_CHANNEL_SUI_FEE,
                REMOVE_MODERATOR_CUSTOM_FEE,
                REMOVE_MODERATOR_SUI_FEE,
                UPDATE_CHANNEL_CUSTOM_FEE,
                UPDATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                LEAVE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = channel_fees::assert_leave_channel_payment<SUI>(
                &channel_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            ts::return_to_sender(scenario, fee_cap);

            destroy_for_testing(
                app
            );

            destroy(channel_fees);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_leave_channel_sui_fail() {
        let (
            mut scenario_val,
            mut app
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            let channel_fees = channel_fees::create_for_testing<SUI>(
                &mut app,
                ADD_MODERATOR_CUSTOM_FEE,
                ADD_MODERATOR_SUI_FEE,
                CREATE_CHANNEL_CUSTOM_FEE,
                CREATE_CHANNEL_SUI_FEE,
                JOIN_CHANNEL_CUSTOM_FEE,
                JOIN_CHANNEL_SUI_FEE,
                LEAVE_CHANNEL_CUSTOM_FEE,
                LEAVE_CHANNEL_SUI_FEE,
                REMOVE_MODERATOR_CUSTOM_FEE,
                REMOVE_MODERATOR_SUI_FEE,
                UPDATE_CHANNEL_CUSTOM_FEE,
                UPDATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                LEAVE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = channel_fees::assert_leave_channel_payment<SUI>(
                &channel_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            ts::return_to_sender(scenario, fee_cap);

            destroy_for_testing(
                app
            );

            destroy(channel_fees);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_remove_moderator_custom_fail() {
        let (
            mut scenario_val,
            mut app
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            let channel_fees = channel_fees::create_for_testing<SUI>(
                &mut app,
                ADD_MODERATOR_CUSTOM_FEE,
                ADD_MODERATOR_SUI_FEE,
                CREATE_CHANNEL_CUSTOM_FEE,
                CREATE_CHANNEL_SUI_FEE,
                JOIN_CHANNEL_CUSTOM_FEE,
                JOIN_CHANNEL_SUI_FEE,
                LEAVE_CHANNEL_CUSTOM_FEE,
                LEAVE_CHANNEL_SUI_FEE,
                REMOVE_MODERATOR_CUSTOM_FEE,
                REMOVE_MODERATOR_SUI_FEE,
                UPDATE_CHANNEL_CUSTOM_FEE,
                UPDATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                REMOVE_MODERATOR_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = channel_fees::assert_remove_moderator_owner_payment<SUI>(
                &channel_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            ts::return_to_sender(scenario, fee_cap);

            destroy_for_testing(
                app
            );

            destroy(channel_fees);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_remove_moderator_sui_fail() {
        let (
            mut scenario_val,
            mut app
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            let channel_fees = channel_fees::create_for_testing<SUI>(
                &mut app,
        ADD_MODERATOR_CUSTOM_FEE,
                ADD_MODERATOR_SUI_FEE,
                CREATE_CHANNEL_CUSTOM_FEE,
                CREATE_CHANNEL_SUI_FEE,
                JOIN_CHANNEL_CUSTOM_FEE,
                JOIN_CHANNEL_SUI_FEE,
                LEAVE_CHANNEL_CUSTOM_FEE,
                LEAVE_CHANNEL_SUI_FEE,
                REMOVE_MODERATOR_CUSTOM_FEE,
                REMOVE_MODERATOR_SUI_FEE,
                UPDATE_CHANNEL_CUSTOM_FEE,
                UPDATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                REMOVE_MODERATOR_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = channel_fees::assert_remove_moderator_owner_payment<SUI>(
                &channel_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            ts::return_to_sender(scenario, fee_cap);

            destroy_for_testing(
                app
            );

            destroy(channel_fees);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_update_channel_custom_fail() {
        let (
            mut scenario_val,
            mut app
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            let channel_fees = channel_fees::create_for_testing<SUI>(
                &mut app,
                ADD_MODERATOR_CUSTOM_FEE,
                ADD_MODERATOR_SUI_FEE,
                CREATE_CHANNEL_CUSTOM_FEE,
                CREATE_CHANNEL_SUI_FEE,
                JOIN_CHANNEL_CUSTOM_FEE,
                JOIN_CHANNEL_SUI_FEE,
                LEAVE_CHANNEL_CUSTOM_FEE,
                LEAVE_CHANNEL_SUI_FEE,
                REMOVE_MODERATOR_CUSTOM_FEE,
                REMOVE_MODERATOR_SUI_FEE,
                UPDATE_CHANNEL_CUSTOM_FEE,
                UPDATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                UPDATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = channel_fees::assert_update_channel_payment<SUI>(
                &channel_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            ts::return_to_sender(scenario, fee_cap);

            destroy_for_testing(
                app
            );

            destroy(channel_fees);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_update_channel_sui_fail() {
        let (
            mut scenario_val,
            mut app
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            let channel_fees = channel_fees::create_for_testing<SUI>(
                &mut app,
                ADD_MODERATOR_CUSTOM_FEE,
                ADD_MODERATOR_SUI_FEE,
                CREATE_CHANNEL_CUSTOM_FEE,
                CREATE_CHANNEL_SUI_FEE,
                JOIN_CHANNEL_CUSTOM_FEE,
                JOIN_CHANNEL_SUI_FEE,
                LEAVE_CHANNEL_CUSTOM_FEE,
                LEAVE_CHANNEL_SUI_FEE,
                REMOVE_MODERATOR_CUSTOM_FEE,
                REMOVE_MODERATOR_SUI_FEE,
                UPDATE_CHANNEL_CUSTOM_FEE,
                UPDATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                UPDATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = channel_fees::assert_update_channel_payment<SUI>(
                &channel_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            ts::return_to_sender(scenario, fee_cap);

            destroy_for_testing(
                app
            );

            destroy(channel_fees);
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

            let channel_fees = channel_fees::create_for_testing<FAKE_FEE_COIN>(
                &mut app,
                ADD_MODERATOR_CUSTOM_FEE,
                ADD_MODERATOR_SUI_FEE,
                CREATE_CHANNEL_CUSTOM_FEE,
                CREATE_CHANNEL_SUI_FEE,
                JOIN_CHANNEL_CUSTOM_FEE,
                JOIN_CHANNEL_SUI_FEE,
                LEAVE_CHANNEL_CUSTOM_FEE,
                LEAVE_CHANNEL_SUI_FEE,
                REMOVE_MODERATOR_CUSTOM_FEE,
                REMOVE_MODERATOR_SUI_FEE,
                UPDATE_CHANNEL_CUSTOM_FEE,
                UPDATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<SUI>(
                UPDATE_CHANNEL_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                UPDATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = channel_fees::assert_update_channel_payment<SUI>(
                &channel_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            ts::return_to_sender(scenario, fee_cap);

            destroy_for_testing(
                app
            );

            destroy(channel_fees);
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
        let fee_cap = {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);

            channel_fees::create<SUI>(
                &fee_cap,
                &mut app,
                ADD_MODERATOR_CUSTOM_FEE,
                ADD_MODERATOR_SUI_FEE,
                CREATE_CHANNEL_CUSTOM_FEE,
                CREATE_CHANNEL_SUI_FEE,
                JOIN_CHANNEL_CUSTOM_FEE,
                JOIN_CHANNEL_SUI_FEE,
                LEAVE_CHANNEL_CUSTOM_FEE,
                LEAVE_CHANNEL_SUI_FEE,
                REMOVE_MODERATOR_CUSTOM_FEE,
                REMOVE_MODERATOR_SUI_FEE,
                UPDATE_CHANNEL_CUSTOM_FEE,
                UPDATE_CHANNEL_SUI_FEE,
                ts::ctx(scenario)
            );

            fee_cap
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut channel_fees = ts::take_shared<ChannelFees>(
                scenario
            );

            channel_fees::update<SUI>(
                &fee_cap,
                &mut channel_fees,
                INCORRECT_FEE,
                INCORRECT_FEE,
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

            ts::return_shared(channel_fees);

            ts::return_to_sender(scenario, fee_cap);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let channel_fees = ts::take_shared<ChannelFees>(
                scenario
            );

            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = channel_fees::assert_add_moderator_owner_payment<SUI>(
                &channel_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = channel_fees::assert_create_channel_payment<SUI>(
                &channel_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = channel_fees::assert_join_channel_payment<SUI>(
                &channel_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = channel_fees::assert_leave_channel_payment<SUI>(
                &channel_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = channel_fees::assert_remove_moderator_owner_payment<SUI>(
                &channel_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = channel_fees::assert_update_channel_payment<SUI>(
                &channel_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            ts::return_shared(channel_fees);

            destroy_for_testing(
                app
            );
        };

        ts::end(scenario_val);
    }
}
