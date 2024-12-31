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
    // const EInvalidHashLength: u64 = 1;
    const EInviteInvalid: u64 = 2;
    const EInviteRecord: u64 = 3;
    const EInviteValid: u64 = 4;

    // --------------- Test Functions ---------------

    // #[test_only]
    // fun create_hash_array(
    //     hash: vector<u8>
    // ): vector<u8> {
    //     assert!(hash.length() == 64, EInvalidHashLength);

    //     let mut index = 0;
    //     let mut bytes = vector::empty<u8>();

    //     while (index < hash.length()) {
    //         let first = hash[index] << 4 & 0xF0;
    //         let second = hash[index + 1] & 0x0F;

    //         let val = first | second;

    //         bytes.push_back(val);

    //         index = index + 2;
    //     };

    //     assert!(bytes.length() == 32, EInvalidHashLength);

    //     bytes
    // }

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

            user_invite::set_invite_config(
                &invite_cap,
                invite_config,
                false
            );

            let is_invite_required = user_invite::is_invite_required(
                invite_config
            );

            assert!(!is_invite_required, EConfigMismatch);

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

            let mut invite_hash = vector::empty<u8>();

            // let invite_hash = create_hash_array(
            //     b"a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a"
            // );

            invite_hash.push_back(0xa7);
            invite_hash.push_back(0xff);
            invite_hash.push_back(0xc6);
            invite_hash.push_back(0xf8);
            invite_hash.push_back(0xbf);
            invite_hash.push_back(0x1e);
            invite_hash.push_back(0xd7);
            invite_hash.push_back(0x66);
            invite_hash.push_back(0x51);
            invite_hash.push_back(0xc1);
            invite_hash.push_back(0x47);
            invite_hash.push_back(0x56);
            invite_hash.push_back(0xa0);
            invite_hash.push_back(0x61);
            invite_hash.push_back(0xd6);
            invite_hash.push_back(0x62);
            invite_hash.push_back(0xf5);
            invite_hash.push_back(0x80);
            invite_hash.push_back(0xff);
            invite_hash.push_back(0x4d);
            invite_hash.push_back(0xe4);
            invite_hash.push_back(0x3b);
            invite_hash.push_back(0x49);
            invite_hash.push_back(0xfa);
            invite_hash.push_back(0x82);
            invite_hash.push_back(0xd8);
            invite_hash.push_back(0x0a);
            invite_hash.push_back(0x4b);
            invite_hash.push_back(0x80);
            invite_hash.push_back(0xf8);
            invite_hash.push_back(0x43);
            invite_hash.push_back(0x4a);

            let is_invite_valid = user_invite::is_invite_valid(
                utf8(b""),
                utf8(b""),
                invite_hash
            );

            assert!(is_invite_valid, EInviteInvalid);

            let mut invite_hash = vector::empty<u8>();

            // let invite_hash = create_hash_array(
            //     b"1c76e98fcac0e60aa45ceb9dd68cb8f8c6e9beb6baee207bee9902aa01e88fc7"
            // );

            invite_hash.push_back(0x1c);
            invite_hash.push_back(0x76);
            invite_hash.push_back(0xe9);
            invite_hash.push_back(0x8f);
            invite_hash.push_back(0xca);
            invite_hash.push_back(0xc0);
            invite_hash.push_back(0xe6);
            invite_hash.push_back(0x0a);
            invite_hash.push_back(0xa4);
            invite_hash.push_back(0x5c);
            invite_hash.push_back(0xeb);
            invite_hash.push_back(0x9d);
            invite_hash.push_back(0xd6);
            invite_hash.push_back(0x8c);
            invite_hash.push_back(0xb8);
            invite_hash.push_back(0xf8);
            invite_hash.push_back(0xc6);
            invite_hash.push_back(0xe9);
            invite_hash.push_back(0xbe);
            invite_hash.push_back(0xb6);
            invite_hash.push_back(0xba);
            invite_hash.push_back(0xee);
            invite_hash.push_back(0x20);
            invite_hash.push_back(0x7b);
            invite_hash.push_back(0xee);
            invite_hash.push_back(0x99);
            invite_hash.push_back(0x02);
            invite_hash.push_back(0xaa);
            invite_hash.push_back(0x01);
            invite_hash.push_back(0xe8);
            invite_hash.push_back(0x8f);
            invite_hash.push_back(0xc7);

            let is_invite_valid = user_invite::is_invite_valid(
                utf8(b"code"),
                utf8(b""),
                invite_hash
            );

            assert!(is_invite_valid, EInviteInvalid);

            let mut invite_hash = vector::empty<u8>();

            // let invite_hash = create_hash_array(
            //     b"20c635d10270fdb360e84bf63e519d5e76df7c57c8ff01a96bc523ee66cd0b2e"
            // );

            invite_hash.push_back(0x20);
            invite_hash.push_back(0xc6);
            invite_hash.push_back(0x35);
            invite_hash.push_back(0xd1);
            invite_hash.push_back(0x02);
            invite_hash.push_back(0x70);
            invite_hash.push_back(0xfd);
            invite_hash.push_back(0xb3);
            invite_hash.push_back(0x60);
            invite_hash.push_back(0xe8);
            invite_hash.push_back(0x4b);
            invite_hash.push_back(0xf6);
            invite_hash.push_back(0x3e);
            invite_hash.push_back(0x51);
            invite_hash.push_back(0x9d);
            invite_hash.push_back(0x5e);
            invite_hash.push_back(0x76);
            invite_hash.push_back(0xdf);
            invite_hash.push_back(0x7c);
            invite_hash.push_back(0x57);
            invite_hash.push_back(0xc8);
            invite_hash.push_back(0xff);
            invite_hash.push_back(0x01);
            invite_hash.push_back(0xa9);
            invite_hash.push_back(0x6b);
            invite_hash.push_back(0xc5);
            invite_hash.push_back(0x23);
            invite_hash.push_back(0xee);
            invite_hash.push_back(0x66);
            invite_hash.push_back(0xcd);
            invite_hash.push_back(0x0b);
            invite_hash.push_back(0x2e);

            let is_invite_valid = user_invite::is_invite_valid(
                utf8(b""),
                utf8(b"key"),
                invite_hash
            );

            assert!(is_invite_valid, EInviteInvalid);

            let mut invite_hash = vector::empty<u8>();

            // let invite_hash = create_hash_array(
            //     b"d49b047aaca5fd3e37ea3be6311e68fc918e7e16bd31bfcd24c44ba5c938e94a"
            // );

            invite_hash.push_back(0xd4);
            invite_hash.push_back(0x9b);
            invite_hash.push_back(0x04);
            invite_hash.push_back(0x7a);
            invite_hash.push_back(0xac);
            invite_hash.push_back(0xa5);
            invite_hash.push_back(0xfd);
            invite_hash.push_back(0x3e);
            invite_hash.push_back(0x37);
            invite_hash.push_back(0xea);
            invite_hash.push_back(0x3b);
            invite_hash.push_back(0xe6);
            invite_hash.push_back(0x31);
            invite_hash.push_back(0x1e);
            invite_hash.push_back(0x68);
            invite_hash.push_back(0xfc);
            invite_hash.push_back(0x91);
            invite_hash.push_back(0x8e);
            invite_hash.push_back(0x7e);
            invite_hash.push_back(0x16);
            invite_hash.push_back(0xbd);
            invite_hash.push_back(0x31);
            invite_hash.push_back(0xbf);
            invite_hash.push_back(0xcd);
            invite_hash.push_back(0x24);
            invite_hash.push_back(0xc4);
            invite_hash.push_back(0x4b);
            invite_hash.push_back(0xa5);
            invite_hash.push_back(0xc9);
            invite_hash.push_back(0x38);
            invite_hash.push_back(0xe9);
            invite_hash.push_back(0x4a);

            let is_invite_valid = user_invite::is_invite_valid(
                utf8(b"code"),
                utf8(b"key"),
                invite_hash
            );

            assert!(is_invite_valid, EInviteInvalid);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_invite_validity_mismatch() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            // test known cases of sha3 computed in javascript

            let mut invite_hash = vector::empty<u8>();

            // let invite_hash = create_hash_array(
            //     b"a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a"
            // );

            invite_hash.push_back(0xa7);
            invite_hash.push_back(0xff);
            invite_hash.push_back(0xc6);
            invite_hash.push_back(0xf8);
            invite_hash.push_back(0xbf);
            invite_hash.push_back(0x1e);
            invite_hash.push_back(0xd7);
            invite_hash.push_back(0x66);
            invite_hash.push_back(0x51);
            invite_hash.push_back(0xc1);
            invite_hash.push_back(0x47);
            invite_hash.push_back(0x56);
            invite_hash.push_back(0xa0);
            invite_hash.push_back(0x61);
            invite_hash.push_back(0xd6);
            invite_hash.push_back(0x62);
            invite_hash.push_back(0xf5);
            invite_hash.push_back(0x80);
            invite_hash.push_back(0xff);
            invite_hash.push_back(0x4d);
            invite_hash.push_back(0xe4);
            invite_hash.push_back(0x3b);
            invite_hash.push_back(0x49);
            invite_hash.push_back(0xfa);
            invite_hash.push_back(0x82);
            invite_hash.push_back(0xd8);
            invite_hash.push_back(0x0a);
            invite_hash.push_back(0x4b);
            invite_hash.push_back(0x80);
            invite_hash.push_back(0xf8);
            invite_hash.push_back(0x43);

            // this is incorrect
            invite_hash.push_back(0x00);

            let is_invite_valid = user_invite::is_invite_valid(
                utf8(b""),
                utf8(b""),
                invite_hash
            );

            assert!(!is_invite_valid, EInviteValid);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_user_invite_validity_length_mismatch() {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            // test known cases of sha3 computed in javascript

            let mut invite_hash = vector::empty<u8>();

            // let invite_hash = create_hash_array(
            //     b"a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a"
            // );

            invite_hash.push_back(0xa7);
            invite_hash.push_back(0xff);
            invite_hash.push_back(0xc6);
            invite_hash.push_back(0xf8);
            invite_hash.push_back(0xbf);
            invite_hash.push_back(0x1e);
            invite_hash.push_back(0xd7);
            invite_hash.push_back(0x66);
            invite_hash.push_back(0x51);
            invite_hash.push_back(0xc1);
            invite_hash.push_back(0x47);
            invite_hash.push_back(0x56);
            invite_hash.push_back(0xa0);
            invite_hash.push_back(0x61);
            invite_hash.push_back(0xd6);
            invite_hash.push_back(0x62);
            invite_hash.push_back(0xf5);
            invite_hash.push_back(0x80);
            invite_hash.push_back(0xff);
            invite_hash.push_back(0x4d);
            invite_hash.push_back(0xe4);
            invite_hash.push_back(0x3b);
            invite_hash.push_back(0x49);
            invite_hash.push_back(0xfa);
            invite_hash.push_back(0x82);
            invite_hash.push_back(0xd8);
            invite_hash.push_back(0x0a);
            invite_hash.push_back(0x4b);
            invite_hash.push_back(0x80);
            invite_hash.push_back(0xf8);
            invite_hash.push_back(0x43);

            let is_invite_valid = user_invite::is_invite_valid(
                utf8(b""),
                utf8(b""),
                invite_hash
            );

            assert!(!is_invite_valid, EInviteValid);
        };

        ts::end(scenario_val);
    }
}
