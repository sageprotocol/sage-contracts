module sage_admin::admin_actions {
    use std::string::{String};

    use sui::{event};

    use sage_admin::{
        admin::{
            AdminCap,
            FeeCap,
            RewardCap
        },
        admin_access::{
            Self,
            UserOwnedConfig
        },
        apps::{Self, App, AppRegistry},
        fees::{Self, Royalties}
    };

    use sage_utils::{
        string_helpers::{Self}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    // --------------- Events ---------------

    public struct AppCreated has copy, drop {
        app_id: address,
        name: String
    }

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun create_app<OwnedUserType: key> (
        app_registry: &mut AppRegistry,
        app_name: String,
        owned_user: &OwnedUserType,
        owned_user_config: &UserOwnedConfig,
        ctx: &mut TxContext
    ): address {
        admin_access::assert_owned_user<OwnedUserType>(
            owned_user_config,
            owned_user
        );

        create_app_internal(
            app_registry,
            app_name,
            ctx
        )
    }

    public fun create_app_as_admin(
        _: &AdminCap,
        app_registry: &mut AppRegistry,
        app_name: String,
        ctx: &mut TxContext
    ): address {
        create_app_internal(
            app_registry,
            app_name,
            ctx
        )
    }

    public fun create_royalties<CoinType> (
        fee_cap: &FeeCap,
        app: &mut App,
        partner_fee: u64,
        partner_treasury: address,
        protocol_fee: u64,
        protocol_treasury: address,
        ctx: &mut TxContext
    ) {
        fees::create_royalties<CoinType>(
            fee_cap,
            app,
            partner_fee,
            partner_treasury,
            protocol_fee,
            protocol_treasury,
            ctx
        );
    }

    public fun update_app_rewards(
        _: &RewardCap,
        app: &mut App,
        rewards_enabled: bool
    ) {
        apps::update_rewards(
            app,
            rewards_enabled
        );
    }

    public fun update_royalties<CoinType> (
        _: &FeeCap,
        royalties: &mut Royalties,
        partner_fee: u64,
        partner_treasury: address,
        protocol_fee: u64,
        protocol_treasury: address
    ) {
        fees::update_royalties<CoinType> (
            royalties,
            partner_fee,
            partner_treasury,
            protocol_fee,
            protocol_treasury
        );
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    fun create_app_internal(
        app_registry: &mut AppRegistry,
        app_name: String,
        ctx: &mut TxContext
    ): address {
        let app_key = string_helpers::to_lowercase(
            &app_name
        );

        let app = apps::create(
            app_registry,
            app_key,
            ctx
        );

        event::emit(AppCreated {
            app_id: app,
            name: app_key
        });

        app
    }

    // --------------- Test Functions ---------------
    
}
