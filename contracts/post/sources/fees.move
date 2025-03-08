module sage_post::post_fees {
    use std::{
        string::{utf8},
        type_name::{Self, TypeName}
    };

    use sui::{
        coin::{Coin},
        event,
        sui::{SUI}
    };

    use sage_admin::{
        admin::{FeeCap},
        apps::{Self, App}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EIncorrectCoinType: u64 = 370;
    const EIncorrectCustomPayment: u64 = 371;
    const EIncorrectSuiPayment: u64 = 372;

    // --------------- Name Tag ---------------

    public struct PostFees has key {
        id: UID,
        app: address,
        custom_coin_type: TypeName,
        like_post_fee_custom: u64,
        like_post_fee_sui: u64,
        post_from_post_fee_custom: u64,
        post_from_post_fee_sui: u64
    }

    // --------------- Events ---------------

    public struct PostFeesCreated has copy, drop {
        id: address,
        app: address,
        custom_coin_type: TypeName,
        like_post_fee_custom: u64,
        like_post_fee_sui: u64,
        post_from_post_fee_custom: u64,
        post_from_post_fee_sui: u64
    }

    public struct PostFeesUpdated has copy, drop {
        id: address,
        custom_coin_type: TypeName,
        like_post_fee_custom: u64,
        like_post_fee_sui: u64,
        post_from_post_fee_custom: u64,
        post_from_post_fee_sui: u64
    }

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun create<CoinType> (
        fee_cap: &FeeCap,
        app: &mut App,
        like_post_fee_custom: u64,
        like_post_fee_sui: u64,
        post_from_post_fee_custom: u64,
        post_from_post_fee_sui: u64,
        ctx: &mut TxContext
    ) {
        let app_address = app.get_address();
        let custom_coin_type = type_name::get<CoinType>();

        let fees = PostFees {
            id: object::new(ctx),
            app: app_address,
            custom_coin_type,
            like_post_fee_custom,
            like_post_fee_sui,
            post_from_post_fee_custom,
            post_from_post_fee_sui
        };

        let fees_address = fees.id.to_address();

        apps::add_fee_config(
            fee_cap,
            app,
            utf8(b"post"),
            fees_address
        );

        event::emit(PostFeesCreated {
            id: fees_address,
            app: app_address,
            custom_coin_type,
            like_post_fee_custom,
            like_post_fee_sui,
            post_from_post_fee_custom,
            post_from_post_fee_sui
        });

        transfer::share_object(fees);
    }

    public fun update<CoinType> (
        _: &FeeCap,
        fees: &mut PostFees,
        like_post_fee_custom: u64,
        like_post_fee_sui: u64,
        post_from_post_fee_custom: u64,
        post_from_post_fee_sui: u64
    ) {
        let custom_coin_type = type_name::get<CoinType>();

        fees.custom_coin_type = custom_coin_type;
        fees.like_post_fee_custom = like_post_fee_custom;
        fees.like_post_fee_sui = like_post_fee_sui;
        fees.post_from_post_fee_custom = post_from_post_fee_custom;
        fees.post_from_post_fee_sui = post_from_post_fee_sui;

        event::emit(PostFeesUpdated {
            id: fees.id.to_address(),
            custom_coin_type,
            like_post_fee_custom,
            like_post_fee_sui,
            post_from_post_fee_custom,
            post_from_post_fee_sui
        });
    }

    // --------------- Friend Functions ---------------

    public(package) fun assert_like_post_payment<CoinType> (
        fees: &PostFees,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>
    ): (Coin<CoinType>, Coin<SUI>) {
        assert_coin_type<CoinType>(fees);

        assert_payment<CoinType>(
            custom_payment,
            sui_payment,
            fees.like_post_fee_custom,
            fees.like_post_fee_sui
        )
    }

    public(package) fun assert_post_from_post_payment<CoinType> (
        fees: &PostFees,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>
    ): (Coin<CoinType>, Coin<SUI>) {
        assert_coin_type<CoinType>(fees);

        assert_payment<CoinType>(
            custom_payment,
            sui_payment,
            fees.post_from_post_fee_custom,
            fees.post_from_post_fee_sui
        )
    }

    // --------------- Internal Functions ---------------

    fun assert_coin_type<CoinType> (
        fees: &PostFees
    ) {
        let custom_coin_type = type_name::get<CoinType>();

        assert!(custom_coin_type == fees.custom_coin_type, EIncorrectCoinType);
    }

    fun assert_payment<CoinType> (
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>,
        custom_fee: u64,
        sui_fee: u64
    ): (Coin<CoinType>, Coin<SUI>) {
        assert!(custom_payment.value() == custom_fee, EIncorrectCustomPayment);
        assert!(sui_payment.value() == sui_fee, EIncorrectSuiPayment);

        (custom_payment, sui_payment)
    }

    // --------------- Test Functions ---------------

}
