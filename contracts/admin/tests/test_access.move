#[test_only]
module sage_admin::test_admin_access {
    use sui::{
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy}
    };

    use sage_admin::{
        admin_access::{
            Self,
            ChannelConfig,
            ChannelWitnessConfig,
            GroupWitnessConfig,
            UserOwnedConfig,
            UserSharedConfig,
            UserWitnessConfig,
            InvalidType,
            ValidType,
            InvalidWitness,
            ValidWitness,
            ETypeMismatch,
            EWitnessMismatch
        },
        admin::{
            Self,
            AdminCap,
        }
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    const ETestTypeMismatch: u64 = 0;

    // --------------- Test Functions ---------------

    #[test_only]
    fun destroy_for_testing(
        admin_cap: AdminCap,
        channel_config: ChannelConfig,
        channel_witness_config: ChannelWitnessConfig,
        group_witness_config: GroupWitnessConfig,
        owned_user_config: UserOwnedConfig,
        user_shared_config: UserSharedConfig,
        user_witness_config: UserWitnessConfig
    ) {
        destroy(admin_cap);
        destroy(channel_config);
        destroy(channel_witness_config);
        destroy(group_witness_config);
        destroy(owned_user_config);
        destroy(user_shared_config);
        destroy(user_witness_config);
    }

    #[test_only]
    fun setup_for_testing(): (
        Scenario,
        AdminCap,
        ChannelConfig,
        ChannelWitnessConfig,
        GroupWitnessConfig,
        UserOwnedConfig,
        UserSharedConfig,
        UserWitnessConfig
    ) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            admin::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let admin_cap = {
            let admin_cap = scenario.take_from_sender<AdminCap>();

            admin_access::create_channel_config<ValidType>(
                &admin_cap,
                ts::ctx(scenario)
            );

            admin_access::create_channel_witness_config<ValidWitness>(
                &admin_cap,
                ts::ctx(scenario)
            );

            admin_access::create_group_witness_config<ValidWitness>(
                &admin_cap,
                ts::ctx(scenario)
            );

            admin_access::create_owned_user_config<ValidType>(
                &admin_cap,
                ts::ctx(scenario)
            );

            admin_access::create_shared_user_config<ValidType>(
                &admin_cap,
                ts::ctx(scenario)
            );

            admin_access::create_user_witness_config<ValidWitness>(
                &admin_cap,
                ts::ctx(scenario)
            );

            admin_cap
        };

        ts::next_tx(scenario, ADMIN);
        let (
            channel_config,
            channel_witness_config,
            group_witness_config,
            owned_user_config,
            shared_user_config,
            user_witness_config
        ) = {
            let channel_config = scenario.take_shared<ChannelConfig>();
            let channel_witness_config = scenario.take_shared<ChannelWitnessConfig>();
            let group_witness_config = scenario.take_shared<GroupWitnessConfig>();
            let owned_user_config = scenario.take_shared<UserOwnedConfig>();
            let shared_user_config = scenario.take_shared<UserSharedConfig>();
            let user_witness_config = scenario.take_shared<UserWitnessConfig>();

            (
                channel_config,
                channel_witness_config,
                group_witness_config,
                owned_user_config,
                shared_user_config,
                user_witness_config
            )
        };

        (
            scenario_val,
            admin_cap,
            channel_config,
            channel_witness_config,
            group_witness_config,
            owned_user_config,
            shared_user_config,
            user_witness_config
        )
    }

    #[test]
    fun test_init() {
        let (
            mut scenario_val,
            admin_cap,
            channel_config,
            channel_witness_config,
            group_witness_config,
            owned_user_config,
            shared_user_config,
            user_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                admin_cap,
                channel_config,
                channel_witness_config,
                group_witness_config,
                owned_user_config,
                shared_user_config,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_verify_type() {
        let (
            mut scenario_val,
            admin_cap,
            mut channel_config,
            channel_witness_config,
            group_witness_config,
            mut owned_user_config,
            mut shared_user_config,
            user_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        let invalid_type = {
            let invalid_type = admin_access::create_invalid_type_for_testing(
                ts::ctx(scenario)
            );

            // assert invalid return

            let is_verified = admin_access::verify_channel<InvalidType>(
                &channel_config,
                &invalid_type
            );

            assert!(!is_verified, ETestTypeMismatch);

            let is_verified = admin_access::verify_owned_user<InvalidType>(
                &owned_user_config,
                &invalid_type
            );

            assert!(!is_verified, ETestTypeMismatch);

            let is_verified = admin_access::verify_shared_user<InvalidType>(
                &shared_user_config,
                &invalid_type
            );

            assert!(!is_verified, ETestTypeMismatch);

            // assert valid return

            let valid_type = admin_access::create_valid_type_for_testing(
                ts::ctx(scenario)
            );

            let is_verified = admin_access::verify_channel<ValidType>(
                &channel_config,
                &valid_type
            );

            assert!(is_verified, ETestTypeMismatch);

            let is_verified = admin_access::verify_owned_user<ValidType>(
                &owned_user_config,
                &valid_type
            );

            assert!(is_verified, ETestTypeMismatch);

            let is_verified = admin_access::verify_shared_user<ValidType>(
                &shared_user_config,
                &valid_type
            );

            assert!(is_verified, ETestTypeMismatch);

            // assert update

            admin_access::update_channel_type<InvalidType>(
                &admin_cap,
                &mut channel_config
            );

            admin_access::update_owned_user_type<InvalidType>(
                &admin_cap,
                &mut owned_user_config
            );

            admin_access::update_shared_user_type<InvalidType>(
                &admin_cap,
                &mut shared_user_config
            );

            destroy(valid_type);

            invalid_type
        };

        ts::next_tx(scenario, ADMIN);
        {
            let is_verified = admin_access::verify_channel<InvalidType>(
                &channel_config,
                &invalid_type
            );

            assert!(is_verified, ETestTypeMismatch);

            let is_verified = admin_access::verify_owned_user<InvalidType>(
                &owned_user_config,
                &invalid_type
            );

            assert!(is_verified, ETestTypeMismatch);

            let is_verified = admin_access::verify_shared_user<InvalidType>(
                &shared_user_config,
                &invalid_type
            );

            assert!(is_verified, ETestTypeMismatch);

            destroy(invalid_type);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                admin_cap,
                channel_config,
                channel_witness_config,
                group_witness_config,
                owned_user_config,
                shared_user_config,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_verify_witness() {
        let (
            mut scenario_val,
            admin_cap,
            channel_config,
            channel_witness_config,
            group_witness_config,
            owned_user_config,
            shared_user_config,
            user_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let invalid_witness = admin_access::create_invalid_witness_for_testing();

            // assert invalid return

            let is_verified = admin_access::verify_channel_witness<InvalidWitness>(
                &channel_witness_config,
                &invalid_witness
            );

            assert!(!is_verified, ETestTypeMismatch);

            let is_verified = admin_access::verify_group_witness<InvalidWitness>(
                &group_witness_config,
                &invalid_witness
            );

            assert!(!is_verified, ETestTypeMismatch);

            let is_verified = admin_access::verify_user_witness<InvalidWitness>(
                &user_witness_config,
                &invalid_witness
            );

            assert!(!is_verified, ETestTypeMismatch);

            // assert valid return

            let valid_witness = admin_access::create_valid_witness_for_testing();

            let is_verified = admin_access::verify_channel_witness<ValidWitness>(
                &channel_witness_config,
                &valid_witness
            );

            assert!(is_verified, ETestTypeMismatch);

            let is_verified = admin_access::verify_group_witness<ValidWitness>(
                &group_witness_config,
                &valid_witness
            );

            assert!(is_verified, ETestTypeMismatch);

            let is_verified = admin_access::verify_user_witness<ValidWitness>(
                &user_witness_config,
                &valid_witness
            );

            assert!(is_verified, ETestTypeMismatch);

            destroy(valid_witness);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                admin_cap,
                channel_config,
                channel_witness_config,
                group_witness_config,
                owned_user_config,
                shared_user_config,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ETypeMismatch)]
    fun test_assert_channel_type() {
        let (
            mut scenario_val,
            admin_cap,
            channel_config,
            channel_witness_config,
            group_witness_config,
            owned_user_config,
            shared_user_config,
            user_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let invalid_type = admin_access::create_invalid_type_for_testing(
                ts::ctx(scenario)
            );

            admin_access::assert_channel<InvalidType>(
                &channel_config,
                &invalid_type
            );

            destroy(invalid_type);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                admin_cap,
                channel_config,
                channel_witness_config,
                group_witness_config,
                owned_user_config,
                shared_user_config,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EWitnessMismatch)]
    fun test_assert_channel_witness() {
        let (
            mut scenario_val,
            admin_cap,
            channel_config,
            channel_witness_config,
            group_witness_config,
            owned_user_config,
            shared_user_config,
            user_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let invalid_witness = admin_access::create_invalid_witness_for_testing();

            admin_access::assert_channel_witness<InvalidWitness>(
                &channel_witness_config,
                &invalid_witness
            );

            destroy(invalid_witness);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                admin_cap,
                channel_config,
                channel_witness_config,
                group_witness_config,
                owned_user_config,
                shared_user_config,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EWitnessMismatch)]
    fun test_assert_group_witness() {
        let (
            mut scenario_val,
            admin_cap,
            channel_config,
            channel_witness_config,
            group_witness_config,
            owned_user_config,
            shared_user_config,
            user_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let invalid_witness = admin_access::create_invalid_witness_for_testing();

            admin_access::assert_group_witness<InvalidWitness>(
                &group_witness_config,
                &invalid_witness
            );

            destroy(invalid_witness);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                admin_cap,
                channel_config,
                channel_witness_config,
                group_witness_config,
                owned_user_config,
                shared_user_config,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ETypeMismatch)]
    fun test_assert_owned_user_type() {
        let (
            mut scenario_val,
            admin_cap,
            channel_config,
            channel_witness_config,
            group_witness_config,
            owned_user_config,
            shared_user_config,
            user_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let invalid_type = admin_access::create_invalid_type_for_testing(
                ts::ctx(scenario)
            );

            admin_access::assert_owned_user<InvalidType>(
                &owned_user_config,
                &invalid_type
            );

            destroy(invalid_type);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                admin_cap,
                channel_config,
                channel_witness_config,
                group_witness_config,
                owned_user_config,
                shared_user_config,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = ETypeMismatch)]
    fun test_assert_shared_user_type() {
        let (
            mut scenario_val,
            admin_cap,
            channel_config,
            channel_witness_config,
            group_witness_config,
            owned_user_config,
            shared_user_config,
            user_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let invalid_type = admin_access::create_invalid_type_for_testing(
                ts::ctx(scenario)
            );

            admin_access::assert_shared_user<InvalidType>(
                &shared_user_config,
                &invalid_type
            );

            destroy(invalid_type);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                admin_cap,
                channel_config,
                channel_witness_config,
                group_witness_config,
                owned_user_config,
                shared_user_config,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = EWitnessMismatch)]
    fun test_assert_user_witness() {
        let (
            mut scenario_val,
            admin_cap,
            channel_config,
            channel_witness_config,
            group_witness_config,
            owned_user_config,
            shared_user_config,
            user_witness_config
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let invalid_witness = admin_access::create_invalid_witness_for_testing();

            admin_access::assert_user_witness<InvalidWitness>(
                &user_witness_config,
                &invalid_witness
            );

            destroy(invalid_witness);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy_for_testing(
                admin_cap,
                channel_config,
                channel_witness_config,
                group_witness_config,
                owned_user_config,
                shared_user_config,
                user_witness_config
            );
        };

        ts::end(scenario_val);
    }
}
