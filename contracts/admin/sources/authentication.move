module sage_admin::authentication {
    use std::{
        type_name::{Self, TypeName}
    };

    use sui::{
        package::{claim_and_keep}
    };

    use sage_admin::{
        admin::{AdminCap}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const ENotAuthenticated: u64 = 370;

    // --------------- Name Tag ---------------

    public struct AuthenticationConfig has key {
        id: UID,
        authentication_soul: Option<TypeName>
    }

    #[test_only]
    public struct InvalidAuthSoul has key {
        id: UID
    }

    #[test_only]
    public struct ValidAuthSoul has key {
        id: UID
    }

    public struct AUTHENTICATION has drop {}

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    fun init(
        otw: AUTHENTICATION,
        ctx: &mut TxContext
    ) {
        claim_and_keep(otw, ctx);

        let authentication_config = AuthenticationConfig {
            id: object::new(ctx),
            authentication_soul: option::none()
        };

        transfer::share_object(authentication_config);
    }

    // --------------- Public Functions ---------------

    public fun assert_authentication<SoulType: key> (
        authentication_config: &AuthenticationConfig,
        soul: &SoulType
    ) {
        let is_auth = verify_authentication<SoulType>(
            authentication_config,
            soul
        );

        assert!(is_auth, ENotAuthenticated);
    }

    public fun update_soul<SoulType: key> (
        _: &AdminCap,
        authentication_config: &mut AuthenticationConfig
    ) {
        let soul_type = type_name::get<SoulType>();

        authentication_config.authentication_soul = option::some(soul_type);
    }

    public fun verify_authentication<SoulType: key> (
        authentication_config: &AuthenticationConfig,
        _: &SoulType
    ): bool {
        if (option::is_none(&authentication_config.authentication_soul)) {
            false
        } else {
            let configured_soul = *option::borrow(&authentication_config.authentication_soul);
            let soul_type = type_name::get<SoulType>();

            configured_soul == soul_type
        }
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public fun create_invalid_auth_soul(
        ctx: &mut TxContext
    ): InvalidAuthSoul {
        let invalid_auth_soul = InvalidAuthSoul {
            id: object::new(ctx)
        };

        invalid_auth_soul
    }

    #[test_only]
    public fun create_valid_auth_soul(
        ctx: &mut TxContext
    ): ValidAuthSoul {
        let valid_auth_soul = ValidAuthSoul {
            id: object::new(ctx)
        };

        valid_auth_soul
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(AUTHENTICATION {}, ctx);
    }
}
