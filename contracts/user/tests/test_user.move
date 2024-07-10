#[test_only]
module sage_user::test_user {
    use std::string::{utf8};

    use sui::test_scenario::{Self as ts};

    use sage_user::{user::{Self}};

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    const EDescriptionInvalid: u64 = 0;
    const EUsernameInvalid: u64 = 1;

    // --------------- Test Functions ---------------

    #[test]
    fun test_user_create() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let created_at: u64 = 999;

            let _user = user::create(
                ADMIN,
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                created_at,
                utf8(b"description"),
                utf8(b"name")
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_description_validity() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let description = utf8(b"ab");

            let is_valid = user::is_valid_description_for_testing(&description);

            assert!(is_valid == true, EDescriptionInvalid);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let description = utf8(b"abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefg");

            let is_valid = user::is_valid_description_for_testing(&description);

            assert!(is_valid == false, EDescriptionInvalid);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_name_validity() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"ab");

            let is_valid = user::is_valid_username_for_testing(&name);

            assert!(is_valid == false, EUsernameInvalid);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"abcdefghijklmnop");

            let is_valid = user::is_valid_username_for_testing(&name);

            assert!(is_valid == false, EUsernameInvalid);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"abcdefghijklmno");

            let is_valid = user::is_valid_username_for_testing(&name);

            assert!(is_valid == true, EUsernameInvalid);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"abcdefghij-klmn");

            let is_valid = user::is_valid_username_for_testing(&name);

            assert!(is_valid == true, EUsernameInvalid);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"ab-");

            let is_valid = user::is_valid_username_for_testing(&name);

            assert!(is_valid == false, EUsernameInvalid);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"-ab");

            let is_valid = user::is_valid_username_for_testing(&name);

            assert!(is_valid == false, EUsernameInvalid);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"a_b");

            let is_valid = user::is_valid_username_for_testing(&name);

            assert!(is_valid == false, EUsernameInvalid);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"ab?");

            let is_valid = user::is_valid_username_for_testing(&name);

            assert!(is_valid == false, EUsernameInvalid);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"ab\"ab");

            let is_valid = user::is_valid_username_for_testing(&name);

            assert!(is_valid == false, EUsernameInvalid);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"ab123");

            let is_valid = user::is_valid_username_for_testing(&name);

            assert!(is_valid == true, EUsernameInvalid);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"987ab");

            let is_valid = user::is_valid_username_for_testing(&name);

            assert!(is_valid == true, EUsernameInvalid);
        };

        ts::end(scenario_val);
    }
}
