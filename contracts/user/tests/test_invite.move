#[test_only]
module sage_user::test_user_invite {
    use std::string::{utf8};

    use sui::{
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy}
    };

    use sage_admin::{admin::{Self, InviteCap}};

    use sage_user::{user_invite::{Self, InviteConfig, UserInviteRegistry}};

    // --------------- Constants ---------------

    const ADMIN: address = @admin;
    const OTHER: address = @0xBABE;
    const SERVER: address = @server;

    // --------------- Errors ---------------

    const EConfigMismatch: u64 = 0;
    const EInvalidHashLength: u64 = 1;
    const EInvalidHexCharacter: u64 = 2;
    const EInviteInvalid: u64 = 3;
    const EInviteRecord: u64 = 4;

    // --------------- Test Functions ---------------

    #[test_only]
    public fun create_hash_array(
        hash: vector<u8>
    ): vector<u8> {
        assert!(hash.length() == 64, EInvalidHashLength);

        let mut index = 0;
        let mut bytes = vector::empty<u8>();

        while (index < hash.length()) {
            let first = convert_hex_char(hash[index]);
            let second = convert_hex_char(hash[index + 1]);

            let val = (first << 4) | second;

            bytes.push_back(val);

            index = index + 2;
        };

        assert!(bytes.length() == 32, EInvalidHashLength);

        bytes
    }

    #[test_only]
    fun convert_hex_char(character: u8): u8 {
        if (character >= 0x30 && character <= 0x39) {  // '0' to '9'
            character - 0x30
        } else if (character >= 0x61 && character <= 0x66) {  // 'a' to 'f'
            character - 0x61 + 10
        } else if (character >= 0x41 && character <= 0x46) {  // 'A' to 'F'
            character - 0x41 + 10
        } else {
            abort(EInvalidHexCharacter)
        }
    }

    #[test_only]
    fun destroy_for_testing(
        user_invite_registry: UserInviteRegistry,
        invite_config: InviteConfig
    ) {
        destroy(user_invite_registry);
        destroy(invite_config);
    }

    #[test_only]
    fun setup_for_testing(): (Scenario, UserInviteRegistry, InviteConfig) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
            user_invite::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let (user_invite_registry, invite_config) = {
            let invite_config = scenario.take_shared<InviteConfig>();
            let user_invite_registry = scenario.take_shared<UserInviteRegistry>();

            (user_invite_registry, invite_config)
        };

        (scenario_val, user_invite_registry, invite_config)
    }

    #[test]
    fun test_user_invite_init() {
        let (
            mut scenario_val,
            user_invite_registry_val,
            invite_config_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                user_invite_registry_val,
                invite_config_val
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_invite_init_config() {
        let (
            mut scenario_val,
            user_invite_registry_val,
            mut invite_config_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let invite_config = &mut invite_config_val;

        ts::next_tx(scenario, SERVER);
        {
            let invite_cap = ts::take_from_sender<InviteCap>(scenario);

            let is_invite_required = user_invite::is_invite_required(
                invite_config
            );

            assert!(!is_invite_required, EConfigMismatch);

            user_invite::set_invite_config(
                &invite_cap,
                invite_config,
                true
            );

            let is_invite_required = user_invite::is_invite_required(
                invite_config
            );

            assert!(is_invite_required, EConfigMismatch);

            ts::return_to_sender(scenario, invite_cap);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                user_invite_registry_val,
                invite_config_val
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_invite() {
        let (
            mut scenario_val,
            mut user_invite_registry_val,
            invite_config_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        let user_invite_registry = &mut user_invite_registry_val;

        let invite_key = utf8(b"key");
        let invite_hash = b"hash";

        ts::next_tx(scenario, ADMIN);
        {
            user_invite::create_invite(
                user_invite_registry,
                invite_hash,
                invite_key,
                OTHER
            );

            let has_record = user_invite::has_record(
                user_invite_registry,
                invite_key
            );

            assert!(has_record, EInviteRecord);

            user_invite::delete_invite(
                user_invite_registry,
                invite_key
            );

            let has_record = user_invite::has_record(
                user_invite_registry,
                invite_key
            );

            assert!(!has_record, EInviteRecord);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                user_invite_registry_val,
                invite_config_val
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_invite_validity() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            // test known cases of sha3 computed in javascript

            let invite_hash = create_hash_array(
                b"a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a"
            );

            let is_invite_valid = user_invite::is_invite_valid(
                utf8(b""),
                utf8(b""),
                invite_hash
            );

            assert!(is_invite_valid, EInviteInvalid);

            let invite_hash = create_hash_array(
                b"1c76e98fcac0e60aa45ceb9dd68cb8f8c6e9beb6baee207bee9902aa01e88fc7"
            );

            let is_invite_valid = user_invite::is_invite_valid(
                utf8(b"code"),
                utf8(b""),
                invite_hash
            );

            assert!(is_invite_valid, EInviteInvalid);

            let invite_hash = create_hash_array(
                b"20c635d10270fdb360e84bf63e519d5e76df7c57c8ff01a96bc523ee66cd0b2e"
            );

            let is_invite_valid = user_invite::is_invite_valid(
                utf8(b""),
                utf8(b"key"),
                invite_hash
            );

            assert!(is_invite_valid, EInviteInvalid);

            let invite_hash = create_hash_array(
                b"d49b047aaca5fd3e37ea3be6311e68fc918e7e16bd31bfcd24c44ba5c938e94a"
            );

            let is_invite_valid = user_invite::is_invite_valid(
                utf8(b"code"),
                utf8(b"key"),
                invite_hash
            );

            assert!(is_invite_valid, EInviteInvalid);
        };

        ts::end(scenario_val);
    }
}
