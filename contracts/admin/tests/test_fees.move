#[test_only]
module sage_admin::test_fees {
    use std::{
        string::{utf8},
        type_name::{Self}
    };

    use sui::{
        coin::{
            Self,
            Coin,
            burn_for_testing,
            mint_for_testing
        },
        sui::{SUI},
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy}
    };

    use sage_admin::{
        admin::{
            Self,
            FeeCap,
        },
        apps::{Self, App, AppRegistry},
        fees::{Self, Royalties, EInvalidFeeValue}
    };

    #[test_only]
    public struct FAKE_FEE_COIN has drop {}

    // --------------- Constants ---------------

    const ADMIN: address = @admin;
    const CONTENT_CREATOR: address = @0xBABE;
    const PARTNER_TREASURY: address = @0xCAFE;
    const TREASURY: address = @treasury;

    // --------------- Errors ---------------

    const EAppAddressMismatch: u64 = 0;
    const ECustomCoinMismatch: u64 = 1;
    const EFeeMismatch: u64 = 2;
    const EIncorrectCustomBalance: u64 = 3;
    const EIncorrectSuiBalance: u64 = 4;
    const ETreasuryAddressMismatch: u64 = 5;

    // --------------- Test Functions ---------------

    #[test_only]
    fun destroy_for_testing(
        app: App,
        app_registry: AppRegistry
    ) {
        destroy(app);
        destroy(app_registry);
    }

    #[test_only]
    fun setup_for_testing(): (
        Scenario,
        App,
        AppRegistry
    ) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
            apps::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let (
            app,
            app_registry
        ) = {
            let app = apps::create_for_testing(
                utf8(b"sage"),
                ts::ctx(scenario)
            );

            let app_registry = scenario.take_shared<AppRegistry>();

            (
                app,
                app_registry
            )
        };

        (
            scenario_val,
            app,
            app_registry
        )
    }

    #[test]
    fun test_init() {
        let (
            mut scenario_val,
            app,
            app_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                app,
                app_registry_val
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun create() {
        let (
            mut scenario_val,
            mut app,
            app_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let fee: u64 = 1;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);
            
            let _royalties_address = fees::create_royalties<SUI>(
                &fee_cap,
                &mut app,
                fee,
                TREASURY,
                fee,
                TREASURY,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, fee_cap);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let royalties = ts::take_shared<Royalties>(scenario);

            let (
                royalties,
                app_address
            ) = fees::get_app_address_for_testing(royalties);
            let (
                royalties,
                custom_coin_type
            ) = fees::get_custom_coin_for_testing(royalties);
            let (
                royalties,
                partner_fee
            ) = fees::get_partner_fee_for_testing(royalties);
            let (
                royalties,
                partner_treasury
            ) = fees::get_partner_treasury_for_testing(royalties);
            let (
                royalties,
                protocol_fee
            ) = fees::get_protocol_fee_for_testing(royalties);
            let (
                royalties,
                protocol_treasury
            ) = fees::get_protocol_treasury_for_testing(royalties);

            assert!(app_address == app.get_address(), EAppAddressMismatch);
            assert!(custom_coin_type == type_name::get<SUI>(), ECustomCoinMismatch);
            assert!(partner_fee == fee, EFeeMismatch);
            assert!(partner_treasury == TREASURY, ETreasuryAddressMismatch);
            assert!(protocol_fee == fee, EFeeMismatch);
            assert!(protocol_treasury == TREASURY, ETreasuryAddressMismatch);

            ts::return_shared(royalties);

            destroy_for_testing(
                app,
                app_registry_val
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidFeeValue)]
    fun create_high_partner_fee() {
        let (
            mut scenario_val,
            mut app,
            app_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);
            
            let _royalties_address = fees::create_royalties<SUI>(
                &fee_cap,
                &mut app,
                9801,
                TREASURY,
                0,
                TREASURY,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, fee_cap);

            destroy_for_testing(
                app,
                app_registry_val
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidFeeValue)]
    fun create_high_protocol_fee() {
        let (
            mut scenario_val,
            mut app,
            app_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);
            
            let _royalties_address = fees::create_royalties<SUI>(
                &fee_cap,
                &mut app,
                0,
                TREASURY,
                9801,
                TREASURY,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, fee_cap);

            destroy_for_testing(
                app,
                app_registry_val
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidFeeValue)]
    fun create_out_of_bound_fees() {
        let (
            mut scenario_val,
            mut app,
            app_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);
            
            let _royalties_address = fees::create_royalties<SUI>(
                &fee_cap,
                &mut app,
                4900,
                TREASURY,
                4901,
                TREASURY,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, fee_cap);

            destroy_for_testing(
                app,
                app_registry_val
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun update() {
        let (
            mut scenario_val,
            mut app,
            app_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);
            
            let _royalties_address = fees::create_royalties<SUI>(
                &fee_cap,
                &mut app,
                0,
                TREASURY,
                0,
                TREASURY,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, fee_cap);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut royalties = ts::take_shared<Royalties>(scenario);

            let fee: u64 = 10;

            fees::update_royalties<FAKE_FEE_COIN>(
                &mut royalties,
                fee,
                ADMIN,
                fee,
                ADMIN
            );

            let (
                royalties,
                app_address
            ) = fees::get_app_address_for_testing(royalties);
            let (
                royalties,
                custom_coin_type
            ) = fees::get_custom_coin_for_testing(royalties);
            let (
                royalties,
                partner_fee
            ) = fees::get_partner_fee_for_testing(royalties);
            let (
                royalties,
                partner_treasury
            ) = fees::get_partner_treasury_for_testing(royalties);
            let (
                royalties,
                protocol_fee
            ) = fees::get_protocol_fee_for_testing(royalties);
            let (
                royalties,
                protocol_treasury
            ) = fees::get_protocol_treasury_for_testing(royalties);

            assert!(app_address == app.get_address(), EAppAddressMismatch);
            assert!(custom_coin_type == type_name::get<FAKE_FEE_COIN>(), ECustomCoinMismatch);
            assert!(partner_fee == fee, EFeeMismatch);
            assert!(partner_treasury == ADMIN, ETreasuryAddressMismatch);
            assert!(protocol_fee == fee, EFeeMismatch);
            assert!(protocol_treasury == ADMIN, ETreasuryAddressMismatch);

            ts::return_shared(royalties);

            destroy_for_testing(
                app,
                app_registry_val
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidFeeValue)]
    fun update_high_partner_fee() {
        let (
            mut scenario_val,
            mut app,
            app_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);
            
            let _royalties_address = fees::create_royalties<SUI>(
                &fee_cap,
                &mut app,
                0,
                TREASURY,
                0,
                TREASURY,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, fee_cap);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut royalties = ts::take_shared<Royalties>(scenario);

            fees::update_royalties<FAKE_FEE_COIN>(
                &mut royalties,
                9801,
                ADMIN,
                0,
                ADMIN
            );

            ts::return_shared(royalties);

            destroy_for_testing(
                app,
                app_registry_val
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidFeeValue)]
    fun update_high_protocol_fee() {
        let (
            mut scenario_val,
            mut app,
            app_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);
            
            let _royalties_address = fees::create_royalties<SUI>(
                &fee_cap,
                &mut app,
                0,
                TREASURY,
                0,
                TREASURY,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, fee_cap);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut royalties = ts::take_shared<Royalties>(scenario);

            fees::update_royalties<FAKE_FEE_COIN>(
                &mut royalties,
                0,
                ADMIN,
                9801,
                ADMIN
            );

            ts::return_shared(royalties);

            destroy_for_testing(
                app,
                app_registry_val
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidFeeValue)]
    fun update_out_of_bound_fees() {
        let (
            mut scenario_val,
            mut app,
            app_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let fee_cap = ts::take_from_sender<FeeCap>(scenario);
            
            let _royalties_address = fees::create_royalties<SUI>(
                &fee_cap,
                &mut app,
                0,
                TREASURY,
                0,
                TREASURY,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, fee_cap);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut royalties = ts::take_shared<Royalties>(scenario);

            fees::update_royalties<FAKE_FEE_COIN>(
                &mut royalties,
                4900,
                ADMIN,
                4901,
                ADMIN
            );

            ts::return_shared(royalties);

            destroy_for_testing(
                app,
                app_registry_val
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun collect_payment() {
        let (
            mut scenario_val,
            app,
            app_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        let amount = {
            let amount: u64 = 1;

            let custom_payment = mint_for_testing<FAKE_FEE_COIN>(
                amount,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                amount,
                ts::ctx(scenario)
            );

            fees::collect_payment<FAKE_FEE_COIN>(
                custom_payment,
                sui_payment
            );

            amount
        };

        ts::next_tx(scenario, ADMIN);
        {
            let custom_coin = ts::take_from_address<Coin<FAKE_FEE_COIN>>(
                scenario, 
                TREASURY
            );

            let balance = coin::value(&custom_coin);

            assert!(balance == amount, EIncorrectCustomBalance);

            let sui_coin = ts::take_from_address<Coin<SUI>>(
                scenario, 
                TREASURY
            );

            let balance = coin::value(&sui_coin);

            assert!(balance == amount, EIncorrectSuiBalance);

            burn_for_testing(custom_coin);
            burn_for_testing(sui_coin);

            destroy_for_testing(
                app,
                app_registry_val
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun distribute_payment_zero() {
        let (
            mut scenario_val,
            mut app,
            app_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let fee: u64 = 1000;
        let starting_amount: u64 = 0;

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<FAKE_FEE_COIN>(
                starting_amount,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                starting_amount,
                ts::ctx(scenario)
            );

            transfer::public_transfer(
                custom_payment,
                CONTENT_CREATOR
            );
            transfer::public_transfer(
                sui_payment,
                CONTENT_CREATOR
            );

            let custom_payment = mint_for_testing<FAKE_FEE_COIN>(
                starting_amount,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                starting_amount,
                ts::ctx(scenario)
            );

            transfer::public_transfer(
                custom_payment,
                PARTNER_TREASURY
            );
            transfer::public_transfer(
                sui_payment,
                PARTNER_TREASURY
            );

            let custom_payment = mint_for_testing<FAKE_FEE_COIN>(
                starting_amount,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                starting_amount,
                ts::ctx(scenario)
            );

            transfer::public_transfer(
                custom_payment,
                TREASURY
            );
            transfer::public_transfer(
                sui_payment,
                TREASURY
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let royalties = fees::create_for_testing<FAKE_FEE_COIN>(
                &mut app,
                0,
                PARTNER_TREASURY,
                0,
                TREASURY,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<FAKE_FEE_COIN>(
                fee,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                fee,
                ts::ctx(scenario)
            );

            fees::distribute_payment<FAKE_FEE_COIN>(
                &royalties,
                custom_payment,
                sui_payment,
                CONTENT_CREATOR,
                ts::ctx(scenario)
            );

            destroy(royalties);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let custom_coin = ts::take_from_address<Coin<FAKE_FEE_COIN>>(
                scenario, 
                TREASURY
            );

            let balance = coin::value(&custom_coin);

            assert!(balance == starting_amount, EIncorrectCustomBalance);

            let sui_coin = ts::take_from_address<Coin<SUI>>(
                scenario, 
                TREASURY
            );

            let balance = coin::value(&sui_coin);

            assert!(balance == fee, EIncorrectSuiBalance);

            burn_for_testing(custom_coin);
            burn_for_testing(sui_coin);

            let custom_coin = ts::take_from_address<Coin<FAKE_FEE_COIN>>(
                scenario, 
                PARTNER_TREASURY
            );

            let balance = coin::value(&custom_coin);

            assert!(balance == starting_amount, EIncorrectCustomBalance);

            let sui_coin = ts::take_from_address<Coin<SUI>>(
                scenario, 
                PARTNER_TREASURY
            );

            let balance = coin::value(&sui_coin);

            assert!(balance == starting_amount, EIncorrectSuiBalance);

            burn_for_testing(custom_coin);
            burn_for_testing(sui_coin);

            let custom_coin = ts::take_from_address<Coin<FAKE_FEE_COIN>>(
                scenario, 
                CONTENT_CREATOR
            );

            let balance = coin::value(&custom_coin);

            assert!(balance == fee, EIncorrectCustomBalance);

            let sui_coin = ts::take_from_address<Coin<SUI>>(
                scenario, 
                CONTENT_CREATOR
            );

            let balance = coin::value(&sui_coin);

            assert!(balance == starting_amount, EIncorrectSuiBalance);

            burn_for_testing(custom_coin);
            burn_for_testing(sui_coin);

            destroy_for_testing(
                app,
                app_registry_val
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun distribute_payment_partner_thirty() {
        let (
            mut scenario_val,
            mut app,
            app_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let fee: u64 = 1000;
        let starting_amount: u64 = 0;

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<FAKE_FEE_COIN>(
                starting_amount,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                starting_amount,
                ts::ctx(scenario)
            );

            transfer::public_transfer(
                custom_payment,
                CONTENT_CREATOR
            );
            transfer::public_transfer(
                sui_payment,
                CONTENT_CREATOR
            );

            let custom_payment = mint_for_testing<FAKE_FEE_COIN>(
                starting_amount,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                starting_amount,
                ts::ctx(scenario)
            );

            transfer::public_transfer(
                custom_payment,
                PARTNER_TREASURY
            );
            transfer::public_transfer(
                sui_payment,
                PARTNER_TREASURY
            );

            let custom_payment = mint_for_testing<FAKE_FEE_COIN>(
                starting_amount,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                starting_amount,
                ts::ctx(scenario)
            );

            transfer::public_transfer(
                custom_payment,
                TREASURY
            );
            transfer::public_transfer(
                sui_payment,
                TREASURY
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let royalties = fees::create_for_testing<FAKE_FEE_COIN>(
                &mut app,
                3000,
                PARTNER_TREASURY,
                0,
                TREASURY,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<FAKE_FEE_COIN>(
                fee,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                fee,
                ts::ctx(scenario)
            );

            fees::distribute_payment<FAKE_FEE_COIN>(
                &royalties,
                custom_payment,
                sui_payment,
                CONTENT_CREATOR,
                ts::ctx(scenario)
            );

            destroy(royalties);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let custom_coin = ts::take_from_address<Coin<FAKE_FEE_COIN>>(
                scenario, 
                TREASURY
            );

            let balance = coin::value(&custom_coin);

            assert!(balance == starting_amount, EIncorrectCustomBalance);

            let sui_coin = ts::take_from_address<Coin<SUI>>(
                scenario, 
                TREASURY
            );

            let balance = coin::value(&sui_coin);

            assert!(balance == fee, EIncorrectSuiBalance);

            burn_for_testing(custom_coin);
            burn_for_testing(sui_coin);

            let custom_coin = ts::take_from_address<Coin<FAKE_FEE_COIN>>(
                scenario, 
                PARTNER_TREASURY
            );

            let balance = coin::value(&custom_coin);

            assert!(balance == 300, EIncorrectCustomBalance);

            let sui_coin = ts::take_from_address<Coin<SUI>>(
                scenario, 
                PARTNER_TREASURY
            );

            let balance = coin::value(&sui_coin);

            assert!(balance == starting_amount, EIncorrectSuiBalance);

            burn_for_testing(custom_coin);
            burn_for_testing(sui_coin);

            let custom_coin = ts::take_from_address<Coin<FAKE_FEE_COIN>>(
                scenario, 
                CONTENT_CREATOR
            );

            let balance = coin::value(&custom_coin);

            assert!(balance == 700, EIncorrectCustomBalance);

            let sui_coin = ts::take_from_address<Coin<SUI>>(
                scenario, 
                CONTENT_CREATOR
            );

            let balance = coin::value(&sui_coin);

            assert!(balance == starting_amount, EIncorrectSuiBalance);

            burn_for_testing(custom_coin);
            burn_for_testing(sui_coin);

            destroy_for_testing(
                app,
                app_registry_val
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun distribute_payment_protocol_thirty() {
        let (
            mut scenario_val,
            mut app,
            app_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let fee: u64 = 1000;
        let starting_amount: u64 = 0;

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<FAKE_FEE_COIN>(
                starting_amount,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                starting_amount,
                ts::ctx(scenario)
            );

            transfer::public_transfer(
                custom_payment,
                CONTENT_CREATOR
            );
            transfer::public_transfer(
                sui_payment,
                CONTENT_CREATOR
            );

            let custom_payment = mint_for_testing<FAKE_FEE_COIN>(
                starting_amount,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                starting_amount,
                ts::ctx(scenario)
            );

            transfer::public_transfer(
                custom_payment,
                PARTNER_TREASURY
            );
            transfer::public_transfer(
                sui_payment,
                PARTNER_TREASURY
            );

            let custom_payment = mint_for_testing<FAKE_FEE_COIN>(
                starting_amount,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                starting_amount,
                ts::ctx(scenario)
            );

            transfer::public_transfer(
                custom_payment,
                TREASURY
            );
            transfer::public_transfer(
                sui_payment,
                TREASURY
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let royalties = fees::create_for_testing<FAKE_FEE_COIN>(
                &mut app,
                0,
                PARTNER_TREASURY,
                3000,
                TREASURY,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<FAKE_FEE_COIN>(
                fee,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                fee,
                ts::ctx(scenario)
            );

            fees::distribute_payment<FAKE_FEE_COIN>(
                &royalties,
                custom_payment,
                sui_payment,
                CONTENT_CREATOR,
                ts::ctx(scenario)
            );

            destroy(royalties);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let custom_coin = ts::take_from_address<Coin<FAKE_FEE_COIN>>(
                scenario, 
                TREASURY
            );

            let balance = coin::value(&custom_coin);

            assert!(balance == 300, EIncorrectCustomBalance);

            let sui_coin = ts::take_from_address<Coin<SUI>>(
                scenario, 
                TREASURY
            );

            let balance = coin::value(&sui_coin);

            assert!(balance == fee, EIncorrectSuiBalance);

            burn_for_testing(custom_coin);
            burn_for_testing(sui_coin);

            let custom_coin = ts::take_from_address<Coin<FAKE_FEE_COIN>>(
                scenario, 
                PARTNER_TREASURY
            );

            let balance = coin::value(&custom_coin);

            assert!(balance == starting_amount, EIncorrectCustomBalance);

            let sui_coin = ts::take_from_address<Coin<SUI>>(
                scenario, 
                PARTNER_TREASURY
            );

            let balance = coin::value(&sui_coin);

            assert!(balance == starting_amount, EIncorrectSuiBalance);

            burn_for_testing(custom_coin);
            burn_for_testing(sui_coin);

            let custom_coin = ts::take_from_address<Coin<FAKE_FEE_COIN>>(
                scenario, 
                CONTENT_CREATOR
            );

            let balance = coin::value(&custom_coin);

            assert!(balance == 700, EIncorrectCustomBalance);

            let sui_coin = ts::take_from_address<Coin<SUI>>(
                scenario, 
                CONTENT_CREATOR
            );

            let balance = coin::value(&sui_coin);

            assert!(balance == starting_amount, EIncorrectSuiBalance);

            burn_for_testing(custom_coin);
            burn_for_testing(sui_coin);

            destroy_for_testing(
                app,
                app_registry_val
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun distribute_payment_top_limit() {
        let (
            mut scenario_val,
            mut app,
            app_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let fee: u64 = 1000;
        let starting_amount: u64 = 0;

        ts::next_tx(scenario, ADMIN);
        {
            let custom_payment = mint_for_testing<FAKE_FEE_COIN>(
                starting_amount,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                starting_amount,
                ts::ctx(scenario)
            );

            transfer::public_transfer(
                custom_payment,
                CONTENT_CREATOR
            );
            transfer::public_transfer(
                sui_payment,
                CONTENT_CREATOR
            );

            let custom_payment = mint_for_testing<FAKE_FEE_COIN>(
                starting_amount,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                starting_amount,
                ts::ctx(scenario)
            );

            transfer::public_transfer(
                custom_payment,
                PARTNER_TREASURY
            );
            transfer::public_transfer(
                sui_payment,
                PARTNER_TREASURY
            );

            let custom_payment = mint_for_testing<FAKE_FEE_COIN>(
                starting_amount,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                starting_amount,
                ts::ctx(scenario)
            );

            transfer::public_transfer(
                custom_payment,
                TREASURY
            );
            transfer::public_transfer(
                sui_payment,
                TREASURY
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let royalties = fees::create_for_testing<FAKE_FEE_COIN>(
                &mut app,
                4900,
                PARTNER_TREASURY,
                4900,
                TREASURY,
                ts::ctx(scenario)
            );

            let custom_payment = mint_for_testing<FAKE_FEE_COIN>(
                fee,
                ts::ctx(scenario)
            );
            let sui_payment = mint_for_testing<SUI>(
                fee,
                ts::ctx(scenario)
            );

            fees::distribute_payment<FAKE_FEE_COIN>(
                &royalties,
                custom_payment,
                sui_payment,
                CONTENT_CREATOR,
                ts::ctx(scenario)
            );

            destroy(royalties);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let custom_coin = ts::take_from_address<Coin<FAKE_FEE_COIN>>(
                scenario, 
                TREASURY
            );

            let balance = coin::value(&custom_coin);

            assert!(balance == 490, EIncorrectCustomBalance);

            let sui_coin = ts::take_from_address<Coin<SUI>>(
                scenario, 
                TREASURY
            );

            let balance = coin::value(&sui_coin);

            assert!(balance == fee, EIncorrectSuiBalance);

            burn_for_testing(custom_coin);
            burn_for_testing(sui_coin);

            let custom_coin = ts::take_from_address<Coin<FAKE_FEE_COIN>>(
                scenario, 
                PARTNER_TREASURY
            );

            let balance = coin::value(&custom_coin);

            assert!(balance == 490, EIncorrectCustomBalance);

            let sui_coin = ts::take_from_address<Coin<SUI>>(
                scenario, 
                PARTNER_TREASURY
            );

            let balance = coin::value(&sui_coin);

            assert!(balance == starting_amount, EIncorrectSuiBalance);

            burn_for_testing(custom_coin);
            burn_for_testing(sui_coin);

            let custom_coin = ts::take_from_address<Coin<FAKE_FEE_COIN>>(
                scenario, 
                CONTENT_CREATOR
            );

            let balance = coin::value(&custom_coin);

            assert!(balance == 20, EIncorrectCustomBalance);

            let sui_coin = ts::take_from_address<Coin<SUI>>(
                scenario, 
                CONTENT_CREATOR
            );

            let balance = coin::value(&sui_coin);

            assert!(balance == starting_amount, EIncorrectSuiBalance);

            burn_for_testing(custom_coin);
            burn_for_testing(sui_coin);

            destroy_for_testing(
                app,
                app_registry_val
            );
        };

        ts::end(scenario_val);
    }
}
