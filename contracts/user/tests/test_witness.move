#[test_only]
module sage_user::test_user_witness {
    use sui::{
        test_scenario::{Self as ts}
    };

    use sage_user::{
        user_witness::{Self}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    // --------------- Test Functions ---------------

    #[test]
    fun test_user_witness() {
        let mut scenario_val = ts::begin(ADMIN);

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let _ = user_witness::create_witness();
        };

        ts::end(scenario_val);
    }
}
