#[test_only]
module sage_shared::test_membership {
    use sui::{
        test_scenario::{Self as ts},
        test_utils::{destroy}
    };

    use sage_shared::{
        membership::{Self, EIsNotMember}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;
    const SERVER: address = @server;

    // --------------- Errors ---------------

    const ELengthMismatch: u64 = 0;
    const EMembershipRecord: u64 = 1;
    const EMembershipMismatch: u64 = 2;
    const ENoMembershipRecord: u64 = 3;

    // --------------- Test Functions ---------------

    #[test]
    fun test_membership_create() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let membership = membership::create(
                ts::ctx(scenario)
            );

            let length = membership::get_length(&membership);

            assert!(length == 0, ELengthMismatch);

            destroy(membership);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_membership_object_join() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        let mut membership = {
            let membership = membership::create(
                ts::ctx(scenario)
            );

            membership
        };

        ts::next_tx(scenario, SERVER);
        {
            let membership_event: u8 = 10;
            let membership_message: u8 = 1;

            let (retrieved_event, retrieved_message) = membership::object_join(
                &mut membership,
                SERVER
            );

            assert!(retrieved_event == membership_event, EMembershipMismatch);
            assert!(retrieved_message == membership_message, EMembershipMismatch);

            let is_member = membership::is_member(
                &membership,
                SERVER
            );

            assert!(is_member, ENoMembershipRecord);

            let length = membership::get_length(&membership);

            assert!(length == 1, ELengthMismatch);

            let retrieved_type = membership::get_type(
                &membership,
                SERVER
            );

            assert!(retrieved_type == membership_message, EMembershipMismatch);

            destroy(membership);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_membership_object_leave() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        let mut membership = {
            let membership = membership::create(
                ts::ctx(scenario)
            );

            membership
        };

        ts::next_tx(scenario, SERVER);
        {
            let membership_event: u8 = 11;
            let membership_message: u8 = 1;

            membership::object_join(
                &mut membership,
                SERVER
            );

            let (retrieved_event, retrieved_message) = membership::object_leave(
                &mut membership,
                SERVER
            );

            assert!(retrieved_event == membership_event, EMembershipMismatch);
            assert!(retrieved_message == membership_message, EMembershipMismatch);

            let is_member = membership::is_member(
                &membership,
                SERVER
            );

            assert!(!is_member, EMembershipRecord);

            let length = membership::get_length(&membership);

            assert!(length == 0, ELengthMismatch);

            destroy(membership);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_membership_wallet_join() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        let mut membership = {
            let membership = membership::create(
                ts::ctx(scenario)
            );

            membership
        };

        ts::next_tx(scenario, SERVER);
        {
            let membership_event: u8 = 10;
            let membership_message: u8 = 0;

            let (retrieved_event, retrieved_message) = membership::wallet_join(
                &mut membership,
                SERVER
            );

            assert!(retrieved_event == membership_event, EMembershipMismatch);
            assert!(retrieved_message == membership_message, EMembershipMismatch);

            let is_member = membership::is_member(
                &membership,
                SERVER
            );

            assert!(is_member, ENoMembershipRecord);

            let length = membership::get_length(&membership);

            assert!(length == 1, ELengthMismatch);

            let retrieved_type = membership::get_type(
                &membership,
                SERVER
            );

            assert!(retrieved_type == membership_message, EMembershipMismatch);

            destroy(membership);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_membership_wallet_leave() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        let mut membership = {
            let membership = membership::create(
                ts::ctx(scenario)
            );

            membership
        };

        ts::next_tx(scenario, SERVER);
        {
            let membership_event: u8 = 11;
            let membership_message: u8 = 0;

            membership::wallet_join(
                &mut membership,
                SERVER
            );

            let (retrieved_event, retrieved_message) = membership::wallet_leave(
                &mut membership,
                SERVER
            );

            assert!(retrieved_event == membership_event, EMembershipMismatch);
            assert!(retrieved_message == membership_message, EMembershipMismatch);

            let is_member = membership::is_member(
                &membership,
                SERVER
            );

            assert!(!is_member, EMembershipRecord);

            let length = membership::get_length(&membership);

            assert!(length == 0, ELengthMismatch);

            destroy(membership);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_membership_assert_pass() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        let mut membership = {
            let membership = membership::create(
                ts::ctx(scenario)
            );

            membership
        };

        ts::next_tx(scenario, SERVER);
        {
            membership::wallet_join(
                &mut membership,
                SERVER
            );

            membership::assert_is_member(
                &membership,
                SERVER
            );

            destroy(membership);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIsNotMember)]
    fun test_membership_assert_fail() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let membership = membership::create(
                ts::ctx(scenario)
            );

            membership::assert_is_member(
                &membership,
                SERVER
            );

            destroy(membership);
        };

        ts::end(scenario_val);
    }
}
