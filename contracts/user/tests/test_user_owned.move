#[test_only]
module sage_user::test_user_owned {
    use std::string::{utf8};

    use sui::{
        test_scenario::{Self as ts},
        test_utils::{destroy}
    };

    use sage_admin::{
        apps::{Self}
    };

    use sage_user::{
        user_owned::{Self, UserOwned, ENoAppFavorites},
        user_shared::{Self, UserShared}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;
    const BOGUS: address = @0x0;
    const SERVER: address = @server;
    const SHARED: address = @0xCAFE;

    // --------------- Errors ---------------

    const EAvatarMismatch: u64 = 1;
    const EBannerMismatch: u64 = 2;
    const EDescriptionMismatch: u64 = 3;
    const EFavoritesLengthMismatch: u64 = 4;
    const EKeyMismatch: u64 = 5;
    const ENameMismatch: u64 = 6;
    const EOwnerMismatch: u64 = 7;
    const ESharedMismatch: u64 = 8;

    // --------------- Name Tag ---------------

    public struct FakeChannel has key {
        id: UID
    }

    // --------------- Test Functions ---------------

    #[test]
    fun test_owned_user_create() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let created_at: u64 = 999;
        let name = utf8(b"user-name");

        ts::next_tx(scenario, ADMIN);
        {
            let (
                owned_user,
                _user_address
            ) = user_owned::create(
                avatar,
                banner,
                created_at,
                description,
                name,
                name,
                ADMIN,
                ts::ctx(scenario)
            );

            let retrieved_avatar = user_owned::get_avatar(&owned_user);
            assert!(avatar == retrieved_avatar, EAvatarMismatch);

            let retrieved_banner = user_owned::get_banner(&owned_user);
            assert!(banner == retrieved_banner, EBannerMismatch);

            let retrieved_description = user_owned::get_description(&owned_user);
            assert!(description == retrieved_description, EDescriptionMismatch);

            let retrieved_key = user_owned::get_key(&owned_user);
            assert!(name == retrieved_key, EKeyMismatch);

            let retrieved_name = user_owned::get_name(&owned_user);
            assert!(name == retrieved_name, ENameMismatch);

            let retrieved_owner = user_owned::get_owner(&owned_user);
            assert!(ADMIN == retrieved_owner, EOwnerMismatch);

            let retrieved_shared_address = user_owned::get_shared_user(&owned_user);
            assert!(BOGUS == retrieved_shared_address, ESharedMismatch);

            destroy(owned_user);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_owned_user_update() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let created_at: u64 = 999;
        let name = utf8(b"user-name");

        ts::next_tx(scenario, ADMIN);
        {
            let (
                mut owned_user,
                _user_address
            ) = user_owned::create(
                avatar,
                banner,
                created_at,
                description,
                name,
                name,
                ADMIN,
                ts::ctx(scenario)
            );

            let new_user_avatar = utf8(b"new_avatar_hash");
            let new_user_banner = utf8(b"banner_hash");
            let new_user_description = utf8(b"new_description");
            let new_user_name = utf8(b"USER-name");
            let updated_at: u64 = 9999;

            user_owned::update(
                &mut owned_user,
                new_user_avatar,
                new_user_banner,
                new_user_description,
                new_user_name,
                updated_at
            );

            let retrieved_avatar = user_owned::get_avatar(&owned_user);
            assert!(new_user_avatar == retrieved_avatar, EAvatarMismatch);

            let retrieved_banner = user_owned::get_banner(&owned_user);
            assert!(new_user_banner == retrieved_banner, EBannerMismatch);

            let retrieved_description = user_owned::get_description(&owned_user);
            assert!(new_user_description == retrieved_description, EDescriptionMismatch);

            let retrieved_key = user_owned::get_key(&owned_user);
            assert!(name == retrieved_key, EKeyMismatch);

            let retrieved_name = user_owned::get_name(&owned_user);
            assert!(new_user_name == retrieved_name, ENameMismatch);

            destroy(owned_user);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_owned_user_set_shared() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let created_at: u64 = 999;
        let name = utf8(b"user-name");

        ts::next_tx(scenario, ADMIN);
        {
            let (
                owned_user,
                _user_address
            ) = user_owned::create(
                avatar,
                banner,
                created_at,
                description,
                name,
                name,
                ADMIN,
                ts::ctx(scenario)
            );

            let retrieved_shared_address = user_owned::get_shared_user(&owned_user);
            assert!(BOGUS == retrieved_shared_address, ESharedMismatch);

            user_owned::set_shared_user(
                owned_user,
                ADMIN,
                SHARED
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let owned_user = ts::take_from_sender<UserOwned>(scenario);

            let retrieved_shared_address = user_owned::get_shared_user(&owned_user);
            assert!(SHARED == retrieved_shared_address, ESharedMismatch);

            destroy(owned_user);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_owned_user_add_favorite_channel() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let created_at: u64 = 999;
        let name = utf8(b"user-name");

        ts::next_tx(scenario, ADMIN);
        {
            apps::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let (
            app,
            mut owned_user
        ) = {
            let (
                mut owned_user,
                _user_address
            ) = user_owned::create(
                avatar,
                banner,
                created_at,
                description,
                name,
                name,
                ADMIN,
                ts::ctx(scenario)
            );

            let app = apps::create_for_testing(
                utf8(b"sage"),
                ts::ctx(scenario)
            );

            let fake_channel = FakeChannel {
                id: ts::new_object(scenario)
            };

            user_owned::add_favorite_channel<FakeChannel>(
                &fake_channel,
                &mut owned_user,
                object::id_address(&app),
                1,
                ts::ctx(scenario)
            );

            let length = user_owned::get_channel_favorites_length(
                &app,
                &owned_user
            );

            assert!(length == 1, EFavoritesLengthMismatch);

            destroy(fake_channel);

            (
                app,
                owned_user
            )
        };

        ts::next_tx(scenario, ADMIN);
        {
            let fake_channel = FakeChannel {
                id: ts::new_object(scenario)
            };

            user_owned::add_favorite_channel<FakeChannel>(
                &fake_channel,
                &mut owned_user,
                object::id_address(&app),
                1,
                ts::ctx(scenario)
            );

            let length = user_owned::get_channel_favorites_length(
                &app,
                &owned_user
            );

            assert!(length == 2, EFavoritesLengthMismatch);

            destroy(app);
            destroy(fake_channel);
            destroy(owned_user);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_owned_user_add_to_total_rewards() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let created_at: u64 = 999;
        let name = utf8(b"user-name");

        ts::next_tx(scenario, ADMIN);
        {
            let (
                mut owned_user,
                _user_address
            ) = user_owned::create(
                avatar,
                banner,
                created_at,
                description,
                name,
                name,
                ADMIN,
                ts::ctx(scenario)
            );

            let mut running_total = 0;

            let total_rewards = owned_user.get_total_rewards();

            assert!(total_rewards == running_total);

            let amount = 5;
            running_total = running_total + amount;

            owned_user.add_to_total_rewards(amount);

            let total_rewards = owned_user.get_total_rewards();

            assert!(total_rewards == running_total);

            let amount = (1005 / 1000);
            running_total = running_total + amount;

            owned_user.add_to_total_rewards(amount);

            let total_rewards = owned_user.get_total_rewards();

            assert!(total_rewards == running_total);

            let amount = (105000 / 100000);
            running_total = running_total + amount;

            owned_user.add_to_total_rewards(amount);

            let total_rewards = owned_user.get_total_rewards();

            assert!(total_rewards == running_total);

            let amount = (1050000 / 1000000);
            running_total = running_total + amount;

            owned_user.add_to_total_rewards(amount);

            let total_rewards = owned_user.get_total_rewards();

            assert!(total_rewards == running_total);

            destroy(owned_user);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ENoAppFavorites)]
    fun test_owned_user_remove_favorite_channel_fail() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let created_at: u64 = 999;
        let name = utf8(b"user-name");

        ts::next_tx(scenario, ADMIN);
        {
            apps::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        {
            let (
                mut owned_user,
                _user_address
            ) = user_owned::create(
                avatar,
                banner,
                created_at,
                description,
                name,
                name,
                ADMIN,
                ts::ctx(scenario)
            );

            let app = apps::create_for_testing(
                utf8(b"sage"),
                ts::ctx(scenario)
            );

            let fake_channel = FakeChannel {
                id: ts::new_object(scenario)
            };

            user_owned::remove_favorite_channel<FakeChannel>(
                &fake_channel,
                &mut owned_user,
                object::id_address(&app),
                1,
                ts::ctx(scenario)
            );

            destroy(app);
            destroy(fake_channel);
            destroy(owned_user);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_owned_user_remove_favorite_channel_pass() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let created_at: u64 = 999;
        let name = utf8(b"user-name");

        ts::next_tx(scenario, ADMIN);
        {
            apps::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        {
            let (
                mut owned_user,
                _user_address
            ) = user_owned::create(
                avatar,
                banner,
                created_at,
                description,
                name,
                name,
                ADMIN,
                ts::ctx(scenario)
            );

            let app = apps::create_for_testing(
                utf8(b"sage"),
                ts::ctx(scenario)
            );

            let fake_channel = FakeChannel {
                id: ts::new_object(scenario)
            };

            user_owned::add_favorite_channel<FakeChannel>(
                &fake_channel,
                &mut owned_user,
                object::id_address(&app),
                1,
                ts::ctx(scenario)
            );

            user_owned::remove_favorite_channel<FakeChannel>(
                &fake_channel,
                &mut owned_user,
                object::id_address(&app),
                2,
                ts::ctx(scenario)
            );

            let length = user_owned::get_channel_favorites_length(
                &app,
                &owned_user
            );

            assert!(length == 0, EFavoritesLengthMismatch);

            destroy(app);
            destroy(fake_channel);
            destroy(owned_user);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_owned_user_add_favorite_user() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let created_at: u64 = 999;
        let name = utf8(b"user-name");

        ts::next_tx(scenario, ADMIN);
        {
            apps::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let (
            mut owned_user,
            user_address
         ) = {
            let (
                owned_user,
                user_address
            ) = user_owned::create(
                avatar,
                banner,
                created_at,
                description,
                name,
                name,
                ADMIN,
                ts::ctx(scenario)
            );

            let _shared_user_address = user_shared::create(
                created_at,
                name,
                user_address,
                ADMIN,
                ts::ctx(scenario)
            );

            (
                owned_user,
                user_address
            )
        };

        ts::next_tx(scenario, ADMIN);
        let app = {
            let app = apps::create_for_testing(
                utf8(b"sage"),
                ts::ctx(scenario)
            );

            let shared_user = ts::take_shared<UserShared>(scenario);

            user_owned::add_favorite_user(
                &mut owned_user,
                &shared_user,
                object::id_address(&app),
                1,
                ts::ctx(scenario)
            );

            let length = user_owned::get_user_favorites_length(
                &app,
                &owned_user
            );

            assert!(length == 1, EFavoritesLengthMismatch);

            ts::return_shared(shared_user);

            let _shared_user_address = user_shared::create(
                created_at,
                name,
                user_address,
                SERVER,
                ts::ctx(scenario)
            );

            app
        };

        ts::next_tx(scenario, ADMIN);
        {
            let shared_user = ts::take_shared<UserShared>(scenario);

            user_owned::add_favorite_user(
                &mut owned_user,
                &shared_user,
                object::id_address(&app),
                2,
                ts::ctx(scenario)
            );

            let length = user_owned::get_user_favorites_length(
                &app,
                &owned_user
            );

            assert!(length == 2, EFavoritesLengthMismatch);

            ts::return_shared(shared_user);

            destroy(app);
            destroy(owned_user);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ENoAppFavorites)]
    fun test_owned_user_remove_favorite_user_fail() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let created_at: u64 = 999;
        let name = utf8(b"user-name");

        ts::next_tx(scenario, ADMIN);
        {
            apps::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let mut owned_user = {
            let (
                owned_user,
                user_address
            ) = user_owned::create(
                avatar,
                banner,
                created_at,
                description,
                name,
                name,
                ADMIN,
                ts::ctx(scenario)
            );

            let _shared_user_address = user_shared::create(
                created_at,
                name,
                user_address,
                ADMIN,
                ts::ctx(scenario)
            );

            owned_user
        };

        ts::next_tx(scenario, ADMIN);
        {
            let app = apps::create_for_testing(
                utf8(b"sage"),
                ts::ctx(scenario)
            );

            let shared_user = ts::take_shared<UserShared>(scenario);

            user_owned::remove_favorite_user(
                &mut owned_user,
                &shared_user,
                object::id_address(&app),
                1,
                ts::ctx(scenario)
            );

            let length = user_owned::get_user_favorites_length(
                &app,
                &owned_user
            );

            assert!(length == 0, EFavoritesLengthMismatch);

            ts::return_shared(shared_user);

            destroy(app);
            destroy(owned_user);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_owned_user_remove_favorite_user_pass() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        let avatar = utf8(b"avatar");
        let banner = utf8(b"banner");
        let description = utf8(b"description");
        let created_at: u64 = 999;
        let name = utf8(b"user-name");

        ts::next_tx(scenario, ADMIN);
        {
            apps::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let mut owned_user = {
            let (
                owned_user,
                user_address
            ) = user_owned::create(
                avatar,
                banner,
                created_at,
                description,
                name,
                name,
                ADMIN,
                ts::ctx(scenario)
            );

            let _shared_user_address = user_shared::create(
                created_at,
                name,
                user_address,
                ADMIN,
                ts::ctx(scenario)
            );

            owned_user
        };

        ts::next_tx(scenario, ADMIN);
        let app = {
            let app = apps::create_for_testing(
                utf8(b"sage"),
                ts::ctx(scenario)
            );

            let shared_user = ts::take_shared<UserShared>(scenario);

            user_owned::add_favorite_user(
                &mut owned_user,
                &shared_user,
                object::id_address(&app),
                1,
                ts::ctx(scenario)
            );

            ts::return_shared(shared_user);

            app
        };

        ts::next_tx(scenario, ADMIN);
        {
            let shared_user = ts::take_shared<UserShared>(scenario);

            user_owned::remove_favorite_user(
                &mut owned_user,
                &shared_user,
                object::id_address(&app),
                2,
                ts::ctx(scenario)
            );

            let length = user_owned::get_user_favorites_length(
                &app,
                &owned_user
            );

            assert!(length == 0, EFavoritesLengthMismatch);

            ts::return_shared(shared_user);

            destroy(app);
            destroy(owned_user);
        };

        ts::end(scenario_val);
    }
}
