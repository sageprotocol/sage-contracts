#[test_only]
module sage_user::test_user_shared {
    use std::string::{utf8};

    use sui::{
        test_scenario::{Self as ts}
    };

    use sage_user::{
        user_shared::{
            Self,
            UserShared
        }
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;
    const USER_OWNED: address = @0xBABE;

    // --------------- Errors ---------------

    const EPostsMismatch: u64 = 0;
    const EUserKeyMismatch: u64 = 1;
    const EUserOwnerMismatch: u64 = 2;

    // --------------- Test Functions ---------------

    #[test]
    fun test_user_create() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        let created_at: u64 = 999;
        let key = utf8(b"user-name");

        ts::next_tx(scenario, ADMIN);
        {
            let _user_address = user_shared::create(
                created_at,
                key,
                USER_OWNED,
                ADMIN,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let shared_user = ts::take_shared<UserShared>(scenario);

            let retrieved_key = user_shared::get_key(&shared_user);
            assert!(retrieved_key == utf8(b"user-name"), EUserKeyMismatch);

            let retrieved_owner = user_shared::get_owner(&shared_user);
            assert!(retrieved_owner == ADMIN, EUserOwnerMismatch);

            let retrieved_owned_user = user_shared::get_owned_user(&shared_user);
            assert!(retrieved_owned_user == USER_OWNED, EUserOwnerMismatch);

            ts::return_shared(shared_user);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_borrow_follows() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        let created_at: u64 = 999;
        let key = utf8(b"user-name");

        ts::next_tx(scenario, ADMIN);
        {
            let _user_address = user_shared::create(
                created_at,
                key,
                USER_OWNED,
                ADMIN,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut user = ts::take_shared<UserShared>(scenario);

            let _follows = user_shared::borrow_follows_mut(
                &mut user,
                ADMIN,
                ts::ctx(scenario)
            );

            ts::return_shared(user);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_friend_requests() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        let created_at: u64 = 999;
        let key = utf8(b"user-name");

        ts::next_tx(scenario, ADMIN);
        {
            let _user_address = user_shared::create(
                created_at,
                key,
                USER_OWNED,
                ADMIN,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut user = ts::take_shared<UserShared>(scenario);

            let _friend_requests = user_shared::borrow_friend_requests_mut(
                &mut user,
                ADMIN,
                ts::ctx(scenario)
            );

            ts::return_shared(user);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_friends() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        let created_at: u64 = 999;
        let key = utf8(b"user-name");

        ts::next_tx(scenario, ADMIN);
        {
            let _user_address = user_shared::create(
                created_at,
                key,
                USER_OWNED,
                ADMIN,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut user = ts::take_shared<UserShared>(scenario);

            let _friends = user_shared::borrow_friends_mut(
                &mut user,
                ADMIN,
                ts::ctx(scenario)
            );

            ts::return_shared(user);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_posts() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        let created_at: u64 = 999;
        let key = utf8(b"user-name");

        ts::next_tx(scenario, ADMIN);
        {
            let _user_address = user_shared::create(
                created_at,
                key,
                USER_OWNED,
                ADMIN,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut user = ts::take_shared<UserShared>(scenario);

            let posts = user_shared::take_posts(
                &mut user,
                ADMIN,
                ts::ctx(scenario)
            );

            user_shared::return_posts(
                &mut user,
                ADMIN,
                posts
            );

            let does_exist = user_shared::posts_exists(
                &user,
                ADMIN
            );

            assert!(does_exist, EPostsMismatch);

            ts::return_shared(user);
        };

        ts::end(scenario_val);
    }
}
