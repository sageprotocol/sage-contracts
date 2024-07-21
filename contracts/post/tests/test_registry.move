// #[test_only]
// module sage_post::test_post_registry {
//     use std::string::{utf8};

//     use sui::test_scenario::{Self as ts, Scenario};

//     use sage_admin::{admin::{Self, AdminCap}};

//     use sage_post::{
//         post::{Self},
//         post_registry::{Self, PostRegistry}
//     };

//     // --------------- Constants ---------------

//     const ADMIN: address = @admin;

//     // --------------- Errors ---------------

//     const EPostMismatch: u64 = 0;
//     const EPostIdMismatch: u64 = 1;
//     const EPostExistsMismatch: u64 = 2;

//     // --------------- Test Functions ---------------

//     #[test_only]
//     fun setup_for_testing(): (Scenario, PostRegistry) {
//         let mut scenario_val = ts::begin(ADMIN);
//         let scenario = &mut scenario_val;
//         {
//             admin::init_for_testing(ts::ctx(scenario));
//         };

//         ts::next_tx(scenario, ADMIN);
//         let post_registry = {
//             let admin_cap = ts::take_from_sender<AdminCap>(scenario);

//             let post_registry = post_registry::create_post_registry(
//                 &admin_cap,
//                 ts::ctx(scenario)
//             );

//             ts::return_to_sender(scenario, admin_cap);

//             post_registry
//         };

//         (scenario_val, post_registry)
//     }

//     #[test]
//     fun test_post_registry_init() {
//         let (
//             mut scenario_val,
//             post_registry_val
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             post_registry::destroy_for_testing(post_registry_val);
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     fun test_post_registry_get_post() {
//         let (
//             mut scenario_val,
//             mut post_registry_val
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let post_registry = &mut post_registry_val;

//             let created_at: u64 = 999;
//             let user: address = @0xaaa;

//             let (post, post_id) = post::create(
//                 user,
//                 utf8(b"data"),
//                 utf8(b"description"),
//                 utf8(b"title"),
//                 created_at,
//                 ts::ctx(scenario)
//             );

//             post_registry::add(
//                 post_registry,
//                 post_id,
//                 post
//             );

//             let retrieved_post = post_registry::get_post(
//                 post_registry,
//                 post_id
//             );

//             assert!(retrieved_post == post, EPostMismatch);

//             post_registry::destroy_for_testing(post_registry_val);
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     fun test_post_registry_get_post_name() {
//         let (
//             mut scenario_val,
//             mut post_registry_val
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let post_registry = &mut post_registry_val;

//             let post_name = utf8(b"post-name");
//             let created_at: u64 = 999;

//             let post = post::create(
//                 post_name,
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 created_at,
//                 ADMIN
//             );

//             post_registry::add(
//                 post_registry,
//                 post_name,
//                 post
//             );

//             let retrieved_post_name = post_registry::get_post_name(
//                 post_registry,
//                 post
//             );

//             assert!(retrieved_post_name == post_name, EPostIdMismatch);

//             post_registry::destroy_for_testing(post_registry_val);
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     fun test_post_has_record() {
//         let (
//             mut scenario_val,
//             mut post_registry_val
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let post_registry = &mut post_registry_val;

//             let post_name = utf8(b"post-name");
//             let created_at: u64 = 999;

//             let post = post::create(
//                 post_name,
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 created_at,
//                 ADMIN
//             );

//             post_registry::add(
//                 post_registry,
//                 post_name,
//                 post
//             );

//             let has_record = post_registry::has_record(
//                 post_registry,
//                 post_name
//             );

//             assert!(has_record, EPostExistsMismatch);

//             post_registry::destroy_for_testing(post_registry_val);
//         };

//         ts::end(scenario_val);
//     }
// }
