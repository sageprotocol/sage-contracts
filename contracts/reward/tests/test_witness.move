#[test_only]
module sage_reward::test_reward_witness {
    use sui::{
        test_scenario::{Self as ts}
    };

    use sage_reward::{
        reward_witness::{Self}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    // --------------- Test Functions ---------------

    #[test]
    fun test_reward_witness() {
        let mut scenario_val = ts::begin(ADMIN);

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let _ = reward_witness::create_witness();
        };

        ts::end(scenario_val);
    }
}
