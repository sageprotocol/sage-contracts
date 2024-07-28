#[test_only]
module sage_utils::test_string_helpers {
    use std::string::{utf8};

    use sui::test_scenario::{Self as ts};

    use sage_utils::{
        string_helpers::{Self}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    const EInvalidName: u64 = 0;
    const ELowercaseMismatch: u64 = 1;
    const EUppercaseMismatch: u64 = 2;

    // --------------- Test Functions ---------------

    #[test]
    fun test_user_name_validity() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"ab");

            let is_valid = string_helpers::is_valid_name(
                &name,
                2,
                15
            );

            assert!(is_valid == true, EInvalidName);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"ab");

            let is_valid = string_helpers::is_valid_name(
                &name,
                3,
                15
            );

            assert!(is_valid == false, EInvalidName);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"abcdefghijklmnop");

            let is_valid = string_helpers::is_valid_name(
                &name,
                3,
                15
            );

            assert!(is_valid == false, EInvalidName);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"abcdefghijklmno");

            let is_valid = string_helpers::is_valid_name(
                &name,
                3,
                15
            );

            assert!(is_valid == true, EInvalidName);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"abcdefghij-klmn");

            let is_valid = string_helpers::is_valid_name(
                &name,
                3,
                15
            );

            assert!(is_valid == true, EInvalidName);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"ab-");

            let is_valid = string_helpers::is_valid_name(
                &name,
                3,
                15
            );

            assert!(is_valid == false, EInvalidName);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"-ab");

            let is_valid = string_helpers::is_valid_name(
                &name,
                3,
                15
            );

            assert!(is_valid == false, EInvalidName);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"a_b");

            let is_valid = string_helpers::is_valid_name(
                &name,
                3,
                15
            );

            assert!(is_valid == false, EInvalidName);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"ab?");

            let is_valid = string_helpers::is_valid_name(
                &name,
                3,
                15
            );

            assert!(is_valid == false, EInvalidName);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"ab\"ab");

            let is_valid = string_helpers::is_valid_name(
                &name,
                3,
                15
            );

            assert!(is_valid == false, EInvalidName);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"ab123");

            let is_valid = string_helpers::is_valid_name(
                &name,
                3,
                15
            );

            assert!(is_valid == true, EInvalidName);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"987ab");

            let is_valid = string_helpers::is_valid_name(
                &name,
                3,
                15
            );

            assert!(is_valid == true, EInvalidName);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"987-AB");

            let is_valid = string_helpers::is_valid_name(
                &name,
                3,
                15
            );

            assert!(is_valid == true, EInvalidName);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"ABCDEFGHIJKLMNOP");

            let is_valid = string_helpers::is_valid_name(
                &name,
                3,
                15
            );

            assert!(is_valid == false, EInvalidName);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"ABCDEFGHIJKLMNO");

            let is_valid = string_helpers::is_valid_name(
                &name,
                3,
                15
            );

            assert!(is_valid == true, EInvalidName);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"ABCDEFGHIJKLMNOPqrstuvwxyz");

            let is_valid = string_helpers::is_valid_name(
                &name,
                3,
                26
            );

            assert!(is_valid == true, EInvalidName);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"ABCDEFGHIJKLMNOP-qrstuvwxyz");

            let is_valid = string_helpers::is_valid_name(
                &name,
                3,
                26
            );

            assert!(is_valid == false, EInvalidName);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_to_lowercase() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"abc");

            let lowercase = string_helpers::to_lowercase(&name);

            assert!(lowercase == utf8(b"abc"), ELowercaseMismatch);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"ABC");

            let lowercase = string_helpers::to_lowercase(&name);

            assert!(lowercase == utf8(b"abc"), ELowercaseMismatch);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"ABC-def");

            let lowercase = string_helpers::to_lowercase(&name);

            assert!(lowercase == utf8(b"abc-def"), ELowercaseMismatch);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_to_uppercase() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"abc");

            let uppercase = string_helpers::to_uppercase(&name);

            assert!(uppercase == utf8(b"ABC"), EUppercaseMismatch);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"ABC");

            let uppercase = string_helpers::to_uppercase(&name);

            assert!(uppercase == utf8(b"ABC"), EUppercaseMismatch);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"ABC-def");

            let uppercase = string_helpers::to_uppercase(&name);

            assert!(uppercase == utf8(b"ABC-DEF"), EUppercaseMismatch);
        };

        ts::end(scenario_val);
    }
}
