module sage_admin::types {
    use std::{
        type_name::{Self, TypeName}
    };

    use sage_admin::{
        admin::{AdminCap}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const ETypeMismatch: u64 = 370;

    // --------------- Name Tag ---------------

    public struct ChannelConfig has key {
        id: UID,
        type_name: TypeName
    }

    public struct UserOwnedConfig has key {
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

    public fun verify_channel<ChannelType: key> (
        channel_config: &ChannelConfig,
        _: &ChannelType
    ): bool {
        let type_name = type_name::get<ChannelType>();

        type_name == channel_config.type_name
    }

    public fun verify_owned_user<UserOwnedType: key> (
        owned_user_config: &UserOwnedConfig,
        _: &UserOwnedType
    ): bool {
        let type_name = type_name::get<UserOwnedType>();

        type_name == owned_user_config.type_name
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
}
