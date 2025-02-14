// ideas on handling invites / gated communities


// public struct Channel has key {
//     id: UID,
//     avatar_hash: String,
//     banner_hash: String,
//     created_at: u64,
//     created_by: address,
//     description: String,
//     name: String,
//     updated_at: u64,
//     // Add privacy setting
//     is_private: bool
// }

// module sage_channel::channel_invites {
//     use std::string::{String};
//     use sui::{table::{Self, Table}};

//     struct ChannelInvites has key {
//         id: UID,
//         // Maps user addresses to a bool indicating if they're invited
//         invites: Table<address, bool>
//     }

//     // Map channel keys to their invite records
//     struct ChannelInviteRegistry has key {
//         id: UID,
//         registry: Table<String, address>
//     }

//     public(package) fun create(
//         channel_invite_registry: &mut ChannelInviteRegistry,
//         channel_key: String,
//         ctx: &mut TxContext
//     ): address {
//         let channel_invites = ChannelInvites {
//             id: object::new(ctx),
//             invites: table::new(ctx)
//         };
        
//         let channel_invites_address = channel_invites.id.to_address();
        
//         channel_invite_registry.registry.add(
//             channel_key,
//             channel_invites_address
//         );
        
//         transfer::share_object(channel_invites);
//         channel_invites_address
//     }

//     public(package) fun add_invite(
//         channel_invites: &mut ChannelInvites,
//         user_address: address,
//     ) {
//         channel_invites.invites.add(user_address, true)
//     }

//     public(package) fun has_invite(
//         channel_invites: &ChannelInvites,
//         user_address: address
//     ): bool {
//         channel_invites.invites.contains(user_address)
//     }
// }

// fun join_channel(
//     channel_membership: &mut ChannelMembership,
//     channel_invites: &ChannelInvites,
//     channel: &Channel,
//     user_address: address,
//     ctx: &mut TxContext
// ) {
//     let is_member = is_member(
//         channel_membership,
//         user_address
//     );
//     assert!(!is_member, EChannelMemberExists);

//     // If channel is private, verify invite
//     if (channel.is_private) {
//         let has_invite = channel_invites::has_invite(
//             channel_invites,
//             user_address
//         );
//         assert!(has_invite, ENoChannelInvite);
//     };

//     // Rest of join logic...
// }

// public fun invite_user<CoinType>(
//     channel_moderation_registry: &ChannelModerationRegistry,
//     channel: &Channel,
//     channel_moderation: &ChannelModeration,
//     channel_invites: &mut ChannelInvites,
//     channel_fees: &ChannelFees,
//     user_address: address,
//     custom_payment: Coin<CoinType>,
//     sui_payment: Coin<SUI>,
//     ctx: &mut TxContext
// ) {
//     // Verify caller is moderator
//     let self = tx_context::sender(ctx);
//     assert!(channel_moderation::is_moderator(
//         channel_moderation,
//         self
//     ), ENotModerator);

//     // Verify payments
//     let (custom_payment, sui_payment) = channel_fees::assert_invite_user_payment(
//         channel_fees,
//         custom_payment,
//         sui_payment
//     );

//     fees::collect_payment<CoinType>(
//         custom_payment,
//         sui_payment
//     );

//     channel_invites::add_invite(
//         channel_invites,
//         user_address
//     );

//     // Emit event for the invite
//     event::emit(ChannelInviteCreated {
//         channel_key: channel.get_key(),
//         invited_user: user_address,
//         invited_by: self
//     });
// }







// // ******************************************
// // ******************************************
// // ******************************************







// public struct Channel has key {
//     id: UID,
//     avatar_hash: String,
//     banner_hash: String,
//     created_at: u64,
//     created_by: address,
//     description: String,
//     name: String,
//     updated_at: u64,
//     // Add NFT gating fields
//     is_nft_gated: bool,
//     nft_collection_id: Option<ID>  // The collection type ID
// }

// module sage_channel::channel_nft_gate {
//     use sui::dynamic_field;
//     use sui::object::{Self, ID};
//     use sui::transfer_policy::{Self as policy, TransferPolicy};
//     use sui::kiosk::{Self, Kiosk, KioskOwnerCap};

//     public(package) fun verify_nft_ownership(
//         user_address: address,
//         collection_id: ID,
//     ): bool {
//         // First check if they have NFTs in their kiosk
//         if (kiosk::has_item(user_kiosk, collection_id)) {
//             return true
//         };

//         // Could also check direct ownership
//         if (object::is_owner(collection_id, user_address)) {
//             return true
//         };

//         false
//     }
// }

// fun join_channel(
//     channel_membership: &mut ChannelMembership,
//     channel: &Channel,
//     user_address: address,
//     ctx: &mut TxContext
// ) {
//     let is_member = is_member(
//         channel_membership,
//         user_address
//     );
//     assert!(!is_member, EChannelMemberExists);

//     // If channel is NFT gated, verify ownership
//     if (channel.is_nft_gated) {
//         let collection_id = option::extract(&channel.nft_collection_id);
//         let has_nft = channel_nft_gate::verify_nft_ownership(
//             user_address,
//             collection_id
//         );
//         assert!(has_nft, ENftOwnershipRequired);
//     };

//     // Rest of join logic...
// }

// // Add to relevant channel interaction functions
// fun verify_continued_membership(
//     channel: &Channel,
//     channel_membership: &mut ChannelMembership,
//     user_address: address,
// ) {
//     if (channel.is_nft_gated) {
//         let collection_id = option::extract(&channel.nft_collection_id);
//         let still_owns_nft = channel_nft_gate::verify_nft_ownership(
//             user_address, 
//             collection_id
//         );
        
//         if (!still_owns_nft) {
//             // Remove their membership
//             channel_membership::leave(
//                 channel_membership,
//                 user_address
//             );
            
//             event::emit(ChannelMembershipUpdate {
//                 channel_key: channel.get_key(),
//                 message: CHANNEL_LEAVE,
//                 user: user_address,
//                 reason: NFT_SOLD
//             });
//         };
//     };
// }

// public fun verify_member_ownership(
//     channel: &Channel,
//     channel_membership: &mut ChannelMembership,
//     user_address: address,
//     ctx: &mut TxContext
// ) {
//     // Verify caller is moderator
//     let self = tx_context::sender(ctx);
//     assert!(channel_moderation::is_moderator(channel_moderation, self), ENotModerator);
    
//     verify_continued_membership(channel, channel_membership, user_address);
// }
