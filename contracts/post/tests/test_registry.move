// #[test_only]
// module sage_post::test_post_registry {
//     use std::string::{utf8};

//     use sui::{
//         test_scenario::{Self as ts, Scenario},
//         test_utils::{destroy}
//     };

//     use sage_admin::{admin::{Self}};

//     use sage_post::{
//         post::{Self},
//         post_registry::{Self, PostRegistry}
//     };

//     // --------------- Constants ---------------

//     const ADMIN: address = @admin;

//     // --------------- Errors ---------------

//     const EPostMismatch: u64 = 0;
//     const EPostDoesNotExist: u64 = 1;

//     // --------------- Test Functions ---------------

//     #[test_only]
//     fun setup_for_testing(): (Scenario, PostRegistry) {
//         let mut scenario_val = ts::begin(ADMIN);
//         let scenario = &mut scenario_val;
//         {
//             admin::init_for_testing(ts::ctx(scenario));
//             post_registry::init_for_testing(ts::ctx(scenario));
//         };

//         ts::next_tx(scenario, ADMIN);
//         let post_registry = {
//             let post_registry = scenario.take_shared<PostRegistry>();

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
//             destroy(post_registry_val);
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     fun test_post_registry_borrow_post() {
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

//             let (post, post_key) = post::create(
//                 user,
//                 utf8(b"data"),
//                 utf8(b"description"),
//                 utf8(b"title"),
//                 created_at,
//                 ts::ctx(scenario)
//             );

//             post_registry::add(
//                 post_registry,
//                 post_key,
//                 post
//             );

//             let retrieved_post = post_registry::borrow_post(
//                 post_registry,
//                 post_key
//             );

//             assert!(retrieved_post == post, EPostMismatch);

//             destroy(post_registry_val);
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     fun test_post_registry_has_record() {
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

//             let (post, post_key) = post::create(
//                 user,
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 created_at,
//                 ts::ctx(scenario)
//             );

//             post_registry::add(
//                 post_registry,
//                 post_key,
//                 post
//             );

//             let has_record = post_registry::has_record(
//                 post_registry,
//                 post_key
//             );

//             assert!(has_record, EPostDoesNotExist);

//             destroy(post_registry_val);
//         };

//         ts::end(scenario_val);
//     }
// }
