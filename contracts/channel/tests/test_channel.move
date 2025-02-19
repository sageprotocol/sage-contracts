// #[test_only]
// module sage_channel::test_channel {
//     use std::string::{utf8};

//     use sui::test_scenario::{Self as ts};

//     use sage_channel::{channel::{Self}};

//     // --------------- Constants ---------------

//     const ADMIN: address = @admin;

//     // --------------- Errors ---------------

//     const EChannelAvatarMismatch: u64 = 0;
//     const EChannelBannerMismatch: u64 = 1;
//     const EChannelDescriptionMismatch: u64 = 2;
//     const EChannelNameMismatch: u64 = 3;
//     const EDescriptionInvalid: u64 = 4;

//     // --------------- Test Functions ---------------

//     #[test]
//     fun description_validity() {
//         let mut scenario_val = ts::begin(ADMIN);
//         let scenario = &mut scenario_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let description = utf8(b"ab");

//             let is_valid = channel::is_valid_description_for_testing(&description);

//             assert!(is_valid == true, EDescriptionInvalid);
//         };

//         ts::next_tx(scenario, ADMIN);
//         {
//             let description = utf8(b"abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefg");

//             let is_valid = channel::is_valid_description_for_testing(&description);

//             assert!(is_valid == false, EDescriptionInvalid);
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     fun create() {
//         let mut scenario_val = ts::begin(ADMIN);
//         let scenario = &mut scenario_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let channel_name = utf8(b"channel-name");
//             let created_at: u64 = 999;

//             let _channel = channel::create(
//                 channel_name,
//                 channel_name,
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 created_at,
//                 ADMIN
//             );
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     fun update() {
//         let mut scenario_val = ts::begin(ADMIN);
//         let scenario = &mut scenario_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let channel_name = utf8(b"channel-name");
//             let created_at: u64 = 999;

//             let avatar_hash = utf8(b"avatar_hash");

//             let mut channel = channel::create(
//                 channel_name,
//                 channel_name,
//                 avatar_hash,
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 created_at,
//                 ADMIN
//             );

//             let new_channel_avatar = utf8(b"new_avatar_hash");
//             let new_channel_banner = utf8(b"new_banner_hash");
//             let new_channel_description = utf8(b"new_description");
//             let new_channel_name = utf8(b"new-name");

//             let updated_at: u64 = 9999;

//             channel::update(
//                 &mut channel,
//                 channel_name,
//                 new_channel_name,
//                 new_channel_avatar,
//                 new_channel_banner,
//                 new_channel_description,
//                 updated_at
//             );

//             let channel_avatar = channel::get_avatar(channel);
//             assert!(channel_avatar == new_channel_avatar, EChannelAvatarMismatch);

//             let channel_banner = channel::get_banner(channel);
//             assert!(channel_banner == new_channel_banner, EChannelBannerMismatch);

//             let channel_description = channel::get_description(channel);
//             assert!(channel_description == new_channel_description, EChannelDescriptionMismatch);

//             let channel_name = channel::get_name(channel);
//             assert!(channel_name == new_channel_name, EChannelNameMismatch);
//         };

//         ts::end(scenario_val);
//     }
// }
