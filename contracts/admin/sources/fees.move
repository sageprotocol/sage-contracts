module sage_admin::fees {
    use std::{
        string::{utf8},
        type_name::{Self, TypeName}
    };

    use sui::{
        coin::{Coin},
        sui::{SUI}
    };

    use sage_admin::{
        admin::{FeeCap},
        apps::{Self, App}
    };

    // --------------- Constants ---------------

    const FEE_LIMIT: u64 = 9800; // 0.98 * SCALE
    const SCALE: u64 = 10000;

    // --------------- Errors ---------------

    const EInvalidFeeValue: u64 = 370;

    // --------------- Name Tag ---------------

    public struct Royalties has key {
        id: UID,
        app: address,
        custom_coin_type: TypeName,
        partner_fee: u64,
        partner_treasury: address,
        protocol_fee: u64,
        protocol_treasury: address
    }

    public struct FEES has drop {}

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun collect_payment<CoinType> (
        custom_coin: Coin<CoinType>,
        sui_coin: Coin<SUI>
    ) {
        transfer::public_transfer(
            custom_coin,
            @treasury
        );

        transfer::public_transfer(
            sui_coin,
            @treasury
        );
    }

    public fun distribute_payment<CoinType> (
        royalties: &Royalties,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        recipient: address,
        ctx: &mut TxContext
    ) {
        let custom_payment_value = custom_payment.value();

        let custom_payment = if (
            royalties.partner_fee > 0
        ) {
            distribute_royalty<CoinType>(
                royalties.partner_fee,
                custom_payment,
                custom_payment_value,
                royalties.partner_treasury,
                ctx
            )
        } else {
            custom_payment
        };

        let custom_payment = if (
            royalties.protocol_fee > 0
        ) {
            distribute_royalty<CoinType>(
                royalties.protocol_fee,
                custom_payment,
                custom_payment_value,
                royalties.protocol_treasury,
                ctx
            )
        } else {
            custom_payment
        };

        transfer::public_transfer(custom_payment, recipient);
        transfer::public_transfer(sui_payment, @treasury);
    }

    // --------------- Friend Functions ---------------

    public(package) fun create_royalties<CoinType> (
        fee_cap: &FeeCap,
        app: &mut App,
        partner_fee: u64,
        partner_treasury: address,
        protocol_fee: u64,
        protocol_treasury: address,
        ctx: &mut TxContext
    ): address {
        assert_fee_ranges(
            partner_fee,
            protocol_fee
        );

        let app_address = app.get_address();
        let coin_type = type_name::get<CoinType>();

        let royalties = Royalties {
            id: object::new(ctx),
            app: app_address,
            custom_coin_type: coin_type,
            partner_fee,
            partner_treasury,
            protocol_fee,
            protocol_treasury
        };

        let royalties_address = royalties.id.to_address();

        apps::add_fee_config(
            fee_cap,
            app,
            utf8(b"royalties"),
            royalties_address
        );

        transfer::share_object(royalties);

        royalties_address
    }

    public(package) fun update_royalties<CoinType> (
        royalties: &mut Royalties,
        partner_fee: u64,
        partner_treasury: address,
        protocol_fee: u64,
        protocol_treasury: address
    ) {
        assert_fee_ranges(
            partner_fee,
            protocol_fee
        );

        let coin_type = type_name::get<CoinType>();

        royalties.custom_coin_type = coin_type;
        royalties.partner_fee = partner_fee;
        royalties.partner_treasury = partner_treasury;
        royalties.protocol_fee = protocol_fee;
        royalties.protocol_treasury = protocol_treasury;
    }

    // --------------- Internal Functions ---------------

    fun assert_fee_ranges (
        partner_fee: u64,
        protocol_fee: u64
    ) {
        let is_valid = if (
            (partner_fee + protocol_fee) <= FEE_LIMIT
        ) {
            true
        } else {
            false
        };

        assert!(is_valid, EInvalidFeeValue);
    }

    fun distribute_royalty<CoinType> (
        fee: u64,
        mut payment: Coin<CoinType>,
        total_payment_value: u64,
        treasury: address,
        ctx: &mut TxContext
    ): Coin<CoinType> {
        let royalty_amount = total_payment_value * fee / SCALE;

        let royalty_payment = payment.split<CoinType>(
            royalty_amount,
            ctx
        );

        transfer::public_transfer(
            royalty_payment,
            treasury
        );

        payment
    }

    // --------------- Test Functions ---------------

    #[test_only]
    public fun create_for_testing<CoinType> (
        app: &mut App,
        partner_fee: u64,
        partner_treasury: address,
        protocol_fee: u64,
        protocol_treasury: address,
        ctx: &mut TxContext
    ): Royalties {
        let app_address = app.get_address();
        let coin_type = type_name::get<CoinType>();

        Royalties {
            id: object::new(ctx),
            app: app_address,
            custom_coin_type: coin_type,
            partner_fee,
            partner_treasury,
            protocol_fee,
            protocol_treasury
        }
    }

    #[test_only]
    public fun get_app_address_for_testing (
        royalties: Royalties
    ): (Royalties, address) {
        let app_address = royalties.app;

        (royalties, app_address)
    }

    #[test_only]
    public fun get_custom_coin_for_testing (
        royalties: Royalties
    ): (Royalties, TypeName) {
        let custom_coin_type = royalties.custom_coin_type;

        (royalties, custom_coin_type)
    }

    #[test_only]
    public fun get_partner_fee_for_testing (
        royalties: Royalties
    ): (Royalties, u64) {
        let partner_fee = royalties.partner_fee;

        (royalties, partner_fee)
    }

    #[test_only]
    public fun get_partner_treasury_for_testing (
        royalties: Royalties
    ): (Royalties, address) {
        let partner_treasury = royalties.partner_treasury;

        (royalties, partner_treasury)
    }

    #[test_only]
    public fun get_protocol_fee_for_testing (
        royalties: Royalties
    ): (Royalties, u64) {
        let protocol_fee = royalties.protocol_fee;

        (royalties, protocol_fee)
    }

    #[test_only]
    public fun get_protocol_treasury_for_testing (
        royalties: Royalties
    ): (Royalties, address) {
        let protocol_treasury = royalties.protocol_treasury;

        (royalties, protocol_treasury)
    }
}
