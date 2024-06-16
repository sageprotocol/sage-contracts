#[test_only]
module sage::test_channel {
    // --------------- Constants ---------------
    const ADMIN: address = @0x111;

    #[test_only]
    public fun setup_for_testing<T, G: drop>(
        admin: address,
        initial_fund_amount: u64,
        max_risk: u64,
        player_rebate_rate: u64,
        referrer_rebate_rate: u64,
    ): Scenario {
        let scenario_val = ts::begin(admin);
        let scenario = &mut scenario_val;
        {
            init(ts::ctx(scenario));
        };

        ts::next_tx(scenario, admin);
        {
            let cap = ts::take_from_sender<AdminCap>(scenario);
            let unihouse = ts::take_shared<UniHouse>(scenario);

            let init_fund = coin::mint_for_testing<T>(initial_fund_amount, ts::ctx(scenario));
            create_house<T>(&cap, &mut unihouse, init_fund, ts::ctx(scenario));
            add_game_config<T, G>(
                &cap,
                &mut unihouse,
                max_risk,
                0,
                casuino_unihouse::math::max_u64(),
                player_rebate_rate,
                referrer_rebate_rate,
            );

            ts::return_to_sender(scenario, cap);
            ts::return_shared(unihouse);
        };

        scenario_val
    }

    #[test]
    fun test() {

    }
}
