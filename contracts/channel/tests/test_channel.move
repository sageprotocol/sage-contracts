#[test_only]
module sage_channel::test_channel {
    use std::string::{utf8};

    use sui::{
        test_scenario::{Self as ts},
        test_utils::{destroy}
    };

    use sage_channel::{
        channel::{
            Self,
            Channel,
            EInvalidChannelDescription,
            EInvalidChannelName
        }
    };

    use sage_shared::{
        membership::{Self},
        moderation::{Self},
        posts::{Self}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    const EChannelAuthorMismatch: u64 = 0;
    const EChannelAvatarMismatch: u64 = 1;
    const EChannelBannerMismatch: u64 = 2;
    const EChannelDescriptionMismatch: u64 = 3;
    const EChannelKeyMismatch: u64 = 4;
    const EChannelNameMismatch: u64 = 5;
    const EDescriptionInvalid: u64 = 6;

    // --------------- Test Functions ---------------

    #[test]
    fun channel_description_validity() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let description = utf8(b"ab");

            let is_valid = channel::is_valid_description_for_testing(&description);

            assert!(is_valid == true, EDescriptionInvalid);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let description = utf8(b"abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefg");

            let is_valid = channel::is_valid_description_for_testing(&description);

            assert!(is_valid == false, EDescriptionInvalid);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun channel_create() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_name = utf8(b"channel-name");
            let created_at: u64 = 999;

            let follows = membership::create(ts::ctx(scenario));
            let (moderators, _, _) = moderation::create(ts::ctx(scenario));
            let posts = posts::create(ts::ctx(scenario));

            let _channel = channel::create(
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                created_at,
                ADMIN,
                follows,
                channel_name,
                moderators,
                channel_name,
                posts,
                ts::ctx(scenario)
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun channel_borrow_follows() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let avatar_hash = utf8(b"avatar_hash");
            let channel_name = utf8(b"channel-name");
            let created_at: u64 = 999;

            let follows = membership::create(ts::ctx(scenario));
            let (moderators, _, _) = moderation::create(ts::ctx(scenario));
            let posts = posts::create(ts::ctx(scenario));

            let _channel_address = channel::create(
                avatar_hash,
                utf8(b"banner_hash"),
                utf8(b"description"),
                created_at,
                ADMIN,
                follows,
                channel_name,
                moderators,
                channel_name,
                posts,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut channel= ts::take_shared<Channel>(scenario);

            let _follows = channel::borrow_follows_mut(&mut channel);

            destroy(channel);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun channel_borrow_moderators() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let avatar_hash = utf8(b"avatar_hash");
            let channel_name = utf8(b"channel-name");
            let created_at: u64 = 999;

            let follows = membership::create(ts::ctx(scenario));
            let (moderators, _, _) = moderation::create(ts::ctx(scenario));
            let posts = posts::create(ts::ctx(scenario));

            let _channel_address = channel::create(
                avatar_hash,
                utf8(b"banner_hash"),
                utf8(b"description"),
                created_at,
                ADMIN,
                follows,
                channel_name,
                moderators,
                channel_name,
                posts,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut channel= ts::take_shared<Channel>(scenario);

            let _moderators = channel::borrow_moderators_mut(&mut channel);

            destroy(channel);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun channel_borrow_posts() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let avatar_hash = utf8(b"avatar_hash");
            let channel_name = utf8(b"channel-name");
            let created_at: u64 = 999;

            let follows = membership::create(ts::ctx(scenario));
            let (moderators, _, _) = moderation::create(ts::ctx(scenario));
            let posts = posts::create(ts::ctx(scenario));

            let _channel_address = channel::create(
                avatar_hash,
                utf8(b"banner_hash"),
                utf8(b"description"),
                created_at,
                ADMIN,
                follows,
                channel_name,
                moderators,
                channel_name,
                posts,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut channel= ts::take_shared<Channel>(scenario);

            let _posts = channel::borrow_posts_mut(&mut channel);

            destroy(channel);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun channel_update() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        let channel_name = {
            let avatar_hash = utf8(b"avatar_hash");
            let channel_name = utf8(b"channel-name");
            let created_at: u64 = 999;

            let follows = membership::create(ts::ctx(scenario));
            let (moderators, _, _) = moderation::create(ts::ctx(scenario));
            let posts = posts::create(ts::ctx(scenario));

            let _channel_address = channel::create(
                avatar_hash,
                utf8(b"banner_hash"),
                utf8(b"description"),
                created_at,
                ADMIN,
                follows,
                channel_name,
                moderators,
                channel_name,
                posts,
                ts::ctx(scenario)
            );

            channel_name
        };

        ts::next_tx(scenario, ADMIN);
        {
            let new_channel_avatar = utf8(b"new_avatar_hash");
            let new_channel_banner = utf8(b"new_banner_hash");
            let new_channel_description = utf8(b"new_description");
            let new_channel_name = utf8(b"NEW-name");

            let updated_at: u64 = 9999;

            let mut channel= ts::take_shared<Channel>(scenario);

            channel::update(
                &mut channel,
                new_channel_avatar,
                new_channel_banner,
                new_channel_description,
                new_channel_name,
                updated_at
            );

            let channel_author = channel::get_created_by(&channel);
            assert!(channel_author == ADMIN, EChannelAuthorMismatch);

            let channel_avatar = channel::get_avatar(&channel);
            assert!(channel_avatar == new_channel_avatar, EChannelAvatarMismatch);

            let channel_banner = channel::get_banner(&channel);
            assert!(channel_banner == new_channel_banner, EChannelBannerMismatch);

            let channel_description = channel::get_description(&channel);
            assert!(channel_description == new_channel_description, EChannelDescriptionMismatch);

            let channel_key = channel::get_key(&channel);
            assert!(channel_key == channel_name, EChannelKeyMismatch);

            let channel_name = channel::get_name(&channel);
            assert!(channel_name == new_channel_name, EChannelNameMismatch);

            destroy(channel);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun channel_assert_description_pass() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let description = utf8(b"description");

            channel::assert_channel_description(&description);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidChannelDescription)]
    fun channel_assert_description_fail() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let description = utf8(b"abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefg");

            channel::assert_channel_description(&description);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun channel_assert_name_pass() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"name");

            channel::assert_channel_name(&name);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidChannelName)]
    fun channel_assert_name_fail() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let name = utf8(b"name-");

            channel::assert_channel_name(&name);
        };

        ts::end(scenario_val);
    }
}
