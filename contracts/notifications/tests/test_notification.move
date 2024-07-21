 #[test_only]
module sage_notification::test_notification {
    use std::string::{utf8};

    use sui::test_scenario::{Self as ts};

    use sage_notification::{
        notification::{Self}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    // --------------- Test Functions ---------------

    #[test]
    fun test_notification() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let reward_amount: u64 = 1000;
            let timestamp: u64 = 999;

            let _notification = notification::create(
                timestamp,
                utf8(b"message"),
                reward_amount
            );
        };

        ts::end(scenario_val);
    }
}
