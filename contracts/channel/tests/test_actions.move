// #[test_only]
// module sage_channel::test_channel_actions {
//     use std::string::{utf8};

//     use sui::{
//         clock::{Self, Clock},
//         coin::{mint_for_testing},
//         sui::{SUI},
//         test_scenario::{Self as ts, Scenario},
//         test_utils::{destroy}
//     };

//     use sage_admin::{
//         admin::{
//             Self,
//             AdminCap,
//             InviteCap
//         },
//         apps::{Self, App}
//     };

//     use sage_channel::{
//         channel::{Self},
//         channel_actions::{
//             Self,
//             EAlreadyChannelModerator,
//             EChannelModeratorLength,
//             EChannelNameMismatch,
//             ENotChannelModerator,
//             ENotChannelOwner,
//             EUserDoesNotExist
//         },
//         channel_fees::{
//             Self,
//             ChannelFees,
//             EIncorrectCustomPayment,
//             EIncorrectSuiPayment
//         },
//         channel_membership::{Self, ChannelMembershipRegistry},
//         channel_moderation::{Self, ChannelModerationRegistry},
//         channel_registry::{Self, ChannelRegistry},
//     };

//     use sage_user::{
//         user_actions::{Self},
//         user_fees::{Self, UserFees},
//         user_invite::{Self, InviteConfig, UserInviteRegistry},
//         user_membership::{Self, UserMembershipRegistry},
//         user_registry::{Self, UserRegistry}
//     };

//     // --------------- Constants ---------------

//     const ADMIN: address = @admin;
//     const SERVER: address = @server;

//     const ADD_MODERATOR_CUSTOM_FEE: u64 = 1;
//     const ADD_MODERATOR_SUI_FEE: u64 = 2;
//     const CREATE_CHANNEL_CUSTOM_FEE: u64 = 3;
//     const CREATE_CHANNEL_SUI_FEE: u64 = 4;
//     const JOIN_CHANNEL_CUSTOM_FEE: u64 = 5;
//     const JOIN_CHANNEL_SUI_FEE: u64 = 6;
//     const LEAVE_CHANNEL_CUSTOM_FEE: u64 = 7;
//     const LEAVE_CHANNEL_SUI_FEE: u64 = 8;
//     const REMOVE_MODERATOR_CUSTOM_FEE: u64 = 9;
//     const REMOVE_MODERATOR_SUI_FEE: u64 = 10;
//     const UPDATE_CHANNEL_CUSTOM_FEE: u64 = 11;
//     const UPDATE_CHANNEL_SUI_FEE: u64 = 12;

//     const CREATE_INVITE_CUSTOM_FEE: u64 = 21;
//     const CREATE_INVITE_SUI_FEE: u64 = 22;
//     const CREATE_USER_CUSTOM_FEE: u64 = 23;
//     const CREATE_USER_SUI_FEE: u64 = 24;
//     const JOIN_USER_CUSTOM_FEE: u64 = 25;
//     const JOIN_USER_SUI_FEE: u64 = 26;
//     const LEAVE_USER_CUSTOM_FEE: u64 = 27;
//     const LEAVE_USER_SUI_FEE: u64 = 28;
//     const UPDATE_USER_CUSTOM_FEE: u64 = 29;
//     const UPDATE_USER_SUI_FEE: u64 = 30;

//     const INCORRECT_FEE: u64 = 100;

//     // --------------- Errors ---------------

//     const EMemberLength: u64 = 0;
//     const EHasMember: u64 = 1;
//     const EChannelAvatarMismatch: u64 = 2;
//     const EChannelBannerMismatch: u64 = 3;
//     const EChannelDescriptionMismatch: u64 = 4;
//     const EIsModerator: u64 = 5;
//     const EIsNotModerator: u64 = 6;
//     const EModeratorLengthMismatch: u64 = 7;
//     const ETestChannelNameMismatch: u64 = 8;

//     // --------------- Test Functions ---------------

//     #[test_only]
//     fun destroy_for_testing(
//         app: App,
//         channel_fees: ChannelFees,
//         channel_registry: ChannelRegistry,
//         channel_membership_registry: ChannelMembershipRegistry,
//         channel_moderation_registry: ChannelModerationRegistry,
//         invite_config: InviteConfig,
//         user_registry: UserRegistry,
//         user_invite_registry: UserInviteRegistry,
//         user_membership_registry: UserMembershipRegistry,
//         user_fees: UserFees
//     ) {
//         destroy(app);
//         destroy(channel_fees);
//         destroy(channel_registry);
//         destroy(channel_membership_registry);
//         destroy(channel_moderation_registry);
//         destroy(invite_config);
//         destroy(user_registry);
//         destroy(user_invite_registry);
//         destroy(user_membership_registry);
//         destroy(user_fees);
//     }

//     #[test_only]
//     fun setup_for_testing(): (
//         Scenario,
//         App,
//         ChannelFees,
//         ChannelRegistry,
//         ChannelMembershipRegistry,
//         ChannelModerationRegistry,
//         InviteConfig,
//         UserRegistry,
//         UserInviteRegistry,
//         UserMembershipRegistry,
//         UserFees
//     ) {
//         let mut scenario_val = ts::begin(ADMIN);
//         let scenario = &mut scenario_val;
//         {
//             admin::init_for_testing(ts::ctx(scenario));
//             apps::init_for_testing(ts::ctx(scenario));
//             channel_membership::init_for_testing(ts::ctx(scenario));
//             channel_moderation::init_for_testing(ts::ctx(scenario));
//             channel_registry::init_for_testing(ts::ctx(scenario));
//             user_invite::init_for_testing(ts::ctx(scenario));
//             user_membership::init_for_testing(ts::ctx(scenario));
//             user_registry::init_for_testing(ts::ctx(scenario));
//         };

//         ts::next_tx(scenario, ADMIN);
//         let (
//             app,
//             channel_fees,
//             channel_registry,
//             channel_membership_registry,
//             channel_moderation_registry,
//             invite_config,
//             user_registry,
//             user_invite_registry,
//             user_membership_registry,
//             user_fees
//         ) = {
//             let channel_registry = scenario.take_shared<ChannelRegistry>();
//             let channel_membership_registry = scenario.take_shared<ChannelMembershipRegistry>();
//             let channel_moderation_registry = scenario.take_shared<ChannelModerationRegistry>();
//             let invite_config = scenario.take_shared<InviteConfig>();
//             let user_invite_registry = scenario.take_shared<UserInviteRegistry>();
//             let user_membership_registry = scenario.take_shared<UserMembershipRegistry>();
//             let user_registry = scenario.take_shared<UserRegistry>();

//             let mut app = apps::create_for_testing(
//                 utf8(b"sage"),
//                 ts::ctx(scenario)
//             );

//             let channel_fees = channel_fees::create_for_testing<SUI>(
//                 &mut app,
//                 ADD_MODERATOR_CUSTOM_FEE,
//                 ADD_MODERATOR_SUI_FEE,
//                 CREATE_CHANNEL_CUSTOM_FEE,
//                 CREATE_CHANNEL_SUI_FEE,
//                 JOIN_CHANNEL_CUSTOM_FEE,
//                 JOIN_CHANNEL_SUI_FEE,
//                 LEAVE_CHANNEL_CUSTOM_FEE,
//                 LEAVE_CHANNEL_SUI_FEE,
//                 REMOVE_MODERATOR_CUSTOM_FEE,
//                 REMOVE_MODERATOR_SUI_FEE,
//                 UPDATE_CHANNEL_CUSTOM_FEE,
//                 UPDATE_CHANNEL_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let user_fees = user_fees::create_for_testing<SUI>(
//                 &mut app,
//                 CREATE_INVITE_CUSTOM_FEE,
//                 CREATE_INVITE_SUI_FEE,
//                 CREATE_USER_CUSTOM_FEE,
//                 CREATE_USER_SUI_FEE,
//                 JOIN_USER_CUSTOM_FEE,
//                 JOIN_USER_SUI_FEE,
//                 LEAVE_USER_CUSTOM_FEE,
//                 LEAVE_USER_SUI_FEE,
//                 UPDATE_USER_CUSTOM_FEE,
//                 UPDATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             (
//                 app,
//                 channel_fees,
//                 channel_registry,
//                 channel_membership_registry,
//                 channel_moderation_registry,
//                 invite_config,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 user_fees
//             )
//         };

//         (
//             scenario_val,
//             app,
//             channel_fees,
//             channel_registry,
//             channel_membership_registry,
//             channel_moderation_registry,
//             invite_config,
//             user_registry,
//             user_invite_registry,
//             user_membership_registry,
//             user_fees
//         )
//     }

