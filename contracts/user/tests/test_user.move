#[test_only]
module sage_user::test_user {
    use std::string::{utf8};

    use sui::test_scenario::{Self as ts};

    use sage_shared::{
        membership::{Self},
        posts::{Self}
    };

    use sage_user::{
        user::{
            Self,
            User,
            EInvalidUserDescription,
            EInvalidUsername
        }
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;
    const SOUL: address = @0xBABE;

    // --------------- Errors ---------------

    const EDescriptionInvalid: u64 = 0;
    const EUserAvatarMismatch: u64 = 1;
    const EUserBannerMismatch: u64 = 2;
    const EUserDescriptionMismatch: u64 = 3;
    const EUserKeyMismatch: u64 = 4;
    const EUserOwnerMismatch: u64 = 5;
    const EUserNameMismatch: u64 = 6;

    // --------------- Test Functions ---------------

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
    fun test_user_create() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        let avatar_hash = utf8(b"avatar-hash");
        let banner_hash = utf8(b"banner-hash");
        let created_at: u64 = 999;
        let description = utf8(b"description");
        let key = utf8(b"user-name");
        let name = utf8(b"USER-name");

        ts::next_tx(scenario, ADMIN);
        {
            let follows = membership::create(ts::ctx(scenario));
            let posts = posts::create(ts::ctx(scenario));

            let _user_address = user::create(
                avatar_hash,
                banner_hash,
                created_at,
                description,
                follows,
                key,
                ADMIN,
                name,
                posts,
                SOUL,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let user = ts::take_shared<User>(scenario);

            let retrieved_avatar = user::get_avatar(&user);
            assert!(retrieved_avatar == avatar_hash, EUserAvatarMismatch);

            let retrieved_banner = user::get_banner(&user);
            assert!(retrieved_banner == banner_hash, EUserBannerMismatch);

            let retrieved_description = user::get_description(&user);
            assert!(retrieved_description == description, EUserDescriptionMismatch);

            let retrieved_owner = user::get_owner(&user);
            assert!(retrieved_owner == ADMIN, EUserOwnerMismatch);

            let retrieved_key = user::get_key(&user);
            assert!(retrieved_key == utf8(b"user-name"), EUserKeyMismatch);

            let retrieved_name = user::get_name(&user);
            assert!(retrieved_name == name, EUserNameMismatch);

            ts::return_shared(user);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidUserDescription)]
    fun test_user_create_description_fail() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        let avatar_hash = utf8(b"avatar-hash");
        let banner_hash = utf8(b"banner-hash");
        let created_at: u64 = 999;
        let description = utf8(b"abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefg");
        let name = utf8(b"user-name");

        ts::next_tx(scenario, ADMIN);
        {
            let follows = membership::create(ts::ctx(scenario));
            let posts = posts::create(ts::ctx(scenario));

            let _user_address = user::create(
                avatar_hash,
                banner_hash,
                created_at,
                description,
                follows,
                name,
                ADMIN,
                name,
                posts,
                SOUL,
                ts::ctx(scenario)
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidUsername)]
    fun test_user_create_name_fail() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        let avatar_hash = utf8(b"avatar-hash");
        let banner_hash = utf8(b"banner-hash");
        let created_at: u64 = 999;
        let description = utf8(b"description");
        let name = utf8(b"abcdefghijklmnopqrstuvwxyz");

        ts::next_tx(scenario, ADMIN);
        {
            let follows = membership::create(ts::ctx(scenario));
            let posts = posts::create(ts::ctx(scenario));

            let _user_address = user::create(
                avatar_hash,
                banner_hash,
                created_at,
                description,
                follows,
                name,
                ADMIN,
                name,
                posts,
                SOUL,
                ts::ctx(scenario)
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_borrow_follows() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        let avatar_hash = utf8(b"avatar-hash");
        let banner_hash = utf8(b"banner-hash");
        let created_at: u64 = 999;
        let description = utf8(b"description");
        let key = utf8(b"user-name");
        let name = utf8(b"USER-name");

        ts::next_tx(scenario, ADMIN);
        {
            let follows = membership::create(ts::ctx(scenario));
            let posts = posts::create(ts::ctx(scenario));

            let _user_address = user::create(
                avatar_hash,
                banner_hash,
                created_at,
                description,
                follows,
                key,
                ADMIN,
                name,
                posts,
                SOUL,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut user = ts::take_shared<User>(scenario);

            let _follows = user::borrow_follows_mut(&mut user);

            ts::return_shared(user);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_borrow_posts() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        let avatar_hash = utf8(b"avatar-hash");
        let banner_hash = utf8(b"banner-hash");
        let created_at: u64 = 999;
        let description = utf8(b"description");
        let name = utf8(b"USER-name");
        let key = utf8(b"user-name");

        ts::next_tx(scenario, ADMIN);
        {
            let follows = membership::create(ts::ctx(scenario));
            let posts = posts::create(ts::ctx(scenario));

            let _user_address = user::create(
                avatar_hash,
                banner_hash,
                created_at,
                description,
                follows,
                key,
                ADMIN,
                name,
                posts,
                SOUL,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut user = ts::take_shared<User>(scenario);

            let _posts = user::borrow_posts_mut(&mut user);

            ts::return_shared(user);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_update() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        let avatar_hash = utf8(b"avatar-hash");
        let banner_hash = utf8(b"banner-hash");
        let description = utf8(b"description");
        let created_at: u64 = 999;
        let name = utf8(b"user-name");

        ts::next_tx(scenario, ADMIN);
        {
            let follows = membership::create(ts::ctx(scenario));
            let posts = posts::create(ts::ctx(scenario));

            let _user_address = user::create(
                avatar_hash,
                banner_hash,
                created_at,
                description,
                follows,
                name,
                ADMIN,
                name,
                posts,
                SOUL,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut user = ts::take_shared<User>(
                scenario
            );

            let new_user_avatar = utf8(b"new_avatar_hash");
            let new_user_banner = utf8(b"banner_hash");
            let new_user_description = utf8(b"new_description");
            let new_user_name = utf8(b"USER-name");
            let updated_at: u64 = 9999;

            user::update(
                &mut user,
                new_user_avatar,
                new_user_banner,
                new_user_description,
                new_user_name,
                updated_at
            );

            let retrieved_avatar = user::get_avatar(&user);
            assert!(retrieved_avatar == new_user_avatar, EUserAvatarMismatch);

            let retrieved_banner = user::get_banner(&user);
            assert!(retrieved_banner == new_user_banner, EUserBannerMismatch);

            let retrieved_description = user::get_description(&user);
            assert!(retrieved_description == new_user_description, EUserDescriptionMismatch);

            let retrieved_key = user::get_key(&user);
            assert!(retrieved_key == utf8(b"user-name"), EUserKeyMismatch);

            let retrieved_name = user::get_name(&user);
            assert!(retrieved_name == new_user_name, EUserNameMismatch);

            ts::return_shared(user);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidUserDescription)]
    fun test_user_update_fail() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        let avatar_hash = utf8(b"avatar-hash");
        let banner_hash = utf8(b"banner-hash");
        let description = utf8(b"description");
        let created_at: u64 = 999;
        let name = utf8(b"user-name");

        ts::next_tx(scenario, ADMIN);
        {
            let follows = membership::create(ts::ctx(scenario));
            let posts = posts::create(ts::ctx(scenario));

            let _user_address = user::create(
                avatar_hash,
                banner_hash,
                created_at,
                description,
                follows,
                name,
                ADMIN,
                name,
                posts,
                SOUL,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut user = ts::take_shared<User>(
                scenario
            );

            let new_user_avatar = utf8(b"new_avatar_hash");
            let new_user_banner = utf8(b"banner_hash");
            let new_user_description = utf8(b"abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefg");
            let new_user_name = utf8(b"USER-name");
            let updated_at: u64 = 9999;

            user::update(
                &mut user,
                new_user_avatar,
                new_user_banner,
                new_user_description,
                new_user_name,
                updated_at
            );

            ts::return_shared(user);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_assert_description_pass() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let description = utf8(b"description");

            user::assert_user_description(&description);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidUserDescription)]
    fun test_user_assert_description_fail() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let description = utf8(b"abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefg");

            user::assert_user_description(&description);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_assert_name_pass() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"name");

            user::assert_user_name(&name);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidUsername)]
    fun test_user_assert_name_fail() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"abcdefghijklmnopqrstuvwxyz");

            user::assert_user_name(&name);
        };

        ts::end(scenario_val);
    }
}
