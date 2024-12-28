#[test_only]
module sage_channel::test_channel {
    use std::string::{utf8};

    use sui::test_scenario::{Self as ts};

    use sage_channel::{
        channel::{
            Self,
            Channel,
            EInvalidChannelDescription,
            EInvalidChannelName
        }
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    const EChannelAddressMismatch: u64 = 0;
    const EChannelAvatarMismatch: u64 = 1;
    const EChannelBannerMismatch: u64 = 2;
    const EChannelCreatedByMismatch: u64 = 3;
    const EChannelDescriptionMismatch: u64 = 4;
    const EChannelNameMismatch: u64 = 5;
    const EDescriptionInvalid: u64 = 6;

    // --------------- Test Functions ---------------

    #[test]
    fun description_validity() {
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
    fun create() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        let avatar_hash = utf8(b"avatar_hash");
        let banner_hash = utf8(b"banner_hash");
        let channel_name = utf8(b"channel-name");
        let description = utf8(b"description");

        ts::next_tx(scenario, ADMIN);
        let channel_address = {    
            let created_at: u64 = 999;

            channel::create(
                channel_name,
                avatar_hash,
                banner_hash,
                description,
                created_at,
                ADMIN,
                ts::ctx(scenario)
            )
        };

        ts::next_tx(scenario, ADMIN);
        {
            let channel = ts::take_shared<Channel>(
                scenario
            );

            let retrieved_address = channel.get_address();

            assert!(channel_address == retrieved_address, EChannelAddressMismatch);

            let retrieved_avatar = channel.get_avatar();

            assert!(avatar_hash == retrieved_avatar, EChannelAvatarMismatch);

            let retrieved_banner = channel.get_banner();

            assert!(banner_hash == retrieved_banner, EChannelBannerMismatch);

            let retrieved_created_by = channel.get_created_by();

            assert!(ADMIN == retrieved_created_by, EChannelCreatedByMismatch);

            let retrieved_description = channel.get_description();

            assert!(description == retrieved_description, EChannelDescriptionMismatch);

            let retrieved_name = channel.get_name();

            assert!(channel_name == retrieved_name, EChannelNameMismatch);

            ts::return_shared(channel);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun create_max_description_length() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let avatar_hash = utf8(b"avatar_hash");
            let banner_hash = utf8(b"banner_hash");
            let channel_name = utf8(b"channel-name");
            let description = utf8(b"ndqtjjyxtxzygwdzbydcavjgkukdkxmbdvftqhwrbgjbivddwlaxzxeeskyfzbakkamyakrgygxxlpidmvfovrjoembdnpeulakjcoqvfxpbgahtpzzieddtowlysatwhssegixlwmjuesvhzavbhvixpypdjpzwusoonhwoqhnlghvnjxnxfbfglrbuleajyveozsiipocbkfezdaukwyfdrwabjzndziklllsymshbfezfucdthrfdrrsmkbsannvxelpkqwsjifmawptgamsxbdukpnlyzezexcogvtviqpvvyfbtzdnartbqhcqnofchsdidorqyornafkaxkjhbsprfamdxkmeaxnkxbswtyviakz");

            let created_at: u64 = 999;

            channel::create(
                channel_name,
                avatar_hash,
                banner_hash,
                description,
                created_at,
                ADMIN,
                ts::ctx(scenario)
            )
        };

        ts::end(scenario_val);
    }

    #[test]
    fun create_max_name_length() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let avatar_hash = utf8(b"avatar_hash");
            let banner_hash = utf8(b"banner_hash");
            let channel_name = utf8(b"channel-name-abcdefg");
            let description = utf8(b"description");

            let created_at: u64 = 999;

            channel::create(
                channel_name,
                avatar_hash,
                banner_hash,
                description,
                created_at,
                ADMIN,
                ts::ctx(scenario)
            )
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidChannelDescription)]
    fun create_description_fail() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let avatar_hash = utf8(b"avatar_hash");
            let banner_hash = utf8(b"banner_hash");
            let channel_name = utf8(b"channel-name");
            let description = utf8(b"ndqtjjyxtxzygwdzbydcavjgkukdkxmbdvftqhwrbgjbivddwlaxzxeeskyfzbakkamyakrgygxxlpidmvfovrjoembdnpeulakjcoqvfxpbgahtpzzieddtowlysatwhssegixlwmjuesvhzavbhvixpypdjpzwusoonhwoqhnlghvnjxnxfbfglrbuleajyveozsiipocbkfezdaukwyfdrwabjzndziklllsymshbfezfucdthrfdrrsmkbsannvxelpkqwsjifmawptgamsxbdukpnlyzezexcogvtviqpvvyfbtzdnartbqhcqnofchsdidorqyornafkaxkjhbsprfamdxkmeaxnkxbswtyviakzm");
            let created_at: u64 = 999;

            let _channel_address = channel::create(
                channel_name,
                avatar_hash,
                banner_hash,
                description,
                created_at,
                ADMIN,
                ts::ctx(scenario)
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidChannelName)]
    fun create_name_fail_characters() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let avatar_hash = utf8(b"avatar_hash");
            let banner_hash = utf8(b"banner_hash");
            let channel_name = utf8(b"channel=name");
            let description = utf8(b"description");
            let created_at: u64 = 999;

            let _channel_address = channel::create(
                channel_name,
                avatar_hash,
                banner_hash,
                description,
                created_at,
                ADMIN,
                ts::ctx(scenario)
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidChannelName)]
    fun create_name_fail_short() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let avatar_hash = utf8(b"avatar_hash");
            let banner_hash = utf8(b"banner_hash");
            let channel_name = utf8(b"ch");
            let description = utf8(b"description");
            let created_at: u64 = 999;

            let _channel_address = channel::create(
                channel_name,
                avatar_hash,
                banner_hash,
                description,
                created_at,
                ADMIN,
                ts::ctx(scenario)
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidChannelName)]
    fun create_name_fail_long() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let avatar_hash = utf8(b"avatar_hash");
            let banner_hash = utf8(b"banner_hash");
            let channel_name = utf8(b"channel-name-channelz");
            let description = utf8(b"description");
            let created_at: u64 = 999;

            let _channel_address = channel::create(
                channel_name,
                avatar_hash,
                banner_hash,
                description,
                created_at,
                ADMIN,
                ts::ctx(scenario)
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun update() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let channel_name = utf8(b"channel-name");
            let created_at: u64 = 999;

            let _channel_address = channel::create(
                channel_name,
                utf8(b"avatar_hash"),
                utf8(b"banner_hash"),
                utf8(b"description"),
                created_at,
                ADMIN,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut channel = ts::take_shared<Channel>(
                scenario
            );

            let new_avatar_hash = utf8(b"new_avatar_hash");
            let new_banner_hash = utf8(b"new_banner_hash");
            let new_channel_name = utf8(b"CHANNEL-name");
            let new_description = utf8(b"new_description");

            let updated_at: u64 = 9999;

            channel::update(
                &mut channel,
                new_channel_name,
                new_avatar_hash,
                new_banner_hash,
                new_description,
                updated_at
            );

            let retrieved_avatar = channel.get_avatar();

            assert!(new_avatar_hash == retrieved_avatar, EChannelAvatarMismatch);

            let retrieved_banner = channel.get_banner();

            assert!(new_banner_hash == retrieved_banner, EChannelBannerMismatch);

            let retrieved_description = channel.get_description();

            assert!(new_description == retrieved_description, EChannelDescriptionMismatch);

            let retrieved_name = channel.get_name();

            assert!(new_channel_name == retrieved_name, EChannelNameMismatch);

            ts::return_shared(channel);
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidChannelDescription)]
    fun update_description_fail() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        let avatar_hash = utf8(b"avatar_hash");
        let banner_hash = utf8(b"banner_hash");
        let channel_name = utf8(b"channel-name");

        ts::next_tx(scenario, ADMIN);
        {
            
            let description = utf8(b"description");
            let created_at: u64 = 999;

            let _channel_address = channel::create(
                channel_name,
                avatar_hash,
                banner_hash,
                description,
                created_at,
                ADMIN,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, ADMIN);
        {
            let mut channel = ts::take_shared<Channel>(
                scenario
            );

            let new_description = utf8(b"ndqtjjyxtxzygwdzbydcavjgkukdkxmbdvftqhwrbgjbivddwlaxzxeeskyfzbakkamyakrgygxxlpidmvfovrjoembdnpeulakjcoqvfxpbgahtpzzieddtowlysatwhssegixlwmjuesvhzavbhvixpypdjpzwusoonhwoqhnlghvnjxnxfbfglrbuleajyveozsiipocbkfezdaukwyfdrwabjzndziklllsymshbfezfucdthrfdrrsmkbsannvxelpkqwsjifmawptgamsxbdukpnlyzezexcogvtviqpvvyfbtzdnartbqhcqnofchsdidorqyornafkaxkjhbsprfamdxkmeaxnkxbswtyviakzm");

            channel::update(
                &mut channel,
                channel_name,
                avatar_hash,
                banner_hash,
                new_description,
                9999
            );

            ts::return_shared(channel);
        };

        ts::end(scenario_val);
    }
}