//     #[test]
//     fun test_init() {
//         let (
//             mut scenario_val,
//             app,
//             channel_fees,
//             channel_registry_val,
//             channel_membership_registry_val,
//             channel_moderation_registry_val,
//             invite_config,
//             user_registry_val,
//             user_invite_registry_val,
//             user_membership_registry_val,
//             user_fees
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             destroy_for_testing(
//                 app,
//                 channel_fees,
//                 channel_registry_val,
//                 channel_membership_registry_val,
//                 channel_moderation_registry_val,
//                 invite_config,
//                 user_registry_val,
//                 user_invite_registry_val,
//                 user_membership_registry_val,
//                 user_fees
//             );
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     fun create() {
//         let (
//             mut scenario_val,
//             app,
//             channel_fees,
//             mut channel_registry_val,
//             mut channel_membership_registry_val,
//             mut channel_moderation_registry_val,
//             mut invite_config,
//             mut user_registry_val,
//             mut user_invite_registry_val,
//             mut user_membership_registry_val,
//             user_fees
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         let channel_registry = &mut channel_registry_val;
//         let channel_membership_registry = &mut channel_membership_registry_val;
//         let channel_moderation_registry = &mut channel_moderation_registry_val;
//         let user_registry = &mut user_registry_val;
//         let user_invite_registry = &mut user_invite_registry_val;
//         let user_membership_registry = &mut user_membership_registry_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let mut clock = clock::create_for_testing(ts::ctx(scenario));

//             clock::set_for_testing(&mut clock, 0);
//             clock::share_for_testing(clock);
//         };

//         ts::next_tx(scenario, SERVER);
//         {
//             let invite_cap = ts::take_from_sender<InviteCap>(scenario);

//             user_invite::set_invite_config(
//                 &invite_cap,
//                 &mut invite_config,
//                 false
//             );

//             ts::return_to_sender(scenario, invite_cap);
//         };

//         ts::next_tx(scenario, ADMIN);
//         {
//             let clock: Clock = ts::take_shared(scenario);

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 utf8(b"user-name"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let channel_name = utf8(b"channel-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _channel = channel_actions::create(
//                 &clock,
//                 channel_registry,
//                 channel_membership_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let channel_membership = channel_membership::borrow_membership_mut(
//                 channel_membership_registry,
//                 channel_name
//             );

//             let member_length = channel_membership::get_member_length(
//                 channel_membership
//             );

//             assert!(member_length == 1, EMemberLength);

//             let has_member = channel_registry::has_record(
//                 channel_registry,
//                 channel_name
//             );

//             assert!(has_member, EHasMember);

//             let is_moderator = channel_moderation::is_moderator(
//                 channel_moderation_registry,
//                 channel_name,
//                 ADMIN
//             );

//             assert!(is_moderator, EIsNotModerator);

//             let moderator_length = channel_moderation::get_moderator_length(
//                 channel_moderation_registry,
//                 channel_name
//             );

//             assert!(moderator_length == 1, EModeratorLengthMismatch);

//             ts::return_shared(clock);

//             destroy_for_testing(
//                 app,
//                 channel_fees,
//                 channel_registry_val,
//                 channel_membership_registry_val,
//                 channel_moderation_registry_val,
//                 invite_config,
//                 user_registry_val,
//                 user_invite_registry_val,
//                 user_membership_registry_val,
//                 user_fees
//             );
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     #[expected_failure(abort_code = EUserDoesNotExist)]
//     fun create_no_user() {
//         let (
//             mut scenario_val,
//             app,
//             channel_fees,
//             mut channel_registry_val,
//             mut channel_membership_registry_val,
//             mut channel_moderation_registry_val,
//             invite_config,
//             user_registry_val,
//             user_invite_registry_val,
//             user_membership_registry_val,
//             user_fees
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         let channel_registry = &mut channel_registry_val;
//         let channel_membership_registry = &mut channel_membership_registry_val;
//         let channel_moderation_registry = &mut channel_moderation_registry_val;
//         let user_registry = &user_registry_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let mut clock = clock::create_for_testing(ts::ctx(scenario));

//             clock::set_for_testing(&mut clock, 0);
//             clock::share_for_testing(clock);
//         };

//         ts::next_tx(scenario, ADMIN);
//         {
//             let clock: Clock = ts::take_shared(scenario);

//             let channel_name = utf8(b"channel-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _channel = channel_actions::create(
//                 &clock,
//                 channel_registry,
//                 channel_membership_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let channel_membership = channel_membership::borrow_membership_mut(
//                 channel_membership_registry,
//                 channel_name
//             );

//             let member_length = channel_membership::get_member_length(
//                 channel_membership
//             );

//             assert!(member_length == 1, EMemberLength);

//             let has_member = channel_registry::has_record(
//                 channel_registry,
//                 channel_name
//             );

//             assert!(has_member, EHasMember);

//             ts::return_shared(clock);

//             destroy_for_testing(
//                 app,
//                 channel_fees,
//                 channel_registry_val,
//                 channel_membership_registry_val,
//                 channel_moderation_registry_val,
//                 invite_config,
//                 user_registry_val,
//                 user_invite_registry_val,
//                 user_membership_registry_val,
//                 user_fees
//             );
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     #[expected_failure(abort_code = EIncorrectCustomPayment)]
//     fun create_incorrect_custom_payment() {
//         let (
//             mut scenario_val,
//             app,
//             channel_fees,
//             mut channel_registry_val,
//             mut channel_membership_registry_val,
//             mut channel_moderation_registry_val,
//             mut invite_config,
//             mut user_registry_val,
//             mut user_invite_registry_val,
//             mut user_membership_registry_val,
//             user_fees
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         let channel_registry = &mut channel_registry_val;
//         let channel_membership_registry = &mut channel_membership_registry_val;
//         let channel_moderation_registry = &mut channel_moderation_registry_val;
//         let user_registry = &mut user_registry_val;
//         let user_invite_registry = &mut user_invite_registry_val;
//         let user_membership_registry = &mut user_membership_registry_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let mut clock = clock::create_for_testing(ts::ctx(scenario));

//             clock::set_for_testing(&mut clock, 0);
//             clock::share_for_testing(clock);
//         };

//         ts::next_tx(scenario, SERVER);
//         {
//             let invite_cap = ts::take_from_sender<InviteCap>(scenario);

//             user_invite::set_invite_config(
//                 &invite_cap,
//                 &mut invite_config,
//                 false
//             );

//             ts::return_to_sender(scenario, invite_cap);
//         };

//         ts::next_tx(scenario, ADMIN);
//         {
//             let clock: Clock = ts::take_shared(scenario);

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 utf8(b"user-name"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let channel_name = utf8(b"channel-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 INCORRECT_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _channel = channel_actions::create(
//                 &clock,
//                 channel_registry,
//                 channel_membership_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             ts::return_shared(clock);

//             destroy_for_testing(
//                 app,
//                 channel_fees,
//                 channel_registry_val,
//                 channel_membership_registry_val,
//                 channel_moderation_registry_val,
//                 invite_config,
//                 user_registry_val,
//                 user_invite_registry_val,
//                 user_membership_registry_val,
//                 user_fees
//             );
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     #[expected_failure(abort_code = EIncorrectSuiPayment)]
//     fun create_incorrect_sui_payment() {
//         let (
//             mut scenario_val,
//             app,
//             channel_fees,
//             mut channel_registry_val,
//             mut channel_membership_registry_val,
//             mut channel_moderation_registry_val,
//             mut invite_config,
//             mut user_registry_val,
//             mut user_invite_registry_val,
//             mut user_membership_registry_val,
//             user_fees
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         let channel_registry = &mut channel_registry_val;
//         let channel_membership_registry = &mut channel_membership_registry_val;
//         let channel_moderation_registry = &mut channel_moderation_registry_val;
//         let user_registry = &mut user_registry_val;
//         let user_invite_registry = &mut user_invite_registry_val;
//         let user_membership_registry = &mut user_membership_registry_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let mut clock = clock::create_for_testing(ts::ctx(scenario));

//             clock::set_for_testing(&mut clock, 0);
//             clock::share_for_testing(clock);
//         };

//         ts::next_tx(scenario, SERVER);
//         {
//             let invite_cap = ts::take_from_sender<InviteCap>(scenario);

//             user_invite::set_invite_config(
//                 &invite_cap,
//                 &mut invite_config,
//                 false
//             );

//             ts::return_to_sender(scenario, invite_cap);
//         };

//         ts::next_tx(scenario, ADMIN);
//         {
//             let clock: Clock = ts::take_shared(scenario);

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 utf8(b"user-name"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let channel_name = utf8(b"channel-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 INCORRECT_FEE,
//                 ts::ctx(scenario)
//             );

//             let _channel = channel_actions::create(
//                 &clock,
//                 channel_registry,
//                 channel_membership_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             ts::return_shared(clock);

//             destroy_for_testing(
//                 app,
//                 channel_fees,
//                 channel_registry_val,
//                 channel_membership_registry_val,
//                 channel_moderation_registry_val,
//                 invite_config,
//                 user_registry_val,
//                 user_invite_registry_val,
//                 user_membership_registry_val,
//                 user_fees
//             );
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     fun add_moderator_admin() {
//         let (
//             mut scenario_val,
//             app,
//             channel_fees,
//             mut channel_registry_val,
//             mut channel_membership_registry_val,
//             mut channel_moderation_registry_val,
//             mut invite_config,
//             mut user_registry_val,
//             mut user_invite_registry_val,
//             mut user_membership_registry_val,
//             user_fees
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         let channel_registry = &mut channel_registry_val;
//         let channel_membership_registry = &mut channel_membership_registry_val;
//         let channel_moderation_registry = &mut channel_moderation_registry_val;
//         let user_registry = &mut user_registry_val;
//         let user_invite_registry = &mut user_invite_registry_val;
//         let user_membership_registry = &mut user_membership_registry_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let mut clock = clock::create_for_testing(ts::ctx(scenario));

//             clock::set_for_testing(&mut clock, 0);
//             clock::share_for_testing(clock);
//         };

//         ts::next_tx(scenario, SERVER);
//         let (clock, server_user_name) = {
//             let clock: Clock = ts::take_shared(scenario);
//             let invite_cap = ts::take_from_sender<InviteCap>(scenario);

//             user_invite::set_invite_config(
//                 &invite_cap,
//                 &mut invite_config,
//                 false
//             );

//             let server_user_name = utf8(b"server-user");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 server_user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             ts::return_to_sender(scenario, invite_cap);

//             (clock, server_user_name)
//         };

//         ts::next_tx(scenario, ADMIN);
//         {
//             let admin_cap = ts::take_from_sender<AdminCap>(scenario);

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 utf8(b"user-name"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let channel_name = utf8(b"channel-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _channel = channel_actions::create(
//                 &clock,
//                 channel_registry,
//                 channel_membership_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             channel_actions::add_moderator_as_admin(
//                 &admin_cap,
//                 channel_moderation_registry,
//                 user_registry,
//                 channel_name,
//                 server_user_name
//             );

//             let is_moderator = channel_moderation::is_moderator(
//                 channel_moderation_registry,
//                 channel_name,
//                 SERVER
//             );

//             assert!(is_moderator, EIsNotModerator);

//             let moderator_length = channel_moderation::get_moderator_length(
//                 channel_moderation_registry,
//                 channel_name
//             );

//             assert!(moderator_length == 2, EModeratorLengthMismatch);

//             ts::return_to_sender(scenario, admin_cap);
//             ts::return_shared(clock);

//             destroy_for_testing(
//                 app,
//                 channel_fees,
//                 channel_registry_val,
//                 channel_membership_registry_val,
//                 channel_moderation_registry_val,
//                 invite_config,
//                 user_registry_val,
//                 user_invite_registry_val,
//                 user_membership_registry_val,
//                 user_fees
//             );
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     #[expected_failure(abort_code = EAlreadyChannelModerator)]
//     fun add_moderator_admin_fail() {
//         let (
//             mut scenario_val,
//             app,
//             channel_fees,
//             mut channel_registry_val,
//             mut channel_membership_registry_val,
//             mut channel_moderation_registry_val,
//             mut invite_config,
//             mut user_registry_val,
//             mut user_invite_registry_val,
//             mut user_membership_registry_val,
//             user_fees
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         let channel_registry = &mut channel_registry_val;
//         let channel_membership_registry = &mut channel_membership_registry_val;
//         let channel_moderation_registry = &mut channel_moderation_registry_val;
//         let user_registry = &mut user_registry_val;
//         let user_invite_registry = &mut user_invite_registry_val;
//         let user_membership_registry = &mut user_membership_registry_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let mut clock = clock::create_for_testing(ts::ctx(scenario));

//             clock::set_for_testing(&mut clock, 0);
//             clock::share_for_testing(clock);
//         };

//         ts::next_tx(scenario, SERVER);
//         {
//             let invite_cap = ts::take_from_sender<InviteCap>(scenario);

//             user_invite::set_invite_config(
//                 &invite_cap,
//                 &mut invite_config,
//                 false
//             );

//             ts::return_to_sender(scenario, invite_cap);
//         };

//         ts::next_tx(scenario, ADMIN);
//         {
//             let admin_cap = ts::take_from_sender<AdminCap>(scenario);
//             let clock: Clock = ts::take_shared(scenario);

//             let user_name = utf8(b"user-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let channel_name = utf8(b"channel-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _channel = channel_actions::create(
//                 &clock,
//                 channel_registry,
//                 channel_membership_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             channel_actions::add_moderator_as_admin(
//                 &admin_cap,
//                 channel_moderation_registry,
//                 user_registry,
//                 channel_name,
//                 user_name
//             );

//             ts::return_to_sender(scenario, admin_cap);
//             ts::return_shared(clock);

//             destroy_for_testing(
//                 app,
//                 channel_fees,
//                 channel_registry_val,
//                 channel_membership_registry_val,
//                 channel_moderation_registry_val,
//                 invite_config,
//                 user_registry_val,
//                 user_invite_registry_val,
//                 user_membership_registry_val,
//                 user_fees
//             );
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     fun add_moderator_owner() {
//         let (
//             mut scenario_val,
//             app,
//             channel_fees,
//             mut channel_registry_val,
//             mut channel_membership_registry_val,
//             mut channel_moderation_registry_val,
//             mut invite_config,
//             mut user_registry_val,
//             mut user_invite_registry_val,
//             mut user_membership_registry_val,
//             user_fees
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         let channel_registry = &mut channel_registry_val;
//         let channel_membership_registry = &mut channel_membership_registry_val;
//         let channel_moderation_registry = &mut channel_moderation_registry_val;
//         let user_registry = &mut user_registry_val;
//         let user_invite_registry = &mut user_invite_registry_val;
//         let user_membership_registry = &mut user_membership_registry_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let mut clock = clock::create_for_testing(ts::ctx(scenario));

//             clock::set_for_testing(&mut clock, 0);
//             clock::share_for_testing(clock);
//         };

//         ts::next_tx(scenario, SERVER);
//         let (clock, server_user_name) = {
//             let clock: Clock = ts::take_shared(scenario);
//             let invite_cap = ts::take_from_sender<InviteCap>(scenario);

//             user_invite::set_invite_config(
//                 &invite_cap,
//                 &mut invite_config,
//                 false
//             );

//             let server_user_name = utf8(b"server-user");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 server_user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             ts::return_to_sender(scenario, invite_cap);

//             (clock, server_user_name)
//         };

//         ts::next_tx(scenario, ADMIN);
//         {
//             let user_name = utf8(b"user-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let channel_name = utf8(b"channel-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _channel = channel_actions::create(
//                 &clock,
//                 channel_registry,
//                 channel_membership_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let custom_payment = mint_for_testing<SUI>(
//                 ADD_MODERATOR_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 ADD_MODERATOR_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             channel_actions::add_moderator_as_owner(
//                 channel_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 server_user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let is_moderator = channel_moderation::is_moderator(
//                 channel_moderation_registry,
//                 channel_name,
//                 SERVER
//             );

//             assert!(is_moderator, EIsNotModerator);

//             let moderator_length = channel_moderation::get_moderator_length(
//                 channel_moderation_registry,
//                 channel_name
//             );

//             assert!(moderator_length == 2, EModeratorLengthMismatch);

//             ts::return_shared(clock);

//             destroy_for_testing(
//                 app,
//                 channel_fees,
//                 channel_registry_val,
//                 channel_membership_registry_val,
//                 channel_moderation_registry_val,
//                 invite_config,
//                 user_registry_val,
//                 user_invite_registry_val,
//                 user_membership_registry_val,
//                 user_fees
//             );
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     #[expected_failure(abort_code = EIncorrectCustomPayment)]
//     fun add_moderator_owner_incorrect_custom_payment() {
//         let (
//             mut scenario_val,
//             app,
//             channel_fees,
//             mut channel_registry_val,
//             mut channel_membership_registry_val,
//             mut channel_moderation_registry_val,
//             mut invite_config,
//             mut user_registry_val,
//             mut user_invite_registry_val,
//             mut user_membership_registry_val,
//             user_fees
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         let channel_registry = &mut channel_registry_val;
//         let channel_membership_registry = &mut channel_membership_registry_val;
//         let channel_moderation_registry = &mut channel_moderation_registry_val;
//         let user_registry = &mut user_registry_val;
//         let user_invite_registry = &mut user_invite_registry_val;
//         let user_membership_registry = &mut user_membership_registry_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let mut clock = clock::create_for_testing(ts::ctx(scenario));

//             clock::set_for_testing(&mut clock, 0);
//             clock::share_for_testing(clock);
//         };

//         ts::next_tx(scenario, SERVER);
//         let (clock, server_user_name) = {
//             let clock: Clock = ts::take_shared(scenario);
//             let invite_cap = ts::take_from_sender<InviteCap>(scenario);

//             user_invite::set_invite_config(
//                 &invite_cap,
//                 &mut invite_config,
//                 false
//             );

//             let server_user_name = utf8(b"server-user");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 server_user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             ts::return_to_sender(scenario, invite_cap);

//             (clock, server_user_name)
//         };

//         ts::next_tx(scenario, ADMIN);
//         {
//             let user_name = utf8(b"user-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let channel_name = utf8(b"channel-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _channel = channel_actions::create(
//                 &clock,
//                 channel_registry,
//                 channel_membership_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let custom_payment = mint_for_testing<SUI>(
//                 INCORRECT_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 ADD_MODERATOR_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             channel_actions::add_moderator_as_owner(
//                 channel_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 server_user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             ts::return_shared(clock);

//             destroy_for_testing(
//                 app,
//                 channel_fees,
//                 channel_registry_val,
//                 channel_membership_registry_val,
//                 channel_moderation_registry_val,
//                 invite_config,
//                 user_registry_val,
//                 user_invite_registry_val,
//                 user_membership_registry_val,
//                 user_fees
//             );
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     #[expected_failure(abort_code = EIncorrectSuiPayment)]
//     fun add_moderator_owner_incorrect_sui_payment() {
//         let (
//             mut scenario_val,
//             app,
//             channel_fees,
//             mut channel_registry_val,
//             mut channel_membership_registry_val,
//             mut channel_moderation_registry_val,
//             mut invite_config,
//             mut user_registry_val,
//             mut user_invite_registry_val,
//             mut user_membership_registry_val,
//             user_fees
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         let channel_registry = &mut channel_registry_val;
//         let channel_membership_registry = &mut channel_membership_registry_val;
//         let channel_moderation_registry = &mut channel_moderation_registry_val;
//         let user_registry = &mut user_registry_val;
//         let user_invite_registry = &mut user_invite_registry_val;
//         let user_membership_registry = &mut user_membership_registry_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let mut clock = clock::create_for_testing(ts::ctx(scenario));

//             clock::set_for_testing(&mut clock, 0);
//             clock::share_for_testing(clock);
//         };

//         ts::next_tx(scenario, SERVER);
//         let (clock, server_user_name) = {
//             let clock: Clock = ts::take_shared(scenario);
//             let invite_cap = ts::take_from_sender<InviteCap>(scenario);

//             user_invite::set_invite_config(
//                 &invite_cap,
//                 &mut invite_config,
//                 false
//             );

//             let server_user_name = utf8(b"server-user");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 server_user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             ts::return_to_sender(scenario, invite_cap);

//             (clock, server_user_name)
//         };

//         ts::next_tx(scenario, ADMIN);
//         {
//             let user_name = utf8(b"user-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let channel_name = utf8(b"channel-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _channel = channel_actions::create(
//                 &clock,
//                 channel_registry,
//                 channel_membership_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let custom_payment = mint_for_testing<SUI>(
//                 ADD_MODERATOR_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 INCORRECT_FEE,
//                 ts::ctx(scenario)
//             );

//             channel_actions::add_moderator_as_owner(
//                 channel_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 server_user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             ts::return_shared(clock);

//             destroy_for_testing(
//                 app,
//                 channel_fees,
//                 channel_registry_val,
//                 channel_membership_registry_val,
//                 channel_moderation_registry_val,
//                 invite_config,
//                 user_registry_val,
//                 user_invite_registry_val,
//                 user_membership_registry_val,
//                 user_fees
//             );
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     #[expected_failure(abort_code = ENotChannelOwner)]
//     fun add_moderator_owner_not_owner() {
//         let (
//             mut scenario_val,
//             app,
//             channel_fees,
//             mut channel_registry_val,
//             mut channel_membership_registry_val,
//             mut channel_moderation_registry_val,
//             mut invite_config,
//             mut user_registry_val,
//             mut user_invite_registry_val,
//             mut user_membership_registry_val,
//             user_fees
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         let channel_registry = &mut channel_registry_val;
//         let channel_membership_registry = &mut channel_membership_registry_val;
//         let channel_moderation_registry = &mut channel_moderation_registry_val;
//         let user_registry = &mut user_registry_val;
//         let user_invite_registry = &mut user_invite_registry_val;
//         let user_membership_registry = &mut user_membership_registry_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let mut clock = clock::create_for_testing(ts::ctx(scenario));

//             clock::set_for_testing(&mut clock, 0);
//             clock::share_for_testing(clock);
//         };

//         ts::next_tx(scenario, SERVER);
//         let (clock) = {
//             let clock: Clock = ts::take_shared(scenario);
//             let invite_cap = ts::take_from_sender<InviteCap>(scenario);

//             user_invite::set_invite_config(
//                 &invite_cap,
//                 &mut invite_config,
//                 false
//             );

//             let server_user_name = utf8(b"server-user");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 server_user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             ts::return_to_sender(scenario, invite_cap);

//             (clock)
//         };

//         ts::next_tx(scenario, ADMIN);
//         let (channel_name, user_name) = {
//             let user_name = utf8(b"user-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let channel_name = utf8(b"channel-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _channel = channel_actions::create(
//                 &clock,
//                 channel_registry,
//                 channel_membership_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             (channel_name, user_name)
//         };

//         ts::next_tx(scenario, SERVER);
//         {
//             let custom_payment = mint_for_testing<SUI>(
//                 ADD_MODERATOR_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 ADD_MODERATOR_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             channel_actions::add_moderator_as_owner(
//                 channel_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let is_moderator = channel_moderation::is_moderator(
//                 channel_moderation_registry,
//                 channel_name,
//                 SERVER
//             );

//             assert!(is_moderator, EIsNotModerator);

//             let moderator_length = channel_moderation::get_moderator_length(
//                 channel_moderation_registry,
//                 channel_name
//             );

//             assert!(moderator_length == 2, EModeratorLengthMismatch);

//             ts::return_shared(clock);

//             destroy_for_testing(
//                 app,
//                 channel_fees,
//                 channel_registry_val,
//                 channel_membership_registry_val,
//                 channel_moderation_registry_val,
//                 invite_config,
//                 user_registry_val,
//                 user_invite_registry_val,
//                 user_membership_registry_val,
//                 user_fees
//             );
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     #[expected_failure(abort_code = EAlreadyChannelModerator)]
//     fun add_moderator_owner_already_moderator() {
//         let (
//             mut scenario_val,
//             app,
//             channel_fees,
//             mut channel_registry_val,
//             mut channel_membership_registry_val,
//             mut channel_moderation_registry_val,
//             mut invite_config,
//             mut user_registry_val,
//             mut user_invite_registry_val,
//             mut user_membership_registry_val,
//             user_fees
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         let channel_registry = &mut channel_registry_val;
//         let channel_membership_registry = &mut channel_membership_registry_val;
//         let channel_moderation_registry = &mut channel_moderation_registry_val;
//         let user_registry = &mut user_registry_val;
//         let user_invite_registry = &mut user_invite_registry_val;
//         let user_membership_registry = &mut user_membership_registry_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let mut clock = clock::create_for_testing(ts::ctx(scenario));

//             clock::set_for_testing(&mut clock, 0);
//             clock::share_for_testing(clock);
//         };

//         ts::next_tx(scenario, SERVER);
//         let (clock) = {
//             let clock: Clock = ts::take_shared(scenario);
//             let invite_cap = ts::take_from_sender<InviteCap>(scenario);

//             user_invite::set_invite_config(
//                 &invite_cap,
//                 &mut invite_config,
//                 false
//             );

//             let server_user_name = utf8(b"server-user");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 server_user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             ts::return_to_sender(scenario, invite_cap);

//             (clock)
//         };

//         ts::next_tx(scenario, ADMIN);
//         {
//             let user_name = utf8(b"user-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let channel_name = utf8(b"channel-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _channel = channel_actions::create(
//                 &clock,
//                 channel_registry,
//                 channel_membership_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let custom_payment = mint_for_testing<SUI>(
//                 ADD_MODERATOR_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 ADD_MODERATOR_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             channel_actions::add_moderator_as_owner(
//                 channel_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let is_moderator = channel_moderation::is_moderator(
//                 channel_moderation_registry,
//                 channel_name,
//                 SERVER
//             );

//             assert!(is_moderator, EIsNotModerator);

//             let moderator_length = channel_moderation::get_moderator_length(
//                 channel_moderation_registry,
//                 channel_name
//             );

//             assert!(moderator_length == 2, EModeratorLengthMismatch);

//             ts::return_shared(clock);

//             destroy_for_testing(
//                 app,
//                 channel_fees,
//                 channel_registry_val,
//                 channel_membership_registry_val,
//                 channel_moderation_registry_val,
//                 invite_config,
//                 user_registry_val,
//                 user_invite_registry_val,
//                 user_membership_registry_val,
//                 user_fees
//             );
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     fun remove_moderator_admin() {
//         let (
//             mut scenario_val,
//             app,
//             channel_fees,
//             mut channel_registry_val,
//             mut channel_membership_registry_val,
//             mut channel_moderation_registry_val,
//             mut invite_config,
//             mut user_registry_val,
//             mut user_invite_registry_val,
//             mut user_membership_registry_val,
//             user_fees
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         let channel_registry = &mut channel_registry_val;
//         let channel_membership_registry = &mut channel_membership_registry_val;
//         let channel_moderation_registry = &mut channel_moderation_registry_val;
//         let user_registry = &mut user_registry_val;
//         let user_invite_registry = &mut user_invite_registry_val;
//         let user_membership_registry = &mut user_membership_registry_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let mut clock = clock::create_for_testing(ts::ctx(scenario));

//             clock::set_for_testing(&mut clock, 0);
//             clock::share_for_testing(clock);
//         };

//         ts::next_tx(scenario, SERVER);
//         let (clock, server_user_name) = {
//             let clock: Clock = ts::take_shared(scenario);
//             let invite_cap = ts::take_from_sender<InviteCap>(scenario);

//             user_invite::set_invite_config(
//                 &invite_cap,
//                 &mut invite_config,
//                 false
//             );

//             let server_user_name = utf8(b"server-user");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 server_user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             ts::return_to_sender(scenario, invite_cap);

//             (clock, server_user_name)
//         };

//         ts::next_tx(scenario, ADMIN);
//         {
//             let admin_cap = ts::take_from_sender<AdminCap>(scenario);

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 utf8(b"user-name"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let channel_name = utf8(b"channel-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _channel = channel_actions::create(
//                 &clock,
//                 channel_registry,
//                 channel_membership_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             channel_actions::add_moderator_as_admin(
//                 &admin_cap,
//                 channel_moderation_registry,
//                 user_registry,
//                 channel_name,
//                 server_user_name
//             );

//             channel_actions::remove_moderator_as_admin(
//                 &admin_cap,
//                 channel_moderation_registry,
//                 user_registry,
//                 channel_name,
//                 server_user_name
//             );

//             let is_moderator = channel_moderation::is_moderator(
//                 channel_moderation_registry,
//                 channel_name,
//                 SERVER
//             );

//             assert!(!is_moderator, EIsModerator);

//             let moderator_length = channel_moderation::get_moderator_length(
//                 channel_moderation_registry,
//                 channel_name
//             );

//             assert!(moderator_length == 1, EModeratorLengthMismatch);

//             ts::return_to_sender(scenario, admin_cap);
//             ts::return_shared(clock);

//             destroy_for_testing(
//                 app,
//                 channel_fees,
//                 channel_registry_val,
//                 channel_membership_registry_val,
//                 channel_moderation_registry_val,
//                 invite_config,
//                 user_registry_val,
//                 user_invite_registry_val,
//                 user_membership_registry_val,
//                 user_fees
//             );
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     #[expected_failure(abort_code = ENotChannelModerator)]
//     fun remove_moderator_admin_not_moderator() {
//         let (
//             mut scenario_val,
//             app,
//             channel_fees,
//             mut channel_registry_val,
//             mut channel_membership_registry_val,
//             mut channel_moderation_registry_val,
//             mut invite_config,
//             mut user_registry_val,
//             mut user_invite_registry_val,
//             mut user_membership_registry_val,
//             user_fees
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         let channel_registry = &mut channel_registry_val;
//         let channel_membership_registry = &mut channel_membership_registry_val;
//         let channel_moderation_registry = &mut channel_moderation_registry_val;
//         let user_registry = &mut user_registry_val;
//         let user_invite_registry = &mut user_invite_registry_val;
//         let user_membership_registry = &mut user_membership_registry_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let mut clock = clock::create_for_testing(ts::ctx(scenario));

//             clock::set_for_testing(&mut clock, 0);
//             clock::share_for_testing(clock);
//         };

//         ts::next_tx(scenario, SERVER);
//         let (clock, server_user_name) = {
//             let clock: Clock = ts::take_shared(scenario);
//             let invite_cap = ts::take_from_sender<InviteCap>(scenario);

//             user_invite::set_invite_config(
//                 &invite_cap,
//                 &mut invite_config,
//                 false
//             );

//             let server_user_name = utf8(b"server-user");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 server_user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             ts::return_to_sender(scenario, invite_cap);

//             (clock, server_user_name)
//         };

//         ts::next_tx(scenario, ADMIN);
//         {
//             let admin_cap = ts::take_from_sender<AdminCap>(scenario);

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 utf8(b"user-name"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let channel_name = utf8(b"channel-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _channel = channel_actions::create(
//                 &clock,
//                 channel_registry,
//                 channel_membership_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             channel_actions::remove_moderator_as_admin(
//                 &admin_cap,
//                 channel_moderation_registry,
//                 user_registry,
//                 channel_name,
//                 server_user_name
//             );

//             ts::return_to_sender(scenario, admin_cap);
//             ts::return_shared(clock);

//             destroy_for_testing(
//                 app,
//                 channel_fees,
//                 channel_registry_val,
//                 channel_membership_registry_val,
//                 channel_moderation_registry_val,
//                 invite_config,
//                 user_registry_val,
//                 user_invite_registry_val,
//                 user_membership_registry_val,
//                 user_fees
//             );
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     #[expected_failure(abort_code = EChannelModeratorLength)]
//     fun remove_moderator_admin_min_length() {
//         let (
//             mut scenario_val,
//             app,
//             channel_fees,
//             mut channel_registry_val,
//             mut channel_membership_registry_val,
//             mut channel_moderation_registry_val,
//             mut invite_config,
//             mut user_registry_val,
//             mut user_invite_registry_val,
//             mut user_membership_registry_val,
//             user_fees
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         let channel_registry = &mut channel_registry_val;
//         let channel_membership_registry = &mut channel_membership_registry_val;
//         let channel_moderation_registry = &mut channel_moderation_registry_val;
//         let user_registry = &mut user_registry_val;
//         let user_invite_registry = &mut user_invite_registry_val;
//         let user_membership_registry = &mut user_membership_registry_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let mut clock = clock::create_for_testing(ts::ctx(scenario));

//             clock::set_for_testing(&mut clock, 0);
//             clock::share_for_testing(clock);
//         };

//         ts::next_tx(scenario, SERVER);
//         {
//             let invite_cap = ts::take_from_sender<InviteCap>(scenario);

//             user_invite::set_invite_config(
//                 &invite_cap,
//                 &mut invite_config,
//                 false
//             );

//             ts::return_to_sender(scenario, invite_cap);
//         };

//         ts::next_tx(scenario, ADMIN);
//         {
//             let admin_cap = ts::take_from_sender<AdminCap>(scenario);
//             let clock: Clock = ts::take_shared(scenario);

//             let user_name = utf8(b"user-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let channel_name = utf8(b"channel-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _channel = channel_actions::create(
//                 &clock,
//                 channel_registry,
//                 channel_membership_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             channel_actions::remove_moderator_as_admin(
//                 &admin_cap,
//                 channel_moderation_registry,
//                 user_registry,
//                 channel_name,
//                 user_name
//             );

//             ts::return_to_sender(scenario, admin_cap);
//             ts::return_shared(clock);

//             destroy_for_testing(
//                 app,
//                 channel_fees,
//                 channel_registry_val,
//                 channel_membership_registry_val,
//                 channel_moderation_registry_val,
//                 invite_config,
//                 user_registry_val,
//                 user_invite_registry_val,
//                 user_membership_registry_val,
//                 user_fees
//             );
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     fun remove_moderator_owner() {
//         let (
//             mut scenario_val,
//             app,
//             channel_fees,
//             mut channel_registry_val,
//             mut channel_membership_registry_val,
//             mut channel_moderation_registry_val,
//             mut invite_config,
//             mut user_registry_val,
//             mut user_invite_registry_val,
//             mut user_membership_registry_val,
//             user_fees
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         let channel_registry = &mut channel_registry_val;
//         let channel_membership_registry = &mut channel_membership_registry_val;
//         let channel_moderation_registry = &mut channel_moderation_registry_val;
//         let user_registry = &mut user_registry_val;
//         let user_invite_registry = &mut user_invite_registry_val;
//         let user_membership_registry = &mut user_membership_registry_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let mut clock = clock::create_for_testing(ts::ctx(scenario));

//             clock::set_for_testing(&mut clock, 0);
//             clock::share_for_testing(clock);
//         };

//         ts::next_tx(scenario, SERVER);
//         let (clock, server_user_name) = {
//             let clock: Clock = ts::take_shared(scenario);
//             let invite_cap = ts::take_from_sender<InviteCap>(scenario);

//             user_invite::set_invite_config(
//                 &invite_cap,
//                 &mut invite_config,
//                 false
//             );

//             let server_user_name = utf8(b"server-user");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 server_user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             ts::return_to_sender(scenario, invite_cap);

//             (clock, server_user_name)
//         };

//         ts::next_tx(scenario, ADMIN);
//         {
//             let user_name = utf8(b"user-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_fees = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let channel_name = utf8(b"channel-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _channel = channel_actions::create(
//                 &clock,
//                 channel_registry,
//                 channel_membership_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let custom_payment = mint_for_testing<SUI>(
//                 ADD_MODERATOR_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 ADD_MODERATOR_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             channel_actions::add_moderator_as_owner(
//                 channel_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 server_user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let custom_payment = mint_for_testing<SUI>(
//                 REMOVE_MODERATOR_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 REMOVE_MODERATOR_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             channel_actions::remove_moderator_as_owner(
//                 channel_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 server_user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let is_moderator = channel_moderation::is_moderator(
//                 channel_moderation_registry,
//                 channel_name,
//                 SERVER
//             );

//             assert!(!is_moderator, EIsModerator);

//             let moderator_length = channel_moderation::get_moderator_length(
//                 channel_moderation_registry,
//                 channel_name
//             );

//             assert!(moderator_length == 1, EModeratorLengthMismatch);

//             ts::return_shared(clock);

//             destroy_for_testing(
//                 app,
//                 channel_fees,
//                 channel_registry_val,
//                 channel_membership_registry_val,
//                 channel_moderation_registry_val,
//                 invite_config,
//                 user_registry_val,
//                 user_invite_registry_val,
//                 user_membership_registry_val,
//                 user_fees
//             );
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     #[expected_failure(abort_code = EIncorrectCustomPayment)]
//     fun remove_moderator_owner_incorrect_custom_payment() {
//         let (
//             mut scenario_val,
//             app,
//             channel_fees,
//             mut channel_registry_val,
//             mut channel_membership_registry_val,
//             mut channel_moderation_registry_val,
//             mut invite_config,
//             mut user_registry_val,
//             mut user_invite_registry_val,
//             mut user_membership_registry_val,
//             user_fees
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         let channel_registry = &mut channel_registry_val;
//         let channel_membership_registry = &mut channel_membership_registry_val;
//         let channel_moderation_registry = &mut channel_moderation_registry_val;
//         let user_registry = &mut user_registry_val;
//         let user_invite_registry = &mut user_invite_registry_val;
//         let user_membership_registry = &mut user_membership_registry_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let mut clock = clock::create_for_testing(ts::ctx(scenario));

//             clock::set_for_testing(&mut clock, 0);
//             clock::share_for_testing(clock);
//         };

//         ts::next_tx(scenario, SERVER);
//         let (clock, server_user_name) = {
//             let clock: Clock = ts::take_shared(scenario);
//             let invite_cap = ts::take_from_sender<InviteCap>(scenario);

//             user_invite::set_invite_config(
//                 &invite_cap,
//                 &mut invite_config,
//                 false
//             );

//             let server_user_name = utf8(b"server-user");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 server_user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             ts::return_to_sender(scenario, invite_cap);

//             (clock, server_user_name)
//         };

//         ts::next_tx(scenario, ADMIN);
//         {
//             let user_name = utf8(b"user-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let channel_name = utf8(b"channel-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _channel = channel_actions::create(
//                 &clock,
//                 channel_registry,
//                 channel_membership_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let custom_payment = mint_for_testing<SUI>(
//                 ADD_MODERATOR_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 ADD_MODERATOR_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             channel_actions::add_moderator_as_owner(
//                 channel_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 server_user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let custom_payment = mint_for_testing<SUI>(
//                 INCORRECT_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 REMOVE_MODERATOR_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             channel_actions::remove_moderator_as_owner(
//                 channel_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 server_user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             ts::return_shared(clock);

//             destroy_for_testing(
//                 app,
//                 channel_fees,
//                 channel_registry_val,
//                 channel_membership_registry_val,
//                 channel_moderation_registry_val,
//                 invite_config,
//                 user_registry_val,
//                 user_invite_registry_val,
//                 user_membership_registry_val,
//                 user_fees
//             );
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     #[expected_failure(abort_code = EIncorrectSuiPayment)]
//     fun remove_moderator_owner_incorrect_sui_payment() {
//         let (
//             mut scenario_val,
//             app,
//             channel_fees,
//             mut channel_registry_val,
//             mut channel_membership_registry_val,
//             mut channel_moderation_registry_val,
//             mut invite_config,
//             mut user_registry_val,
//             mut user_invite_registry_val,
//             mut user_membership_registry_val,
//             user_fees
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         let channel_registry = &mut channel_registry_val;
//         let channel_membership_registry = &mut channel_membership_registry_val;
//         let channel_moderation_registry = &mut channel_moderation_registry_val;
//         let user_registry = &mut user_registry_val;
//         let user_invite_registry = &mut user_invite_registry_val;
//         let user_membership_registry = &mut user_membership_registry_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let mut clock = clock::create_for_testing(ts::ctx(scenario));

//             clock::set_for_testing(&mut clock, 0);
//             clock::share_for_testing(clock);
//         };

//         ts::next_tx(scenario, SERVER);
//         let (clock, server_user_name) = {
//             let clock: Clock = ts::take_shared(scenario);
//             let invite_cap = ts::take_from_sender<InviteCap>(scenario);

//             user_invite::set_invite_config(
//                 &invite_cap,
//                 &mut invite_config,
//                 false
//             );

//             let server_user_name = utf8(b"server-user");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 server_user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             ts::return_to_sender(scenario, invite_cap);

//             (clock, server_user_name)
//         };

//         ts::next_tx(scenario, ADMIN);
//         {
//             let user_name = utf8(b"user-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let channel_name = utf8(b"channel-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _channel = channel_actions::create(
//                 &clock,
//                 channel_registry,
//                 channel_membership_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let custom_payment = mint_for_testing<SUI>(
//                 ADD_MODERATOR_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 ADD_MODERATOR_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             channel_actions::add_moderator_as_owner(
//                 channel_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 server_user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let custom_payment = mint_for_testing<SUI>(
//                 REMOVE_MODERATOR_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 INCORRECT_FEE,
//                 ts::ctx(scenario)
//             );

//             channel_actions::remove_moderator_as_owner(
//                 channel_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 server_user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             ts::return_shared(clock);

//             destroy_for_testing(
//                 app,
//                 channel_fees,
//                 channel_registry_val,
//                 channel_membership_registry_val,
//                 channel_moderation_registry_val,
//                 invite_config,
//                 user_registry_val,
//                 user_invite_registry_val,
//                 user_membership_registry_val,
//                 user_fees
//             );
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     #[expected_failure(abort_code = ENotChannelOwner)]
//     fun remove_moderator_owner_not_owner() {
//         let (
//             mut scenario_val,
//             app,
//             channel_fees,
//             mut channel_registry_val,
//             mut channel_membership_registry_val,
//             mut channel_moderation_registry_val,
//             mut invite_config,
//             mut user_registry_val,
//             mut user_invite_registry_val,
//             mut user_membership_registry_val,
//             user_fees
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         let channel_registry = &mut channel_registry_val;
//         let channel_membership_registry = &mut channel_membership_registry_val;
//         let channel_moderation_registry = &mut channel_moderation_registry_val;
//         let user_registry = &mut user_registry_val;
//         let user_invite_registry = &mut user_invite_registry_val;
//         let user_membership_registry = &mut user_membership_registry_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let mut clock = clock::create_for_testing(ts::ctx(scenario));

//             clock::set_for_testing(&mut clock, 0);
//             clock::share_for_testing(clock);
//         };

//         ts::next_tx(scenario, SERVER);
//         let (clock, server_user_name) = {
//             let clock: Clock = ts::take_shared(scenario);
//             let invite_cap = ts::take_from_sender<InviteCap>(scenario);

//             user_invite::set_invite_config(
//                 &invite_cap,
//                 &mut invite_config,
//                 false
//             );

//             let server_user_name = utf8(b"server-user");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 server_user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             ts::return_to_sender(scenario, invite_cap);

//             (clock, server_user_name)
//         };

//         ts::next_tx(scenario, ADMIN);
//         let (channel_name, user_name) = {
//             let user_name = utf8(b"user-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let channel_name = utf8(b"channel-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _channel = channel_actions::create(
//                 &clock,
//                 channel_registry,
//                 channel_membership_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let custom_payment = mint_for_testing<SUI>(
//                 ADD_MODERATOR_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 ADD_MODERATOR_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             channel_actions::add_moderator_as_owner(
//                 channel_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 server_user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             (channel_name, user_name)
//         };

//         ts::next_tx(scenario, SERVER);
//         {
//             let custom_payment = mint_for_testing<SUI>(
//                 REMOVE_MODERATOR_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 REMOVE_MODERATOR_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             channel_actions::remove_moderator_as_owner(
//                 channel_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             ts::return_shared(clock);

//             destroy_for_testing(
//                 app,
//                 channel_fees,
//                 channel_registry_val,
//                 channel_membership_registry_val,
//                 channel_moderation_registry_val,
//                 invite_config,
//                 user_registry_val,
//                 user_invite_registry_val,
//                 user_membership_registry_val,
//                 user_fees
//             );
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     #[expected_failure(abort_code = ENotChannelModerator)]
//     fun remove_moderator_owner_not_moderator() {
//         let (
//             mut scenario_val,
//             app,
//             channel_fees,
//             mut channel_registry_val,
//             mut channel_membership_registry_val,
//             mut channel_moderation_registry_val,
//             mut invite_config,
//             mut user_registry_val,
//             mut user_invite_registry_val,
//             mut user_membership_registry_val,
//             user_fees
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         let channel_registry = &mut channel_registry_val;
//         let channel_membership_registry = &mut channel_membership_registry_val;
//         let channel_moderation_registry = &mut channel_moderation_registry_val;
//         let user_registry = &mut user_registry_val;
//         let user_invite_registry = &mut user_invite_registry_val;
//         let user_membership_registry = &mut user_membership_registry_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let mut clock = clock::create_for_testing(ts::ctx(scenario));

//             clock::set_for_testing(&mut clock, 0);
//             clock::share_for_testing(clock);
//         };

//         ts::next_tx(scenario, SERVER);
//         let (clock, server_user_name) = {
//             let clock: Clock = ts::take_shared(scenario);
//             let invite_cap = ts::take_from_sender<InviteCap>(scenario);

//             user_invite::set_invite_config(
//                 &invite_cap,
//                 &mut invite_config,
//                 false
//             );

//             let server_user_name = utf8(b"server-user");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 server_user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             ts::return_to_sender(scenario, invite_cap);

//             (clock, server_user_name)
//         };

//         ts::next_tx(scenario, ADMIN);
//         {
//             let user_name = utf8(b"user-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let channel_name = utf8(b"channel-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _channel = channel_actions::create(
//                 &clock,
//                 channel_registry,
//                 channel_membership_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let custom_payment = mint_for_testing<SUI>(
//                 REMOVE_MODERATOR_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 REMOVE_MODERATOR_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             channel_actions::remove_moderator_as_owner(
//                 channel_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 server_user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             ts::return_shared(clock);

//             destroy_for_testing(
//                 app,
//                 channel_fees,
//                 channel_registry_val,
//                 channel_membership_registry_val,
//                 channel_moderation_registry_val,
//                 invite_config,
//                 user_registry_val,
//                 user_invite_registry_val,
//                 user_membership_registry_val,
//                 user_fees
//             );
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     #[expected_failure(abort_code = EChannelModeratorLength)]
//     fun remove_moderator_owner_min_moderators() {
//         let (
//             mut scenario_val,
//             app,
//             channel_fees,
//             mut channel_registry_val,
//             mut channel_membership_registry_val,
//             mut channel_moderation_registry_val,
//             mut invite_config,
//             mut user_registry_val,
//             mut user_invite_registry_val,
//             mut user_membership_registry_val,
//             user_fees
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         let channel_registry = &mut channel_registry_val;
//         let channel_membership_registry = &mut channel_membership_registry_val;
//         let channel_moderation_registry = &mut channel_moderation_registry_val;
//         let user_registry = &mut user_registry_val;
//         let user_invite_registry = &mut user_invite_registry_val;
//         let user_membership_registry = &mut user_membership_registry_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let mut clock = clock::create_for_testing(ts::ctx(scenario));

//             clock::set_for_testing(&mut clock, 0);
//             clock::share_for_testing(clock);
//         };

//         ts::next_tx(scenario, SERVER);
//         let (clock) = {
//             let clock: Clock = ts::take_shared(scenario);
//             let invite_cap = ts::take_from_sender<InviteCap>(scenario);

//             user_invite::set_invite_config(
//                 &invite_cap,
//                 &mut invite_config,
//                 false
//             );

//             let server_user_name = utf8(b"server-user");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 server_user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             ts::return_to_sender(scenario, invite_cap);

//             (clock)
//         };

//         ts::next_tx(scenario, ADMIN);
//         {
//             let user_name = utf8(b"user-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let channel_name = utf8(b"channel-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _channel = channel_actions::create(
//                 &clock,
//                 channel_registry,
//                 channel_membership_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let custom_payment = mint_for_testing<SUI>(
//                 REMOVE_MODERATOR_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 REMOVE_MODERATOR_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             channel_actions::remove_moderator_as_owner(
//                 channel_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 user_name,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             ts::return_shared(clock);

//             destroy_for_testing(
//                 app,
//                 channel_fees,
//                 channel_registry_val,
//                 channel_membership_registry_val,
//                 channel_moderation_registry_val,
//                 invite_config,
//                 user_registry_val,
//                 user_invite_registry_val,
//                 user_membership_registry_val,
//                 user_fees
//             );
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     fun update_admin() {
//         let (
//             mut scenario_val,
//             app,
//             channel_fees,
//             mut channel_registry_val,
//             mut channel_membership_registry_val,
//             mut channel_moderation_registry_val,
//             mut invite_config,
//             mut user_registry_val,
//             mut user_invite_registry_val,
//             mut user_membership_registry_val,
//             user_fees
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         let channel_registry = &mut channel_registry_val;
//         let channel_membership_registry = &mut channel_membership_registry_val;
//         let channel_moderation_registry = &mut channel_moderation_registry_val;
//         let user_registry = &mut user_registry_val;
//         let user_invite_registry = &mut user_invite_registry_val;
//         let user_membership_registry = &mut user_membership_registry_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let mut clock = clock::create_for_testing(ts::ctx(scenario));

//             clock::set_for_testing(&mut clock, 0);
//             clock::share_for_testing(clock);
//         };

//         ts::next_tx(scenario, SERVER);
//         {
//             let invite_cap = ts::take_from_sender<InviteCap>(scenario);

//             user_invite::set_invite_config(
//                 &invite_cap,
//                 &mut invite_config,
//                 false
//             );

//             ts::return_to_sender(scenario, invite_cap);
//         };

//         ts::next_tx(scenario, ADMIN);
//         {
//             let clock: Clock = ts::take_shared(scenario);
//             let admin_cap = ts::take_from_sender<AdminCap>(scenario);

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 utf8(b"user-name"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let avatar_hash = utf8(b"avatar_hash");
//             let banner_hash = utf8(b"banner_hash");
//             let description = utf8(b"description");

//             let channel_name = utf8(b"channel-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let channel = channel_actions::create(
//                 &clock,
//                 channel_registry,
//                 channel_membership_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 avatar_hash,
//                 banner_hash,
//                 description,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let channel_avatar_hash = channel::get_avatar(
//                 channel
//             );

//             assert!(channel_avatar_hash == avatar_hash, EChannelAvatarMismatch);

//             let channel_banner_hash = channel::get_banner(
//                 channel
//             );

//             assert!(channel_banner_hash == banner_hash, EChannelBannerMismatch);

//             let channel_description = channel::get_description(
//                 channel
//             );

//             assert!(channel_description == description, EChannelDescriptionMismatch);

//             let name = channel::get_name(
//                 channel
//             );

//             assert!(channel_name == name, ETestChannelNameMismatch);

//             let new_avatar_hash = utf8(b"new_avatar_hash");
//             let new_banner_hash = utf8(b"new_banner_hash");
//             let new_description = utf8(b"new_description");
//             let new_name = utf8(b"CHANNEL-NAME");

//             channel_actions::update_channel_as_admin(
//                 &admin_cap,
//                 &clock,
//                 channel_registry,
//                 channel_name,
//                 new_avatar_hash,
//                 new_banner_hash,
//                 new_description,
//                 new_name
//             );

//             let channel = channel_registry::borrow_channel(
//                 channel_registry,
//                 channel_name
//             );

//             let channel_avatar_hash = channel::get_avatar(
//                 channel
//             );

//             assert!(channel_avatar_hash == new_avatar_hash, EChannelAvatarMismatch);

//             let channel_banner_hash = channel::get_banner(
//                 channel
//             );

//             assert!(channel_banner_hash == new_banner_hash, EChannelBannerMismatch);

//             let channel_description = channel::get_description(
//                 channel
//             );

//             assert!(channel_description == new_description, EChannelDescriptionMismatch);

//             let name = channel::get_name(
//                 channel
//             );

//             assert!(name == new_name, ETestChannelNameMismatch);

//             ts::return_shared(clock);
//             ts::return_to_sender(scenario, admin_cap);

//             destroy_for_testing(
//                 app,
//                 channel_fees,
//                 channel_registry_val,
//                 channel_membership_registry_val,
//                 channel_moderation_registry_val,
//                 invite_config,
//                 user_registry_val,
//                 user_invite_registry_val,
//                 user_membership_registry_val,
//                 user_fees
//             );
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     #[expected_failure(abort_code = EChannelNameMismatch)]
//     fun update_admin_name_mismatch() {
//         let (
//             mut scenario_val,
//             app,
//             channel_fees,
//             mut channel_registry_val,
//             mut channel_membership_registry_val,
//             mut channel_moderation_registry_val,
//             mut invite_config,
//             mut user_registry_val,
//             mut user_invite_registry_val,
//             mut user_membership_registry_val,
//             user_fees
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         let channel_registry = &mut channel_registry_val;
//         let channel_membership_registry = &mut channel_membership_registry_val;
//         let channel_moderation_registry = &mut channel_moderation_registry_val;
//         let user_registry = &mut user_registry_val;
//         let user_invite_registry = &mut user_invite_registry_val;
//         let user_membership_registry = &mut user_membership_registry_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let mut clock = clock::create_for_testing(ts::ctx(scenario));

//             clock::set_for_testing(&mut clock, 0);
//             clock::share_for_testing(clock);
//         };

//         ts::next_tx(scenario, SERVER);
//         {
//             let invite_cap = ts::take_from_sender<InviteCap>(scenario);

//             user_invite::set_invite_config(
//                 &invite_cap,
//                 &mut invite_config,
//                 false
//             );

//             ts::return_to_sender(scenario, invite_cap);
//         };

//         ts::next_tx(scenario, ADMIN);
//         {
//             let clock: Clock = ts::take_shared(scenario);
//             let admin_cap = ts::take_from_sender<AdminCap>(scenario);

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 utf8(b"user-name"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let avatar_hash = utf8(b"avatar_hash");
//             let banner_hash = utf8(b"banner_hash");
//             let description = utf8(b"description");

//             let channel_name = utf8(b"channel-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let channel = channel_actions::create(
//                 &clock,
//                 channel_registry,
//                 channel_membership_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 avatar_hash,
//                 banner_hash,
//                 description,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let channel_name = channel::get_name(
//                 channel
//             );

//             assert!(channel_name == channel_name, ETestChannelNameMismatch);

//             let new_name = utf8(b"new_name");
            
//             channel_actions::update_channel_as_admin(
//                 &admin_cap,
//                 &clock,
//                 channel_registry,
//                 channel_name,
//                 avatar_hash,
//                 banner_hash,
//                 description,
//                 new_name
//             );

//             let channel = channel_registry::borrow_channel(
//                 channel_registry,
//                 channel_name
//             );

//             let channel_name = channel::get_name(
//                 channel
//             );

//             assert!(channel_name == new_name, ETestChannelNameMismatch);

//             ts::return_shared(clock);
//             ts::return_to_sender(scenario, admin_cap);

//             destroy_for_testing(
//                 app,
//                 channel_fees,
//                 channel_registry_val,
//                 channel_membership_registry_val,
//                 channel_moderation_registry_val,
//                 invite_config,
//                 user_registry_val,
//                 user_invite_registry_val,
//                 user_membership_registry_val,
//                 user_fees
//             );
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     fun update_owner_owned() {
//         let (
//             mut scenario_val,
//             app,
//             channel_fees,
//             mut channel_registry_val,
//             mut channel_membership_registry_val,
//             mut channel_moderation_registry_val,
//             mut invite_config,
//             mut user_registry_val,
//             mut user_invite_registry_val,
//             mut user_membership_registry_val,
//             user_fees
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         let channel_registry = &mut channel_registry_val;
//         let channel_membership_registry = &mut channel_membership_registry_val;
//         let channel_moderation_registry = &mut channel_moderation_registry_val;
//         let user_registry = &mut user_registry_val;
//         let user_invite_registry = &mut user_invite_registry_val;
//         let user_membership_registry = &mut user_membership_registry_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let mut clock = clock::create_for_testing(ts::ctx(scenario));

//             clock::set_for_testing(&mut clock, 0);
//             clock::share_for_testing(clock);
//         };

//         ts::next_tx(scenario, SERVER);
//         {
//             let invite_cap = ts::take_from_sender<InviteCap>(scenario);

//             user_invite::set_invite_config(
//                 &invite_cap,
//                 &mut invite_config,
//                 false
//             );

//             ts::return_to_sender(scenario, invite_cap);
//         };

//         ts::next_tx(scenario, ADMIN);
//         {
//             let clock: Clock = ts::take_shared(scenario);

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 utf8(b"user-name"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let avatar_hash = utf8(b"avatar_hash");
//             let banner_hash = utf8(b"banner_hash");
//             let description = utf8(b"description");

//             let channel_name = utf8(b"channel-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let channel = channel_actions::create(
//                 &clock,
//                 channel_registry,
//                 channel_membership_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 avatar_hash,
//                 banner_hash,
//                 description,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let channel_avatar_hash = channel::get_avatar(
//                 channel
//             );

//             assert!(channel_avatar_hash == avatar_hash, EChannelAvatarMismatch);

//             let new_avatar_hash = utf8(b"new_avatar_hash");
//             let new_banner_hash = utf8(b"new_banner_hash");
//             let new_description = utf8(b"new_description");
//             let new_name = utf8(b"CHANNEL-NAME");

//             let custom_payment = mint_for_testing<SUI>(
//                 UPDATE_CHANNEL_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 UPDATE_CHANNEL_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             channel_actions::update_channel_as_owner(
//                 &clock,
//                 channel_registry,
//                 &channel_fees,
//                 channel_name,
//                 new_avatar_hash,
//                 new_banner_hash,
//                 new_name,
//                 new_description,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let channel = channel_registry::borrow_channel(
//                 channel_registry,
//                 channel_name
//             );

//             let channel_avatar_hash = channel::get_avatar(
//                 channel
//             );

//             assert!(channel_avatar_hash == new_avatar_hash, EChannelAvatarMismatch);

//             let channel_banner_hash = channel::get_banner(
//                 channel
//             );

//             assert!(channel_banner_hash == new_banner_hash, EChannelBannerMismatch);

//             let channel_description = channel::get_description(
//                 channel
//             );

//             assert!(channel_description == new_description, EChannelDescriptionMismatch);

//             let channel_name = channel::get_name(
//                 channel
//             );

//             assert!(channel_name == new_name, ETestChannelNameMismatch);

//             ts::return_shared(clock);

//             destroy_for_testing(
//                 app,
//                 channel_fees,
//                 channel_registry_val,
//                 channel_membership_registry_val,
//                 channel_moderation_registry_val,
//                 invite_config,
//                 user_registry_val,
//                 user_invite_registry_val,
//                 user_membership_registry_val,
//                 user_fees
//             );
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     #[expected_failure(abort_code = EIncorrectCustomPayment)]
//     fun update_owner_owned_incorrect_custom_payment() {
//         let (
//             mut scenario_val,
//             app,
//             channel_fees,
//             mut channel_registry_val,
//             mut channel_membership_registry_val,
//             mut channel_moderation_registry_val,
//             mut invite_config,
//             mut user_registry_val,
//             mut user_invite_registry_val,
//             mut user_membership_registry_val,
//             user_fees
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         let channel_registry = &mut channel_registry_val;
//         let channel_membership_registry = &mut channel_membership_registry_val;
//         let channel_moderation_registry = &mut channel_moderation_registry_val;
//         let user_registry = &mut user_registry_val;
//         let user_invite_registry = &mut user_invite_registry_val;
//         let user_membership_registry = &mut user_membership_registry_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let mut clock = clock::create_for_testing(ts::ctx(scenario));

//             clock::set_for_testing(&mut clock, 0);
//             clock::share_for_testing(clock);
//         };

//         ts::next_tx(scenario, SERVER);
//         {
//             let invite_cap = ts::take_from_sender<InviteCap>(scenario);

//             user_invite::set_invite_config(
//                 &invite_cap,
//                 &mut invite_config,
//                 false
//             );

//             ts::return_to_sender(scenario, invite_cap);
//         };

//         ts::next_tx(scenario, ADMIN);
//         {
//             let clock: Clock = ts::take_shared(scenario);

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 utf8(b"user-name"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let avatar_hash = utf8(b"avatar_hash");
//             let banner_hash = utf8(b"banner_hash");
//             let description = utf8(b"description");

//             let channel_name = utf8(b"channel-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let channel = channel_actions::create(
//                 &clock,
//                 channel_registry,
//                 channel_membership_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 avatar_hash,
//                 banner_hash,
//                 description,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let channel_avatar_hash = channel::get_avatar(
//                 channel
//             );

//             assert!(channel_avatar_hash == avatar_hash, EChannelAvatarMismatch);

//             let new_avatar_hash = utf8(b"new_avatar_hash");
//             let new_banner_hash = utf8(b"new_banner_hash");
//             let new_description = utf8(b"new_description");
//             let new_name = utf8(b"CHANNEL-NAME");

//             let custom_payment = mint_for_testing<SUI>(
//                 INCORRECT_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 UPDATE_CHANNEL_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             channel_actions::update_channel_as_owner(
//                 &clock,
//                 channel_registry,
//                 &channel_fees,
//                 channel_name,
//                 new_avatar_hash,
//                 new_banner_hash,
//                 new_name,
//                 new_description,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             ts::return_shared(clock);

//             destroy_for_testing(
//                 app,
//                 channel_fees,
//                 channel_registry_val,
//                 channel_membership_registry_val,
//                 channel_moderation_registry_val,
//                 invite_config,
//                 user_registry_val,
//                 user_invite_registry_val,
//                 user_membership_registry_val,
//                 user_fees
//             );
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     #[expected_failure(abort_code = EIncorrectSuiPayment)]
//     fun update_owner_owned_incorrect_sui_payment() {
//         let (
//             mut scenario_val,
//             app,
//             channel_fees,
//             mut channel_registry_val,
//             mut channel_membership_registry_val,
//             mut channel_moderation_registry_val,
//             mut invite_config,
//             mut user_registry_val,
//             mut user_invite_registry_val,
//             mut user_membership_registry_val,
//             user_fees
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         let channel_registry = &mut channel_registry_val;
//         let channel_membership_registry = &mut channel_membership_registry_val;
//         let channel_moderation_registry = &mut channel_moderation_registry_val;
//         let user_registry = &mut user_registry_val;
//         let user_invite_registry = &mut user_invite_registry_val;
//         let user_membership_registry = &mut user_membership_registry_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let mut clock = clock::create_for_testing(ts::ctx(scenario));

//             clock::set_for_testing(&mut clock, 0);
//             clock::share_for_testing(clock);
//         };

//         ts::next_tx(scenario, SERVER);
//         {
//             let invite_cap = ts::take_from_sender<InviteCap>(scenario);

//             user_invite::set_invite_config(
//                 &invite_cap,
//                 &mut invite_config,
//                 false
//             );

//             ts::return_to_sender(scenario, invite_cap);
//         };

//         ts::next_tx(scenario, ADMIN);
//         {
//             let clock: Clock = ts::take_shared(scenario);

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 utf8(b"user-name"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let avatar_hash = utf8(b"avatar_hash");
//             let banner_hash = utf8(b"banner_hash");
//             let description = utf8(b"description");

//             let channel_name = utf8(b"channel-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let channel = channel_actions::create(
//                 &clock,
//                 channel_registry,
//                 channel_membership_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 avatar_hash,
//                 banner_hash,
//                 description,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let channel_avatar_hash = channel::get_avatar(
//                 channel
//             );

//             assert!(channel_avatar_hash == avatar_hash, EChannelAvatarMismatch);

//             let new_avatar_hash = utf8(b"new_avatar_hash");
//             let new_banner_hash = utf8(b"new_banner_hash");
//             let new_description = utf8(b"new_description");
//             let new_name = utf8(b"CHANNEL-NAME");

//             let custom_payment = mint_for_testing<SUI>(
//                 UPDATE_CHANNEL_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 INCORRECT_FEE,
//                 ts::ctx(scenario)
//             );

//             channel_actions::update_channel_as_owner(
//                 &clock,
//                 channel_registry,
//                 &channel_fees,
//                 channel_name,
//                 new_avatar_hash,
//                 new_banner_hash,
//                 new_name,
//                 new_description,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             ts::return_shared(clock);

//             destroy_for_testing(
//                 app,
//                 channel_fees,
//                 channel_registry_val,
//                 channel_membership_registry_val,
//                 channel_moderation_registry_val,
//                 invite_config,
//                 user_registry_val,
//                 user_invite_registry_val,
//                 user_membership_registry_val,
//                 user_fees
//             );
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     #[expected_failure(abort_code = ENotChannelModerator)]
//     fun update_owner_unowned() {
//         let (
//             mut scenario_val,
//             app,
//             channel_fees,
//             mut channel_registry_val,
//             mut channel_membership_registry_val,
//             mut channel_moderation_registry_val,
//             mut invite_config,
//             mut user_registry_val,
//             mut user_invite_registry_val,
//             mut user_membership_registry_val,
//             user_fees
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         let channel_registry = &mut channel_registry_val;
//         let channel_membership_registry = &mut channel_membership_registry_val;
//         let channel_moderation_registry = &mut channel_moderation_registry_val;
//         let user_registry = &mut user_registry_val;
//         let user_invite_registry = &mut user_invite_registry_val;
//         let user_membership_registry = &mut user_membership_registry_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let mut clock = clock::create_for_testing(ts::ctx(scenario));

//             clock::set_for_testing(&mut clock, 0);
//             clock::share_for_testing(clock);
//         };

//         ts::next_tx(scenario, SERVER);
//         {
//             let invite_cap = ts::take_from_sender<InviteCap>(scenario);

//             user_invite::set_invite_config(
//                 &invite_cap,
//                 &mut invite_config,
//                 false
//             );

//             ts::return_to_sender(scenario, invite_cap);
//         };

//         ts::next_tx(scenario, ADMIN);
//         let (clock, channel_name) = {
//             let clock: Clock = ts::take_shared(scenario);

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 utf8(b"user-name"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let avatar_hash = utf8(b"avatar_hash");
//             let banner_hash = utf8(b"banner_hash");
//             let description = utf8(b"description");

//             let channel_name = utf8(b"channel-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _channel = channel_actions::create(
//                 &clock,
//                 channel_registry,
//                 channel_membership_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 avatar_hash,
//                 banner_hash,
//                 description,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             (clock, channel_name)
//         };

//         ts::next_tx(scenario, SERVER);
//         {

//             let new_avatar_hash = utf8(b"new_avatar_hash");
//             let new_banner_hash = utf8(b"new_banner_hash");
//             let new_description = utf8(b"new_description");
//             let new_name = utf8(b"CHANNEL-NAME");

//             let custom_payment = mint_for_testing<SUI>(
//                 UPDATE_CHANNEL_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 UPDATE_CHANNEL_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             channel_actions::update_channel_as_owner(
//                 &clock,
//                 channel_registry,
//                 &channel_fees,
//                 channel_name,
//                 new_avatar_hash,
//                 new_banner_hash,
//                 new_name,
//                 new_description,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             ts::return_shared(clock);

//             destroy_for_testing(
//                 app,
//                 channel_fees,
//                 channel_registry_val,
//                 channel_membership_registry_val,
//                 channel_moderation_registry_val,
//                 invite_config,
//                 user_registry_val,
//                 user_invite_registry_val,
//                 user_membership_registry_val,
//                 user_fees
//             );
//         };

//         ts::end(scenario_val);
//     }

//     #[test]
//     #[expected_failure(abort_code = EChannelNameMismatch)]
//     fun update_name_owner_owned_mismatch() {
//         let (
//             mut scenario_val,
//             app,
//             channel_fees,
//             mut channel_registry_val,
//             mut channel_membership_registry_val,
//             mut channel_moderation_registry_val,
//             mut invite_config,
//             mut user_registry_val,
//             mut user_invite_registry_val,
//             mut user_membership_registry_val,
//             user_fees
//         ) = setup_for_testing();

//         let scenario = &mut scenario_val;

//         let channel_registry = &mut channel_registry_val;
//         let channel_membership_registry = &mut channel_membership_registry_val;
//         let channel_moderation_registry = &mut channel_moderation_registry_val;
//         let user_registry = &mut user_registry_val;
//         let user_invite_registry = &mut user_invite_registry_val;
//         let user_membership_registry = &mut user_membership_registry_val;

//         ts::next_tx(scenario, ADMIN);
//         {
//             let mut clock = clock::create_for_testing(ts::ctx(scenario));

//             clock::set_for_testing(&mut clock, 0);
//             clock::share_for_testing(clock);
//         };

//         ts::next_tx(scenario, SERVER);
//         {
//             let invite_cap = ts::take_from_sender<InviteCap>(scenario);

//             user_invite::set_invite_config(
//                 &invite_cap,
//                 &mut invite_config,
//                 false
//             );

//             ts::return_to_sender(scenario, invite_cap);
//         };

//         ts::next_tx(scenario, ADMIN);
//         {
//             let clock: Clock = ts::take_shared(scenario);
//             let admin_cap = ts::take_from_sender<AdminCap>(scenario);

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_USER_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_USER_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let _user_address = user_actions::create(
//                 &clock,
//                 user_registry,
//                 user_invite_registry,
//                 user_membership_registry,
//                 &user_fees,
//                 &invite_config,
//                 utf8(b""),
//                 utf8(b""),
//                 utf8(b"avatar_hash"),
//                 utf8(b"banner_hash"),
//                 utf8(b"description"),
//                 utf8(b"user-name"),
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let avatar_hash = utf8(b"avatar_hash");
//             let banner_hash = utf8(b"banner_hash");
//             let description = utf8(b"description");

//             let channel_name = utf8(b"channel-name");

//             let custom_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 CREATE_CHANNEL_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             let channel = channel_actions::create(
//                 &clock,
//                 channel_registry,
//                 channel_membership_registry,
//                 channel_moderation_registry,
//                 user_registry,
//                 &channel_fees,
//                 channel_name,
//                 avatar_hash,
//                 banner_hash,
//                 description,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let channel_name = channel::get_name(
//                 channel
//             );

//             assert!(channel_name == channel_name, ETestChannelNameMismatch);

//             let new_name = utf8(b"new_name");

//             let custom_payment = mint_for_testing<SUI>(
//                 UPDATE_CHANNEL_CUSTOM_FEE,
//                 ts::ctx(scenario)
//             );
//             let sui_payment = mint_for_testing<SUI>(
//                 UPDATE_CHANNEL_SUI_FEE,
//                 ts::ctx(scenario)
//             );

//             channel_actions::update_channel_as_owner(
//                 &clock,
//                 channel_registry,
//                 &channel_fees,
//                 channel_name,
//                 avatar_hash,
//                 banner_hash,
//                 new_name,
//                 description,
//                 custom_payment,
//                 sui_payment,
//                 ts::ctx(scenario)
//             );

//             let channel_name = channel::get_name(
//                 channel
//             );

//             assert!(channel_name == new_name, ETestChannelNameMismatch);

//             ts::return_shared(clock);
//             ts::return_to_sender(scenario, admin_cap);

//             destroy_for_testing(
//                 app,
//                 channel_fees,
//                 channel_registry_val,
//                 channel_membership_registry_val,
//                 channel_moderation_registry_val,
//                 invite_config,
//                 user_registry_val,
//                 user_invite_registry_val,
//                 user_membership_registry_val,
//                 user_fees
//             );
//         };

//         ts::end(scenario_val);
//     }
// }
