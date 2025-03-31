#[test_only]
module sage_user::test_soul {
    use std::string::{utf8};

    use sui::{
        test_scenario::{Self as ts}
    };

    use sage_user::{
        soul::{
            Self,
            SageSoul
        }
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    const ENameMismatch: u64 = 0;

    // --------------- Test Functions ---------------

    #[test]
    fun test_soul_create() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        let name = utf8(b"user-name");

        ts::next_tx(scenario, ADMIN);
        {
            let _soul_address = soul::create(
                name,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let soul = ts::take_from_sender<SageSoul>(scenario);

            let retrieved_name = soul::get_name(&soul);

            assert!(name == retrieved_name, ENameMismatch);

            ts::return_to_sender(scenario, soul);
        };

        ts::end(scenario_val);
    }
}
