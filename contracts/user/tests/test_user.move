#[test_only]
module sage_user::test_user {
    use std::string::{utf8};

    use sui::test_scenario::{Self as ts};

    use sage_user::{user::{Self}};

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    const EDescriptionInvalid: u64 = 0;
    const EUserAvatarMismatch: u64 = 0;
    const EUserBannerMismatch: u64 = 1;
    const EUserDescriptionMismatch: u64 = 2;
    const EUserNameMismatch: u64 = 3;

    // --------------- Test Functions ---------------

    #[test]
    fun test_user_create() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let created_at: u64 = 999;
            let invited_by = option::none();
            let name = utf8(b"name");

            let _user = user::create(
                ADMIN,
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                created_at,
                utf8(b"description"),
                invited_by,
                name,
                name
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
    fun test_user_update_avatar() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let created_at: u64 = 999;
            let invited_by = option::none();
            let user_name = utf8(b"user-name");

            let avatar_hash = utf8(b"avatar_hash");

            let mut user = user::create(
                ADMIN,
                avatar_hash,
                utf8(b"banner-hash"),
                created_at,
                utf8(b"description"),
                invited_by,
                user_name,
                user_name
            );

            let user_avatar = user::get_avatar(user);

            assert!(user_avatar == avatar_hash, EUserAvatarMismatch);

            let new_user_avatar = utf8(b"new_avatar_hash");
            let updated_at: u64 = 9999;

            let user = user::update_avatar(
                user_name,
                &mut user,
                new_user_avatar,
                updated_at
            );

            let user_avatar = user::get_avatar(user);

            assert!(user_avatar == new_user_avatar, EUserAvatarMismatch);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_update_banner() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let user_name = utf8(b"user-name");
            let created_at: u64 = 999;
            let invited_by = option::none();

            let banner_hash = utf8(b"banner_hash");

            let mut user = user::create(
                ADMIN,
                utf8(b"avatar-hash"),
                banner_hash,
                created_at,
                utf8(b"description"),
                invited_by,
                user_name,
                user_name
            );

            let user_banner = user::get_banner(user);

            assert!(user_banner == banner_hash, EUserBannerMismatch);

            let new_user_banner = utf8(b"new_banner_hash");
            let updated_at: u64 = 9999;

            let user = user::update_banner(
                user_name,
                &mut user,
                new_user_banner,
                updated_at
            );

            let user_banner = user::get_banner(user);

            assert!(user_banner == new_user_banner, EUserBannerMismatch);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_update_description() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let user_name = utf8(b"user-name");
            let created_at: u64 = 999;
            let invited_by = option::none();

            let description = utf8(b"description");

            let mut user = user::create(
                ADMIN,
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                created_at,
                description,
                invited_by,
                user_name,
                user_name
            );

            let user_description = user::get_description(user);

            assert!(user_description == description, EUserDescriptionMismatch);

            let new_user_description = utf8(b"new_description");
            let updated_at: u64 = 9999;

            let user = user::update_description(
                user_name,
                &mut user,
                new_user_description,
                updated_at
            );

            let user_description = user::get_description(user);

            assert!(user_description == new_user_description, EUserDescriptionMismatch);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_update_name() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let user_name = utf8(b"user-name");
            let created_at: u64 = 999;
            let invited_by = option::none();

            let mut user = user::create(
                ADMIN,
                utf8(b"avatar-hash"),
                utf8(b"banner-hash"),
                created_at,
                utf8(b"description"),
                invited_by,
                user_name,
                user_name
            );

            let retrieved_name = user::get_name(user);

            assert!(user_name == retrieved_name, EUserNameMismatch);

            let new_user_name = utf8(b"new-name");
            let updated_at: u64 = 9999;

            let user = user::update_name(
                user_name,
                &mut user,
                new_user_name,
                updated_at
            );

            let retrieved_name = user::get_name(user);

            assert!(retrieved_name == new_user_name, EUserNameMismatch);
        };

        ts::end(scenario_val);
    }
}
