#[test_only]
module sage_shared::test_membership {
    use sui::{
        test_scenario::{Self as ts},
        test_utils::{destroy}
    };

    use sage_shared::{
        membership::{
            Self,
            EIsMember,
            EIsNotMember
        }
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;
    const SERVER: address = @server;

    // --------------- Errors ---------------

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

            let length = membership::get_member_length(&membership);

            assert!(length == 0);

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
            let timestamp: u64 = 333;

            let (
                retrieved_event,
                retrieved_message,
                retrieved_count
            ) = membership::object_join(
                &mut membership,
                SERVER,
                timestamp
            );

            assert!(retrieved_event == membership_event);
            assert!(retrieved_message == membership_message);
            assert!(retrieved_count == 1);

            let count = membership::get_count(
                &membership,
                SERVER
            );

            assert!(count == 1);

            let created_at = membership::get_created_at(
                &membership,
                SERVER
            );

            assert!(created_at == timestamp);

            let updated_at = membership::get_updated_at(
                &membership,
                SERVER
            );

            assert!(updated_at == timestamp);

            let is_member = membership::is_member(
                &membership,
                SERVER
            );

            assert!(is_member);

            let length = membership::get_member_length(&membership);

            assert!(length == 1);

            let retrieved_type = membership::get_type(
                &membership,
                SERVER
            );

            assert!(retrieved_type == membership_message);

            destroy(membership);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIsMember)]
    fun test_membership_object_join_fail() {
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
            let timestamp: u64 = 333;

            membership::object_join(
                &mut membership,
                SERVER,
                timestamp
            );

            membership::object_join(
                &mut membership,
                SERVER,
                timestamp
            );

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
            let created_at: u64 = 333;
            let updated_at: u64 = 999;

            membership::object_join(
                &mut membership,
                SERVER,
                created_at
            );

            let (
                retrieved_event,
                retrieved_message,
                retrieved_count
            ) = membership::object_leave(
                &mut membership,
                SERVER,
                updated_at
            );

            assert!(retrieved_event == membership_event);
            assert!(retrieved_message == membership_message);
            assert!(retrieved_count == 1);

            let retrieved_created_at = membership::get_created_at(
                &membership,
                SERVER
            );

            assert!(created_at == retrieved_created_at);

            let retrieved_updated_at = membership::get_updated_at(
                &membership,
                SERVER
            );

            assert!(updated_at == retrieved_updated_at);

            let is_member = membership::is_member(
                &membership,
                SERVER
            );

            assert!(!is_member);

            let length = membership::get_member_length(&membership);

            assert!(length == 0);

            destroy(membership);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIsNotMember)]
    fun test_membership_object_leave_fail() {
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
            let timestamp: u64 = 999;

            membership::object_join(
                &mut membership,
                SERVER,
                timestamp
            );

            membership::object_leave(
                &mut membership,
                SERVER,
                timestamp
            );

            membership::object_leave(
                &mut membership,
                SERVER,
                timestamp
            );

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
            let timestamp: u64 = 333;

            let (
                retrieved_event,
                retrieved_message,
                retrieved_count
            ) = membership::wallet_join(
                &mut membership,
                SERVER,
                timestamp
            );

            assert!(retrieved_event == membership_event);
            assert!(retrieved_message == membership_message);
            assert!(retrieved_count == 1);

            let count = membership::get_count(
                &membership,
                SERVER
            );

            assert!(count == 1);

            let created_at = membership::get_created_at(
                &membership,
                SERVER
            );

            assert!(created_at == timestamp);

            let updated_at = membership::get_updated_at(
                &membership,
                SERVER
            );

            assert!(updated_at == timestamp);

            let is_member = membership::is_member(
                &membership,
                SERVER
            );

            assert!(is_member);

            let length = membership::get_member_length(&membership);

            assert!(length == 1);

            let retrieved_type = membership::get_type(
                &membership,
                SERVER
            );

            assert!(retrieved_type == membership_message);

            destroy(membership);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIsMember)]
    fun test_membership_wallet_join_fail() {
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
            let timestamp: u64 = 333;

            membership::wallet_join(
                &mut membership,
                SERVER,
                timestamp
            );

            membership::wallet_join(
                &mut membership,
                SERVER,
                timestamp
            );

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
            let created_at: u64 = 333;
            let updated_at: u64 = 999;

            membership::wallet_join(
                &mut membership,
                SERVER,
                created_at
            );

            let (
                retrieved_event,
                retrieved_message,
                retrieved_count
            ) = membership::wallet_leave(
                &mut membership,
                SERVER,
                updated_at
            );

            assert!(retrieved_event == membership_event);
            assert!(retrieved_message == membership_message);
            assert!(retrieved_count == 1);

            let retrieved_created_at = membership::get_created_at(
                &membership,
                SERVER
            );

            assert!(created_at == retrieved_created_at);

            let retrieved_updated_at = membership::get_updated_at(
                &membership,
                SERVER
            );

            assert!(updated_at == retrieved_updated_at);

            let is_member = membership::is_member(
                &membership,
                SERVER
            );

            assert!(!is_member);

            let length = membership::get_member_length(&membership);

            assert!(length == 0);

            destroy(membership);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EIsNotMember)]
    fun test_membership_wallet_leave_fail() {
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
            let timestamp: u64 = 999;

            membership::wallet_join(
                &mut membership,
                SERVER,
                timestamp
            );

            membership::wallet_leave(
                &mut membership,
                SERVER,
                timestamp
            );

            membership::wallet_leave(
                &mut membership,
                SERVER,
                timestamp
            );

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
                SERVER,
                999
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

    #[test]
    fun test_membership_multiple_join() {
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
            let created_at: u64 = 333;

            let (_, _, retrieved_count) = membership::wallet_join(
                &mut membership,
                SERVER,
                created_at
            );

            assert!(retrieved_count == 1);

            membership::wallet_leave(
                &mut membership,
                SERVER,
                1
            );

            let (_, _, retrieved_count) = membership::wallet_join(
                &mut membership,
                SERVER,
                2
            );

            assert!(retrieved_count == 2);

            membership::wallet_leave(
                &mut membership,
                SERVER,
                3
            );

            let (_, _, retrieved_count) = membership::wallet_join(
                &mut membership,
                SERVER,
                4
            );

            assert!(retrieved_count == 3);

            let count = membership::get_count(
                &membership,
                SERVER
            );

            assert!(count == 3);

            let retrieved_created_at = membership::get_created_at(
                &membership,
                SERVER
            );

            assert!(created_at == retrieved_created_at);

            let retrieved_updated_at = membership::get_updated_at(
                &membership,
                SERVER
            );

            assert!(retrieved_updated_at == 4);

            let is_member = membership::is_member(
                &membership,
                SERVER
            );

            assert!(is_member);

            let length = membership::get_member_length(&membership);

            assert!(length == 1);

            destroy(membership);
        };

        ts::end(scenario_val);
    }
}
