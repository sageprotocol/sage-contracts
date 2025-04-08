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
        apps::{Self}
    };

    use sage_user::{
        user_fees::{
            Self,
            UserFees,
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
    const FOLLOW_USER_CUSTOM_FEE: u64 = 5;
    const FOLLOW_USER_SUI_FEE: u64 = 6;
    const FRIEND_USER_CUSTOM_FEE: u64 = 7;
    const FRIEND_USER_SUI_FEE: u64 = 8;
    const POST_TO_USER_CUSTOM_FEE: u64 = 9;
    const POST_TO_USER_SUI_FEE: u64 = 10;
    const UNFOLLOW_USER_CUSTOM_FEE: u64 = 11;
    const UNFOLLOW_USER_SUI_FEE: u64 = 12;
    const UNFRIEND_USER_CUSTOM_FEE: u64 = 13;
    const UNFRIEND_USER_SUI_FEE: u64 = 14;
    const UPDATE_USER_CUSTOM_FEE: u64 = 15;
    const UPDATE_USER_SUI_FEE: u64 = 16;
    
    const INCORRECT_FEE: u64 = 100;

    // --------------- Errors ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    fun destroy_for_testing(
        fee_cap: FeeCap,
        user_fees: UserFees
    ) {
        ts::return_to_address(ADMIN, fee_cap);
        destroy(user_fees);
    }

    #[test_only]
    fun setup_for_testing<CoinType>(): (
        Scenario,
        FeeCap,
        UserFees
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

            let fee_cap = ts::take_from_address<FeeCap>(scenario, ADMIN);

            user_fees::create<CoinType>(
                &fee_cap,
                &mut app,
                CREATE_INVITE_CUSTOM_FEE,
                CREATE_INVITE_SUI_FEE,
                CREATE_USER_CUSTOM_FEE,
                CREATE_USER_SUI_FEE,
                FOLLOW_USER_CUSTOM_FEE,
                FOLLOW_USER_SUI_FEE,
                FRIEND_USER_CUSTOM_FEE,
                FRIEND_USER_SUI_FEE,
                POST_TO_USER_CUSTOM_FEE,
                POST_TO_USER_SUI_FEE,
                UNFOLLOW_USER_CUSTOM_FEE,
                UNFOLLOW_USER_SUI_FEE,
                UNFRIEND_USER_CUSTOM_FEE,
                UNFRIEND_USER_SUI_FEE,
                UPDATE_USER_CUSTOM_FEE,
                UPDATE_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            destroy(app);

            fee_cap
        };

        ts::next_tx(scenario, ADMIN);
        let user_fees = {
            let user_fees = ts::take_shared<UserFees>(scenario);

            user_fees
        };

        (
            scenario_val,
            fee_cap,
            user_fees
        )
    }

    #[test]
    fun test_init() {
        let (
            mut scenario_val,
            fee_cap,
            user_fees
        ) = setup_for_testing<SUI>();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                fee_cap,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_create() {
        let (
            mut scenario_val,
            fee_cap,
            user_fees
        ) = setup_for_testing<SUI>();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
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
                FOLLOW_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                FOLLOW_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = user_fees::assert_follow_user_payment<SUI>(
                &user_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            let custom_payment = mint_for_testing<SUI>(
                UNFOLLOW_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                UNFOLLOW_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = user_fees::assert_unfollow_user_payment<SUI>(
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

            destroy_for_testing(
                fee_cap,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_create_invite_custom_fail() {
        let (
            mut scenario_val,
            fee_cap,
            user_fees
        ) = setup_for_testing<SUI>();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
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

            destroy_for_testing(
                fee_cap,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_create_invite_sui_fail() {
        let (
            mut scenario_val,
            fee_cap,
            user_fees
        ) = setup_for_testing<SUI>();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
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

            destroy_for_testing(
                fee_cap,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_create_user_custom_fail() {
        let (
            mut scenario_val,
            fee_cap,
            user_fees
        ) = setup_for_testing<SUI>();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
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

            destroy_for_testing(
                fee_cap,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_create_user_sui_fail() {
        let (
            mut scenario_val,
            fee_cap,
            user_fees
        ) = setup_for_testing<SUI>();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
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

            destroy_for_testing(
                fee_cap,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_follow_user_custom_fail() {
        let (
            mut scenario_val,
            fee_cap,
            user_fees
        ) = setup_for_testing<SUI>();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                FOLLOW_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = user_fees::assert_follow_user_payment<SUI>(
                &user_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            destroy_for_testing(
                fee_cap,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_follow_user_sui_fail() {
        let (
            mut scenario_val,
            fee_cap,
            user_fees
        ) = setup_for_testing<SUI>();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                FOLLOW_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = user_fees::assert_follow_user_payment<SUI>(
                &user_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            destroy_for_testing(
                fee_cap,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_friend_user_custom_fail() {
        let (
            mut scenario_val,
            fee_cap,
            user_fees
        ) = setup_for_testing<SUI>();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                FRIEND_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = user_fees::assert_friend_user_payment<SUI>(
                &user_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            destroy_for_testing(
                fee_cap,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_friend_user_sui_fail() {
        let (
            mut scenario_val,
            fee_cap,
            user_fees
        ) = setup_for_testing<SUI>();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                FRIEND_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = user_fees::assert_friend_user_payment<SUI>(
                &user_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            destroy_for_testing(
                fee_cap,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_unfollow_user_custom_fail() {
        let (
            mut scenario_val,
            fee_cap,
            user_fees
        ) = setup_for_testing<SUI>();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                UNFOLLOW_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = user_fees::assert_unfollow_user_payment<SUI>(
                &user_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            destroy_for_testing(
                fee_cap,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_unfollow_user_sui_fail() {
        let (
            mut scenario_val,
            fee_cap,
            user_fees
        ) = setup_for_testing<SUI>();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                UNFOLLOW_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = user_fees::assert_unfollow_user_payment<SUI>(
                &user_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            destroy_for_testing(
                fee_cap,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_unfriend_user_custom_fail() {
        let (
            mut scenario_val,
            fee_cap,
            user_fees
        ) = setup_for_testing<SUI>();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                UNFRIEND_USER_SUI_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = user_fees::assert_unfriend_user_payment<SUI>(
                &user_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            destroy_for_testing(
                fee_cap,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_unfriend_user_sui_fail() {
        let (
            mut scenario_val,
            fee_cap,
            user_fees
        ) = setup_for_testing<SUI>();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<SUI>(
                UNFRIEND_USER_CUSTOM_FEE,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                INCORRECT_FEE,
                ts::ctx(scenario)
            );

            let (custom_payment, sui_payment) = user_fees::assert_unfriend_user_payment<SUI>(
                &user_fees,
                custom_payment,
                sui_payment
            );

            burn_for_testing(custom_payment);
            burn_for_testing(sui_payment);

            destroy_for_testing(
                fee_cap,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectCustomPayment)]
    fun test_update_user_custom_fail() {
        let (
            mut scenario_val,
            fee_cap,
            user_fees
        ) = setup_for_testing<SUI>();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
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

            destroy_for_testing(
                fee_cap,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectSuiPayment)]
    fun test_update_user_sui_fail() {
        let (
            mut scenario_val,
            fee_cap,
            user_fees
        ) = setup_for_testing<SUI>();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
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

            destroy_for_testing(
                fee_cap,
                user_fees
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
            user_fees
        ) = setup_for_testing<FAKE_FEE_COIN>();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
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

            destroy_for_testing(
                fee_cap,
                user_fees
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_update() {
        let (
            mut scenario_val,
            fee_cap,
            mut user_fees
        ) = setup_for_testing<SUI>();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
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

            let (custom_payment, sui_payment) = user_fees::assert_follow_user_payment<SUI>(
                &user_fees,
                custom_payment,
                sui_payment
            );

            let (custom_payment, sui_payment) = user_fees::assert_follow_user_payment<SUI>(
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

            destroy_for_testing(
                fee_cap,
                user_fees
            );
        };

        ts::end(scenario_val);
    }
}
