#[test_only]
module sage_channel::test_channel {
    use std::string::{utf8};

    use sui::test_scenario::{Self as ts};

    use sage_channel::{channel::{Self}};

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    const EChannelAvatarMismatch: u64 = 0;
    const EChannelBannerMismatch: u64 = 1;
    const EChannelDescriptionMismatch: u64 = 2;

    // --------------- Test Functions ---------------

    #[test]
    fun test_channel_create() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_name = utf8(b"channel-name");
            let created_at: u64 = 999;

            let _channel = channel::create(
                channel_name,
                channel_name,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                created_at,
                ADMIN
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_channel_update_avatar() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_name = utf8(b"channel-name");
            let created_at: u64 = 999;

            let avatar_hash = utf8(b"avatar_hash");

            let mut channel = channel::create(
                channel_name,
                channel_name,
                avatar_hash,
                utf8(b"banner_hash"),
                utf8(b"description"),
                created_at,
                ADMIN
            );

            let channel_avatar = channel::get_avatar(channel);

            assert!(channel_avatar == avatar_hash, EChannelAvatarMismatch);

            let new_channel_avatar = utf8(b"new_avatar_hash");
            let updated_at: u64 = 9999;

            channel::update_avatar(
                channel_name,
                &mut channel,
                new_channel_avatar,
                updated_at
            );

            let channel_avatar = channel::get_avatar(channel);

            assert!(channel_avatar == new_channel_avatar, EChannelAvatarMismatch);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_channel_update_banner() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_name = utf8(b"channel-name");
            let created_at: u64 = 999;

            let banner_hash = utf8(b"banner_hash");

            let mut channel = channel::create(
                channel_name,
                channel_name,
                utf8(b"avatar_hash"),
                banner_hash,
                utf8(b"description"),
                created_at,
                ADMIN
            );

            let channel_banner = channel::get_banner(channel);

            assert!(channel_banner == banner_hash, EChannelBannerMismatch);

            let new_channel_banner = utf8(b"new_banner_hash");
            let updated_at: u64 = 9999;

            channel::update_banner(
                channel_name,
                &mut channel,
                new_channel_banner,
                updated_at
            );

            let channel_banner = channel::get_banner(channel);

            assert!(channel_banner == new_channel_banner, EChannelBannerMismatch);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_channel_update_description() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_name = utf8(b"channel-name");
            let created_at: u64 = 999;

            let description = utf8(b"description");

            let mut channel = channel::create(
                channel_name,
                channel_name,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                description,
                created_at,
                ADMIN
            );

            let channel_description = channel::get_description(channel);

            assert!(channel_description == description, EChannelDescriptionMismatch);

            let new_channel_description = utf8(b"new_description");
            let updated_at: u64 = 9999;

            channel::update_description(
                channel_name,
                &mut channel,
                new_channel_description,
                updated_at
            );

            let channel_description = channel::get_description(channel);

            assert!(channel_description == new_channel_description, EChannelDescriptionMismatch);
        };

        ts::end(scenario_val);
    }
}
