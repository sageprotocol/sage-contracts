module sage_user::user_fees {
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

    // --------------- Errors ---------------

    const EIncorrectCoinType: u64 = 370;
    const EIncorrectCustomPayment: u64 = 371;
    const EIncorrectSuiPayment: u64 = 372;

    // --------------- Name Tag ---------------

    public struct UserFees has key {
        id: UID,
        app: address,
        custom_coin_type: TypeName,
        create_invite_fee_custom: u64,
        create_invite_fee_sui: u64,
        create_user_fee_custom: u64,
        create_user_fee_sui: u64,
        join_user_fee_custom: u64,
        join_user_fee_sui: u64,
        leave_user_fee_custom: u64,
        leave_user_fee_sui: u64,
        update_user_fee_custom: u64,
        update_user_fee_sui: u64
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun create<CoinType> (
        fee_cap: &FeeCap,
        app: &mut App,
        create_invite_fee_custom: u64,
        create_invite_fee_sui: u64,
        create_user_fee_custom: u64,
        create_user_fee_sui: u64,
        join_user_fee_custom: u64,
        join_user_fee_sui: u64,
        leave_user_fee_custom: u64,
        leave_user_fee_sui: u64,
        update_user_fee_custom: u64,
        update_user_fee_sui: u64,
        ctx: &mut TxContext
    ) {
        let app_address = app.get_address();
        let custom_coin_type = type_name::get<CoinType>();

        let fees = UserFees {
            id: object::new(ctx),
            app: app_address,
            custom_coin_type,
            create_invite_fee_custom,
            create_invite_fee_sui,
            create_user_fee_custom,
            create_user_fee_sui,
            join_user_fee_custom,
            join_user_fee_sui,
            leave_user_fee_custom,
            leave_user_fee_sui,
            update_user_fee_custom,
            update_user_fee_sui
        };

        apps::add_fee_config(
            fee_cap,
            app,
            utf8(b"user"),
            fees.id.to_address()
        );

        transfer::share_object(fees);
    }

    public fun update<CoinType> (
        _: &FeeCap,
        fees: &mut UserFees,
        create_invite_fee_custom: u64,
        create_invite_fee_sui: u64,
        create_user_fee_custom: u64,
        create_user_fee_sui: u64,
        join_user_fee_custom: u64,
        join_user_fee_sui: u64,
        leave_user_fee_custom: u64,
        leave_user_fee_sui: u64,
        update_user_fee_custom: u64,
        update_user_fee_sui: u64
    ) {
        let custom_coin_type = type_name::get<CoinType>();

        fees.custom_coin_type = custom_coin_type;
        fees.create_invite_fee_custom = create_invite_fee_custom;
        fees.create_invite_fee_sui = create_invite_fee_sui;
        fees.create_user_fee_custom = create_user_fee_custom;
        fees.create_user_fee_sui = create_user_fee_sui;
        fees.join_user_fee_custom = join_user_fee_custom;
        fees.join_user_fee_sui = join_user_fee_sui;
        fees.leave_user_fee_custom = leave_user_fee_custom;
        fees.leave_user_fee_sui = leave_user_fee_sui;
        fees.update_user_fee_custom = update_user_fee_custom;
        fees.update_user_fee_sui = update_user_fee_sui;
    }

    // --------------- Friend Functions ---------------

    public(package) fun assert_create_invite_payment<CoinType> (
        fees: &UserFees,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>
    ): (Coin<CoinType>, Coin<SUI>) {
        assert_coin_type<CoinType>(fees);

        assert_payment<CoinType>(
            custom_payment,
            sui_payment,
            fees.create_invite_fee_custom,
            fees.create_invite_fee_sui
        )
    }

    public(package) fun assert_create_user_payment<CoinType> (
        fees: &UserFees,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>
    ): (Coin<CoinType>, Coin<SUI>) {
        assert_coin_type<CoinType>(fees);

        assert_payment<CoinType>(
            custom_payment,
            sui_payment,
            fees.create_user_fee_custom,
            fees.create_user_fee_sui
        )
    }

    public(package) fun assert_join_user_payment<CoinType> (
        fees: &UserFees,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>
    ): (Coin<CoinType>, Coin<SUI>) {
        assert_coin_type<CoinType>(fees);

        assert_payment<CoinType>(
            custom_payment,
            sui_payment,
            fees.join_user_fee_custom,
            fees.join_user_fee_sui
        )
    }

    public(package) fun assert_leave_user_payment<CoinType> (
        fees: &UserFees,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>
    ): (Coin<CoinType>, Coin<SUI>) {
        assert_coin_type<CoinType>(fees);

        assert_payment<CoinType>(
            custom_payment,
            sui_payment,
            fees.leave_user_fee_custom,
            fees.leave_user_fee_sui
        )
    }

    public(package) fun assert_update_user_payment<CoinType> (
        fees: &UserFees,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>
    ): (Coin<CoinType>, Coin<SUI>) {
        assert_coin_type<CoinType>(fees);

        assert_payment<CoinType>(
            custom_payment,
            sui_payment,
            fees.update_user_fee_custom,
            fees.update_user_fee_sui
        )
    }

    // --------------- Internal Functions ---------------

    fun assert_coin_type<CoinType> (
        fees: &UserFees
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

    #[test_only]
    public fun create_for_testing<CoinType> (
        app: &mut App,
        create_invite_fee_custom: u64,
        create_invite_fee_sui: u64,
        create_user_fee_custom: u64,
        create_user_fee_sui: u64,
        join_user_fee_custom: u64,
        join_user_fee_sui: u64,
        leave_user_fee_custom: u64,
        leave_user_fee_sui: u64,
        update_user_fee_custom: u64,
        update_user_fee_sui: u64,
        ctx: &mut TxContext
    ): UserFees {
        let app_address = app.get_address();
        let custom_coin_type = type_name::get<CoinType>();

        UserFees {
            id: object::new(ctx),
            app: app_address,
            custom_coin_type,
            create_invite_fee_custom,
            create_invite_fee_sui,
            create_user_fee_custom,
            create_user_fee_sui,
            join_user_fee_custom,
            join_user_fee_sui,
            leave_user_fee_custom,
            leave_user_fee_sui,
            update_user_fee_custom,
            update_user_fee_sui
        }
    }
}
