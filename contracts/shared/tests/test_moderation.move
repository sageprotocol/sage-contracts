#[test_only]
module sage_shared::test_moderation {
    use sui::{
        test_scenario::{Self as ts},
        test_utils::{destroy}
    };

    use sage_shared::{
        moderation::{
            Self,
            EIsOwner,
            EIsNotModerator,
            EIsNotOwner
        }
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;
    const SERVER: address = @server;

    // --------------- Errors ---------------

    const ELengthMismatch: u64 = 0;
    const EModerationRecord: u64 = 1;
    const EModerationMismatch: u64 = 2;
    const ENoModerationRecord: u64 = 3;

    // --------------- Test Functions ---------------

    #[test]
    fun test_moderation_create() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let moderation_event: u8 = 10;
            let moderation_message: u8 = 0;

            let (moderation, retrieved_event, retrieved_message) = moderation::create(
                ts::ctx(scenario)
            );

            assert!(retrieved_event == moderation_event, EModerationMismatch);
            assert!(retrieved_message == moderation_message, EModerationMismatch);

            let is_owner = moderation::is_owner(
                &moderation,
                ADMIN
            );

            assert!(is_owner, ENoModerationRecord);

            let length = moderation::get_length(&moderation);

            assert!(length == 1, ELengthMismatch);

            destroy(moderation);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_moderation_add_moderator() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        let mut moderation = {
            let (moderation, _, _) = moderation::create(
                ts::ctx(scenario)
            );

            moderation
        };

        ts::next_tx(scenario, SERVER);
        {
            let moderation_event: u8 = 10;
            let moderation_message: u8 = 1;

            let (retrieved_event, retrieved_message) = moderation::make_moderator(
                &mut moderation,
                SERVER
            );

            assert!(retrieved_event == moderation_event, EModerationMismatch);
            assert!(retrieved_message == moderation_message, EModerationMismatch);

            let is_moderator = moderation::is_moderator(
                &moderation,
                SERVER
            );

            assert!(is_moderator, ENoModerationRecord);

            let is_owner = moderation::is_owner(
                &moderation,
                SERVER
            );

            assert!(!is_owner, ENoModerationRecord);

            let length = moderation::get_length(&moderation);

            assert!(length == 2, ELengthMismatch);

            destroy(moderation);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_moderation_remove_moderator() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        let mut moderation = {
            let (moderation, _, _) = moderation::create(
                ts::ctx(scenario)
            );

            moderation
        };

        ts::next_tx(scenario, SERVER);
        {
            let moderation_event: u8 = 11;
            let moderation_message: u8 = 1;

            moderation::make_moderator(
                &mut moderation,
                SERVER
            );

            let (retrieved_event, retrieved_message) = moderation::remove_moderator(
                &mut moderation,
                SERVER
            );

            assert!(retrieved_event == moderation_event, EModerationMismatch);
            assert!(retrieved_message == moderation_message, EModerationMismatch);

            let is_moderator = moderation::is_moderator(
                &moderation,
                SERVER
            );

            assert!(!is_moderator, EModerationRecord);

            let length = moderation::get_length(&moderation);

            assert!(length == 1, ELengthMismatch);

            destroy(moderation);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_moderation_add_owner() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        let mut moderation = {
            let (moderation, _, _) = moderation::create(
                ts::ctx(scenario)
            );

            moderation
        };

        ts::next_tx(scenario, SERVER);
        {
            let moderation_event: u8 = 10;
            let moderation_message: u8 = 0;

            let (retrieved_event, retrieved_message) = moderation::make_owner(
                &mut moderation,
                SERVER
            );

            assert!(retrieved_event == moderation_event, EModerationMismatch);
            assert!(retrieved_message == moderation_message, EModerationMismatch);

            let is_moderator = moderation::is_moderator(
                &moderation,
                SERVER
            );

            assert!(is_moderator, ENoModerationRecord);

            let is_owner = moderation::is_owner(
                &moderation,
                SERVER
            );

            assert!(is_owner, ENoModerationRecord);

            let length = moderation::get_length(&moderation);

            assert!(length == 2, ELengthMismatch);

            destroy(moderation);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIsOwner)]
    fun test_moderation_remove_owner() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        let mut moderation = {
            let (moderation, _, _) = moderation::create(
                ts::ctx(scenario)
            );

            moderation
        };

        ts::next_tx(scenario, SERVER);
        {
            moderation::make_owner(
                &mut moderation,
                SERVER
            );

            moderation::remove_moderator(
                &mut moderation,
                SERVER
            );

            destroy(moderation);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_moderation_assert_moderator_pass() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        let mut moderation = {
            let (moderation, _, _) = moderation::create(
                ts::ctx(scenario)
            );

            moderation
        };

        ts::next_tx(scenario, SERVER);
        {
            moderation::make_moderator(
                &mut moderation,
                SERVER
            );

            moderation::assert_is_moderator(
                &moderation,
                SERVER
            );

            destroy(moderation);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIsNotModerator)]
    fun test_moderation_assert_moderator_fail() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let (moderation, _, _) = moderation::create(
                ts::ctx(scenario)
            );

            moderation::assert_is_moderator(
                &moderation,
                SERVER
            );

            destroy(moderation);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_moderation_assert_owner_pass() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        let mut moderation = {
            let (moderation, _, _) = moderation::create(
                ts::ctx(scenario)
            );

            moderation
        };

        ts::next_tx(scenario, SERVER);
        {
            moderation::make_owner(
                &mut moderation,
                SERVER
            );

            moderation::assert_is_owner(
                &moderation,
                SERVER
            );

            destroy(moderation);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIsNotOwner)]
    fun test_moderation_assert_owner_fail() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let (mut moderation, _, _) = moderation::create(
                ts::ctx(scenario)
            );

            moderation::make_moderator(
                &mut moderation,
                SERVER
            );

            moderation::assert_is_owner(
                &moderation,
                SERVER
            );

            destroy(moderation);
        };

        ts::end(scenario_val);
    }
}
