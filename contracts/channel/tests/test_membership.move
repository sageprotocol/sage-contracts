// #[test_only]
// module sage_channel::test_channel_membership {
//     use std::string::{utf8};

//     use sui::{
//         test_scenario::{Self as ts, Scenario},
//         test_utils::{destroy}
//     };

//     use sage_admin::{admin::{Self}};

//     use sage_channel::{
//         channel_membership::{Self, ChannelMembershipRegistry, EChannelMemberExists}
//     };

//     // --------------- Constants ---------------

//     const ADMIN: address = @admin;

//     // --------------- Errors ---------------

//     const EChannelMembershipCountMismatch: u64 = 0;
//     const EChannelNotMember: u64 = 1;

//     // --------------- Test Functions ---------------

//     #[test_only]
//     public fun setup_for_testing(): (Scenario, ChannelMembershipRegistry) {
//         let mut scenario_val = ts::begin(ADMIN);
//         let scenario = &mut scenario_val;
//         {
//             admin::init_for_testing(ts::ctx(scenario));
//             channel_membership::init_for_testing(ts::ctx(scenario));
//         };

//         ts::next_tx(scenario, ADMIN);
//         let channel_membership_registry = {
//             let channel_membership_registry = scenario.take_shared<ChannelMembershipRegistry>();

//             channel_membership_registry
//         };

//         (scenario_val, channel_membership_registry)
//     }

//     #[test]
//     fun registry_init() {
//         let (
//             mut scenario_val,
//             channel_membership_registry_val
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             destroy(channel_membership_registry_val);
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     fun create() {
//         let (
//             mut scenario_val,
//             mut channel_membership_registry_val,
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let channel_membership_registry = &mut channel_membership_registry_val;

//             let channel_key = utf8(b"channel-name");

//             channel_membership::create(
//                 channel_membership_registry,
//                 channel_key,
//                 ts::ctx(scenario)
//             );

//             let channel_membership = channel_membership::borrow_membership_mut(
//                 channel_membership_registry,
//                 channel_key
//             );

//             let channel_member_count = channel_membership::get_member_length(
//                 channel_membership
//             );

//             assert!(channel_member_count == 1, EChannelMembershipCountMismatch);

//             let is_member = channel_membership::is_member(
//                 channel_membership,
//                 ADMIN
//             );

//             assert!(is_member, EChannelNotMember);

//             destroy(channel_membership_registry_val);
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     #[expected_failure(abort_code = EChannelMemberExists)]
//     fun join() {
//         let (
//             mut scenario_val,
//             mut channel_membership_registry_val,
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let channel_membership_registry = &mut channel_membership_registry_val;

//             let channel_key = utf8(b"channel-name");

//             channel_membership::create(
//                 channel_membership_registry,
//                 channel_key,
//                 ts::ctx(scenario)
//             );

//             let channel_membership = channel_membership::borrow_membership_mut(
//                 channel_membership_registry,
//                 channel_key
//             );

//             channel_membership::join(
//                 channel_membership,
//                 channel_key,
//                 ts::ctx(scenario)
//             );

//             let is_member = channel_membership::is_member(
//                 channel_membership,
//                 ADMIN
//             );

//             assert!(is_member, EChannelNotMember);

//             let member_length = channel_membership::get_member_length(
//                 channel_membership
//             );

//             assert!(member_length == 1, EChannelMembershipCountMismatch);

//             destroy(channel_membership_registry_val);
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     fun leave() {
//         let (
//             mut scenario_val,
//             mut channel_membership_registry_val,
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let channel_membership_registry = &mut channel_membership_registry_val;

//             let channel_key = utf8(b"channel-name");

//             channel_membership::create(
//                 channel_membership_registry,
//                 channel_key,
//                 ts::ctx(scenario)
//             );

//             let channel_membership = channel_membership::borrow_membership_mut(
//                 channel_membership_registry,
//                 channel_key
//             );

//             channel_membership::leave(
//                 channel_membership,
//                 channel_key,
//                 ts::ctx(scenario)
//             );

//             let channel_member_count_leave = channel_membership::get_member_length(
//                 channel_membership
//             );

//             assert!(channel_member_count_leave == 0, EChannelMembershipCountMismatch);

//             channel_membership::join(
//                 channel_membership,
//                 channel_key,
//                 ts::ctx(scenario)
//             );

//             let channel_member_count_join = channel_membership::get_member_length(
//                 channel_membership
//             );

//             assert!(channel_member_count_join == 1, EChannelMembershipCountMismatch);

//             destroy(channel_membership_registry_val);
//         };

//         ts::end(scenario_val);
//     }
// }
