module sage_admin::access {
    use std::{
        type_name::{Self, TypeName}
    };

    use sage_admin::{
        admin::{AdminCap}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const ETypeMismatch: u64 = 370;
    const EWitnessMismatch: u64 = 371;

    // --------------- Name Tag ---------------

    public struct ChannelConfig has key {
        id: UID,
        type_name: TypeName
    }

    public struct ChannelWitnessConfig has key {
        id: UID,
        type_name: TypeName
    }

    public struct GroupWitnessConfig has key {
        id: UID,
        type_name: TypeName
    }

    public struct UserOwnedConfig has key {
        id: UID,
        type_name: TypeName
    }

    public struct UserSharedConfig has key {
        id: UID,
        type_name: TypeName
    }

    public struct UserWitnessConfig has key {
        id: UID,
        type_name: TypeName
    }
    
    #[test_only]
    public struct InvalidType has key {
        id: UID
    }

    #[test_only]
    public struct ValidType has key {
        id: UID
    }

    #[test_only]
    public struct InvalidWitness has drop {}

    #[test_only]
    public struct ValidWitness has drop {}

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun assert_channel<ChannelType: key> (
        channel_config: &ChannelConfig,
        channel: &ChannelType
    ) {
        let is_auth = verify_channel<ChannelType>(
            channel_config,
            channel
        );

        assert!(is_auth, ETypeMismatch);
    }

    public fun assert_channel_witness<ChannelWitnessType: drop> (
        channel_witness_config: &ChannelWitnessConfig,
        channel_witness: &ChannelWitnessType
    ) {
        let is_auth = verify_channel_witness<ChannelWitnessType>(
            channel_witness_config,
            channel_witness
        );

        assert!(is_auth, EWitnessMismatch);
    }

    public fun assert_group_witness<GroupWitnessType: drop> (
        group_witness_config: &GroupWitnessConfig,
        group_witness: &GroupWitnessType
    ) {
        let is_auth = verify_group_witness<GroupWitnessType>(
            group_witness_config,
            group_witness
        );

        assert!(is_auth, EWitnessMismatch);
    }

    public fun assert_owned_user<UserOwnedType: key> (
        owned_user_config: &UserOwnedConfig,
        owned_user: &UserOwnedType
    ) {
        let is_auth = verify_owned_user<UserOwnedType>(
            owned_user_config,
            owned_user
        );

        assert!(is_auth, ETypeMismatch);
    }

    public fun assert_shared_user<UserSharedType: key> (
        shared_user_config: &UserSharedConfig,
        shared_user: &UserSharedType
    ) {
        let is_auth = verify_shared_user<UserSharedType>(
            shared_user_config,
            shared_user
        );

        assert!(is_auth, ETypeMismatch);
    }

    public fun assert_user_witness<UserWitnessType: drop> (
        user_witness_config: &UserWitnessConfig,
        user_witness: &UserWitnessType
    ) {
        let is_auth = verify_user_witness<UserWitnessType>(
            user_witness_config,
            user_witness
        );

        assert!(is_auth, EWitnessMismatch);
    }

    public fun create_channel_config<ChannelType: key> (
        _: &AdminCap,
        ctx: &mut TxContext
    ) {
        let type_name = type_name::get<ChannelType>();

        let channel_config = ChannelConfig {
            id: object::new(ctx),
            type_name
        };

        transfer::share_object(channel_config);
    }

    public fun create_channel_witness_config<ChannelWitnessType: drop> (
        _: &AdminCap,
        ctx: &mut TxContext
    ) {
        let type_name = type_name::get<ChannelWitnessType>();

        let channel_witness_config = ChannelWitnessConfig {
            id: object::new(ctx),
            type_name
        };

        transfer::share_object(channel_witness_config);
    }

    public fun create_group_witness_config<GroupWitnessType: drop> (
        _: &AdminCap,
        ctx: &mut TxContext
    ) {
        let type_name = type_name::get<GroupWitnessType>();

        let group_witness_config = GroupWitnessConfig {
            id: object::new(ctx),
            type_name
        };

        transfer::share_object(group_witness_config);
    }

    public fun create_owned_user_config<UserOwnedType: key> (
        _: &AdminCap,
        ctx: &mut TxContext
    ) {
        let type_name = type_name::get<UserOwnedType>();

        let owned_user_config = UserOwnedConfig {
            id: object::new(ctx),
            type_name
        };

        transfer::share_object(owned_user_config);
    }

    public fun create_shared_user_config<UserSharedType: key> (
        _: &AdminCap,
        ctx: &mut TxContext
    ) {
        let type_name = type_name::get<UserSharedType>();

        let shared_user_config = UserSharedConfig {
            id: object::new(ctx),
            type_name
        };

        transfer::share_object(shared_user_config);
    }

    public fun create_user_witness_config<UserWitnessType: drop> (
        _: &AdminCap,
        ctx: &mut TxContext
    ) {
        let type_name = type_name::get<UserWitnessType>();

        let user_witness_config = UserWitnessConfig {
            id: object::new(ctx),
            type_name
        };

        transfer::share_object(user_witness_config);
    }

    public fun update_channel_type<ChannelType: key> (
        _: &AdminCap,
        channel_config: &mut ChannelConfig
    ) {
        let type_name = type_name::get<ChannelType>();

        channel_config.type_name = type_name;
    }

    public fun update_owned_user_type<UserOwnedType: key> (
        _: &AdminCap,
        owned_user_config: &mut UserOwnedConfig
    ) {
        let type_name = type_name::get<UserOwnedType>();

        owned_user_config.type_name = type_name;
    }

    public fun update_shared_user_type<UserSharedType: key> (
        _: &AdminCap,
        shared_user_config: &mut UserSharedConfig
    ) {
        let type_name = type_name::get<UserSharedType>();

        shared_user_config.type_name = type_name;
    }

    public fun verify_channel<ChannelType: key> (
        channel_config: &ChannelConfig,
        _: &ChannelType
    ): bool {
        let type_name = type_name::get<ChannelType>();

        type_name == channel_config.type_name
    }

    public fun verify_channel_witness<ChannelWitnessType: drop> (
        channel_witness_config: &ChannelWitnessConfig,
        _: &ChannelWitnessType
    ): bool {
        let type_name = type_name::get<ChannelWitnessType>();

        type_name == channel_witness_config.type_name
    }

    public fun verify_group_witness<GroupWitnessType: drop> (
        group_witness_config: &GroupWitnessConfig,
        _: &GroupWitnessType
    ): bool {
        let type_name = type_name::get<GroupWitnessType>();

        type_name == group_witness_config.type_name
    }

    public fun verify_owned_user<UserOwnedType: key> (
        owned_user_config: &UserOwnedConfig,
        _: &UserOwnedType
    ): bool {
        let type_name = type_name::get<UserOwnedType>();

        type_name == owned_user_config.type_name
    }

    public fun verify_shared_user<UserSharedType: key> (
        shared_user_config: &UserSharedConfig,
        _: &UserSharedType
    ): bool {
        let type_name = type_name::get<UserSharedType>();

        type_name == shared_user_config.type_name
    }

    public fun verify_user_witness<UserWitnessType: drop> (
        user_witness_config: &UserWitnessConfig,
        _: &UserWitnessType
    ): bool {
        let type_name = type_name::get<UserWitnessType>();

        type_name == user_witness_config.type_name
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public fun create_invalid_type_for_testing(
        ctx: &mut TxContext
    ): InvalidType {
        InvalidType {
            id: object::new(ctx)
        }
    }

    #[test_only]
    public fun create_valid_type_for_testing(
        ctx: &mut TxContext
    ): ValidType {
        ValidType {
            id: object::new(ctx)
        }
    }

    #[test_only]
    public fun create_invalid_witness_for_testing(): InvalidWitness {
        InvalidWitness {}
    }

    #[test_only]
    public fun create_valid_witness_for_testing(): ValidWitness {
        ValidWitness {}
    }
}
