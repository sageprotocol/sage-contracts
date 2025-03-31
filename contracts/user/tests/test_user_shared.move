#[test_only]
module sage_user::test_user_shared {
    use std::string::{utf8};

    use sui::{
        test_scenario::{Self as ts}
    };

    use sage_shared::{
        membership::{Self},
        posts::{Self}
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

    const EUserKeyMismatch: u64 = 5;
    const EUserOwnerMismatch: u64 = 6;

    // --------------- Test Functions ---------------

    #[test]
    fun test_user_create() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        let created_at: u64 = 999;
        let key = utf8(b"user-name");

        ts::next_tx(scenario, ADMIN);
        {
            let follows = membership::create(ts::ctx(scenario));
            let posts = posts::create(ts::ctx(scenario));

            let _user_address = user_shared::create(
                created_at,
                follows,
                key,
                USER_OWNED,
                ADMIN,
                posts,
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
            let follows = membership::create(ts::ctx(scenario));
            let posts = posts::create(ts::ctx(scenario));

            let _user_address = user_shared::create(
                created_at,
                follows,
                key,
                USER_OWNED,
                ADMIN,
                posts,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut user = ts::take_shared<UserShared>(scenario);

            let _follows = user_shared::borrow_follows_mut(&mut user);

            ts::return_shared(user);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_borrow_posts() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        let created_at: u64 = 999;
        let key = utf8(b"user-name");

        ts::next_tx(scenario, ADMIN);
        {
            let follows = membership::create(ts::ctx(scenario));
            let posts = posts::create(ts::ctx(scenario));

            let _user_address = user_shared::create(
                created_at,
                follows,
                key,
                USER_OWNED,
                ADMIN,
                posts,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut user = ts::take_shared<UserShared>(scenario);

            let _posts = user_shared::borrow_posts_mut(&mut user);

            ts::return_shared(user);
        };

        ts::end(scenario_val);
    }
}
