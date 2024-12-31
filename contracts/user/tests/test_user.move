#[test_only]
module sage_user::test_user {
    use std::string::{utf8};

    use sui::test_scenario::{Self as ts};

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

    // --------------- Errors ---------------

    const EDescriptionInvalid: u64 = 0;
    const EUserAvatarMismatch: u64 = 1;
    const EUserBannerMismatch: u64 = 2;
    const EUserDescriptionMismatch: u64 = 3;
    const EUserOwnerMismatch: u64 = 4;
    const EUserNameMismatch: u64 = 5;

    // --------------- Test Functions ---------------

    #[test]
    fun test_user_create() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let created_at: u64 = 999;
            let name = utf8(b"name");

            let _user_address = user::create(
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                created_at,
                utf8(b"description"),
                ADMIN,
                name,
                ts::ctx(scenario)
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidUserDescription)]
    fun test_user_create_description_length() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let created_at: u64 = 999;
            let description = utf8(b"abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefg");

            let _user_address = user::create(
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                created_at,
                description,
                ADMIN,
                utf8(b"name"),
                ts::ctx(scenario)
            );
        };

        ts::end(scenario_val);
    }
    
    #[test]
    #[expected_failure(abort_code = EInvalidUsername)]
    fun test_user_create_name_special() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let created_at: u64 = 999;
            let name = utf8(b"nam*e");

            let _user_address = user::create(
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                created_at,
                utf8(b"description"),
                ADMIN,
                name,
                ts::ctx(scenario)
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidUsername)]
    fun test_user_create_name_dash() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let created_at: u64 = 999;
            let name = utf8(b"name-");

            let _user_address = user::create(
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                created_at,
                utf8(b"description"),
                ADMIN,
                name,
                ts::ctx(scenario)
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidUsername)]
    fun test_user_create_name_max_length() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let created_at: u64 = 999;
            let name = utf8(b"abcdefghijklmnop");

            let _user_address = user::create(
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                created_at,
                utf8(b"description"),
                ADMIN,
                name,
                ts::ctx(scenario)
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidUsername)]
    fun test_user_create_name_min_length() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let created_at: u64 = 999;
            let name = utf8(b"ab");

            let _user_address = user::create(
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                created_at,
                utf8(b"description"),
                ADMIN,
                name,
                ts::ctx(scenario)
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_description_valid() {
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
    fun test_user_update() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        let (
            avatar_hash,
            banner_hash,
            description,
            user_name
        ) = {
            let avatar_hash = utf8(b"avatar-hash");
            let banner_hash = utf8(b"banner-hash");
            let description = utf8(b"description");
            let user_name = utf8(b"user-name");

            let created_at: u64 = 999;

            let _user_address = user::create(
                avatar_hash,
                banner_hash,
                created_at,
                description,
                ADMIN,
                user_name,
                ts::ctx(scenario)
            );

            (
                avatar_hash,
                banner_hash,
                description,
                user_name
            )
        };

        ts::next_tx(scenario, ADMIN);
        {
            let user = ts::take_from_sender<User>(
                scenario
            );

            let user_request = user::create_user_request(user);

            let (retrieved_owner, user_request) = user::get_owner(user_request);
            let (retrieved_avatar, user_request) = user::get_avatar(user_request);
            let (retrieved_banner, user_request) = user::get_banner(user_request);
            let (retrieved_description, user_request) = user::get_description(user_request);
            let (retrieved_name, user_request) = user::get_name(user_request);

            assert!(retrieved_owner == ADMIN, EUserOwnerMismatch);
            assert!(retrieved_avatar == avatar_hash, EUserAvatarMismatch);
            assert!(retrieved_banner == banner_hash, EUserBannerMismatch);
            assert!(retrieved_description == description, EUserDescriptionMismatch);
            assert!(retrieved_name == user_name, EUserNameMismatch);

            let new_user_avatar = utf8(b"new_avatar_hash");
            let new_user_banner = utf8(b"banner_hash");
            let new_user_description = utf8(b"new_description");
            let new_user_name = utf8(b"new-name");
            let updated_at: u64 = 999;

            let user_request = user::update(
                user_request,
                new_user_avatar,
                new_user_banner,
                new_user_description,
                new_user_name,
                updated_at
            );

            let (retrieved_avatar, user_request) = user::get_avatar(user_request);
            let (retrieved_banner, user_request) = user::get_banner(user_request);
            let (retrieved_description, user_request) = user::get_description(user_request);
            let (retrieved_name, user_request) = user::get_name(user_request);

            assert!(retrieved_avatar == new_user_avatar, EUserAvatarMismatch);
            assert!(retrieved_banner == new_user_banner, EUserBannerMismatch);
            assert!(retrieved_description == new_user_description, EUserDescriptionMismatch);
            assert!(retrieved_name == new_user_name, EUserNameMismatch);

            user::destroy_user_request(user_request, ADMIN);
        };

        ts::end(scenario_val);
    }
}
