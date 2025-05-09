#[test_only]
module sage_channel::test_channel_witness {
    use sui::{
        test_scenario::{Self as ts}
    };

    use sage_channel::{
        channel_witness::{Self}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    // --------------- Test Functions ---------------

    #[test]
    fun test_channel_witness() {
        let mut scenario_val = ts::begin(ADMIN);

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let _ = channel_witness::create_witness();
        };

        ts::end(scenario_val);
    }
}
