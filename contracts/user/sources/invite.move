module sage_user::user_invite {
    use std::hash::{sha3_256};
    use std::string::{String, into_bytes, utf8};

    use sui::event;
    use sui::table::{Self, Table};

    use sage_admin::{
        admin::{AdminCap, InviteCap}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EInviteCodeExists: u64 = 370;

    // --------------- Name Tag ---------------

    public struct Invite has copy, drop, store {
        hash: vector<u8>,
        user: address
    }

    public struct InviteConfig has store {
        required: bool
    }

    public struct UserInviteRegistry has store {
        registry: Table<String, Invite>
    }

    // --------------- Events ---------------

    public struct InviteDeleted has copy, drop {
        invite_key: String
    }

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun create_invite_config(
        _: &AdminCap
    ): InviteConfig {
        InviteConfig {
            required: false
        }
    }

    public fun create_invite_registry(
        _: &AdminCap,
        ctx: &mut TxContext
    ): UserInviteRegistry {
        UserInviteRegistry {
            registry: table::new(ctx)
        }
    }

    public fun get_destructured_invite(
        user_invite_registry: &mut UserInviteRegistry,
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
        user: address
    ) {
        let has_record = has_record(
            user_invite_registry,
            invite_key
        );

        assert!(!has_record, EInviteCodeExists);

        let invite = Invite {
            hash: invite_hash,
            user
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
    public fun destroy_for_testing(
        user_invite_registry: UserInviteRegistry
    ) {
        let UserInviteRegistry {
            registry,
        } = user_invite_registry;

        registry.drop();
    }
}
