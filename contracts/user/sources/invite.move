module sage_user::user_invite {
    use std::{
        hash::{sha3_256},
        string::{String, into_bytes, utf8}
    };

    use sui::{
        event,
        package::{claim_and_keep},
        table::{Self, Table}
    };

    use sage_admin::{
        admin::{InviteCap}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EInviteDoesNotExist: u64 = 370;
    const EInviteInvalid: u64 = 371;
    const EInviteNotAllowed: u64 = 372;

    // --------------- Name Tag ---------------

    public struct Invite has copy, drop, store {
        hash: vector<u8>,
        user: address
    }

    public struct InviteConfig has key {
        id: UID,
        required: bool
    }

    public struct UserInviteRegistry has key {
        id: UID,
        registry: Table<String, Invite>
    }

    public struct USER_INVITE has drop {}

    // --------------- Events ---------------

    public struct InviteDeleted has copy, drop {
        invite_key: String
    }

    // --------------- Constructor ---------------

    fun init(
        otw: USER_INVITE,
        ctx: &mut TxContext
    ) {
        claim_and_keep(otw, ctx);

        let invite_config = InviteConfig {
            id: object::new(ctx),
            required: false
        };

        let user_invite_registry = UserInviteRegistry {
            id: object::new(ctx),
            registry: table::new(ctx)
        };

        transfer::share_object(invite_config);
        transfer::share_object(user_invite_registry);
    }

    // --------------- Public Functions ---------------

    public fun assert_invite_exists(
        user_invite_registry: &UserInviteRegistry,
        invite_key: String
    ) {
        let has_record = has_record(
            user_invite_registry,
            invite_key
        );

        assert!(has_record, EInviteDoesNotExist);
    }

    public fun assert_invite_not_required(
        invite_config: &InviteConfig
    ) {
        let is_invite_required = is_invite_required(
            invite_config
        );

        assert!(!is_invite_required, EInviteNotAllowed);
    }

    public fun assert_invite_is_valid(
        invite_code: String,
        invite_key: String,
        invite_hash: vector<u8>
    ) {
        let is_invite_valid = is_invite_valid(
            invite_code,
            invite_key,
            invite_hash
        );

        assert!(is_invite_valid, EInviteInvalid);
    }

    public fun get_destructured_invite(
        user_invite_registry: &UserInviteRegistry,
        invite_key: String
    ): (vector<u8>, address) {
        let invite = *user_invite_registry.registry.borrow(invite_key);

        let Invite {
            hash,
            user
        } = invite;

        (hash, user)
    }

    public fun has_record(
        user_invite_registry: &UserInviteRegistry,
        invite_key: String
    ): bool {
        user_invite_registry.registry.contains(invite_key)
    }

    public fun is_invite_required(
        invite_config: &InviteConfig
    ): bool {
        invite_config.required
    }

    public fun is_invite_valid(
        invite_code: String,
        invite_key: String,
        invite_hash: vector<u8>
    ): bool {
        let mut combined = utf8(b"");

        combined.append(invite_code);
        combined.append(invite_key);

        let bytes = into_bytes(combined);

        let computed_hash_bytes = sha3_256(bytes);

        let computed_length = computed_hash_bytes.length();
        let provided_length = invite_hash.length();

        if (computed_length != provided_length) {
            return false
        };

        let mut index = 0;

        while (index < computed_length) {
            if (computed_hash_bytes[index] != invite_hash[index]) {
                return false
            };

            index = index + 1;
        };

        true
    }

    public fun set_invite_config(
        _: &InviteCap,
        invite_config: &mut InviteConfig,
        required: bool
    ) {
        invite_config.required = required;
    }

    // --------------- Friend Functions ---------------

    public(package) fun create_invite(
        user_invite_registry: &mut UserInviteRegistry,
        invite_hash: vector<u8>,
        invite_key: String,
        wallet_address: address
    ) {
        let invite = Invite {
            hash: invite_hash,
            user: wallet_address
        };

        user_invite_registry.registry.add(invite_key, invite);
    }

    public(package) fun delete_invite(
        user_invite_registry: &mut UserInviteRegistry,
        invite_key: String
    ) {
        user_invite_registry.registry.remove<String, Invite>(invite_key);

        event::emit(InviteDeleted {
            invite_key
        });
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(USER_INVITE {}, ctx);
    }
}
