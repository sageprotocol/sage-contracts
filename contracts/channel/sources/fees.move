module sage_channel::channel_fees {
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

    public struct ChannelFees has key {
        id: UID,
        add_channel_moderator_fee_custom: u64,
        add_channel_moderator_fee_sui: u64,
        app: address,
        create_channel_fee_custom: u64,
        create_channel_fee_sui: u64,
        custom_coin_type: TypeName,
        join_channel_fee_custom: u64,
        join_channel_fee_sui: u64,
        leave_channel_fee_custom: u64,
        leave_channel_fee_sui: u64,
        post_to_channel_fee_custom: u64,
        post_to_channel_fee_sui: u64,
        remove_channel_moderator_fee_custom: u64,
        remove_channel_moderator_fee_sui: u64,
        update_channel_fee_custom: u64,
        update_channel_fee_sui: u64
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun create<CoinType> (
        fee_cap: &FeeCap,
        app: &mut App,
        add_channel_moderator_fee_custom: u64,
        add_channel_moderator_fee_sui: u64,
        create_channel_fee_custom: u64,
        create_channel_fee_sui: u64,
        join_channel_fee_custom: u64,
        join_channel_fee_sui: u64,
        leave_channel_fee_custom: u64,
        leave_channel_fee_sui: u64,
        post_to_channel_fee_custom: u64,
        post_to_channel_fee_sui: u64,
        remove_channel_moderator_fee_custom: u64,
        remove_channel_moderator_fee_sui: u64,
        update_channel_fee_custom: u64,
        update_channel_fee_sui: u64,
        ctx: &mut TxContext
    ) {
        let app_address = app.get_address();
        let custom_coin_type = type_name::get<CoinType>();

        let fees = ChannelFees {
            id: object::new(ctx),
            add_channel_moderator_fee_custom,
            add_channel_moderator_fee_sui,
            app: app_address,
            create_channel_fee_custom,
            create_channel_fee_sui,
            custom_coin_type,
            join_channel_fee_custom,
            join_channel_fee_sui,
            leave_channel_fee_custom,
            leave_channel_fee_sui,
            post_to_channel_fee_custom,
            post_to_channel_fee_sui,
            remove_channel_moderator_fee_custom,
            remove_channel_moderator_fee_sui,
            update_channel_fee_custom,
            update_channel_fee_sui
        };

        apps::add_fee_config(
            fee_cap,
            app,
            utf8(b"channel"),
            fees.id.to_address()
        );

        transfer::share_object(fees);
    }

    public fun update<CoinType> (
        _: &FeeCap,
        fees: &mut ChannelFees,
        add_channel_moderator_fee_custom: u64,
        add_channel_moderator_fee_sui: u64,
        create_channel_fee_custom: u64,
        create_channel_fee_sui: u64,
        join_channel_fee_custom: u64,
        join_channel_fee_sui: u64,
        leave_channel_fee_custom: u64,
        leave_channel_fee_sui: u64,
        post_to_channel_fee_custom: u64,
        post_to_channel_fee_sui: u64,
        remove_channel_moderator_fee_custom: u64,
        remove_channel_moderator_fee_sui: u64,
        update_channel_fee_custom: u64,
        update_channel_fee_sui: u64
    ) {
        let custom_coin_type = type_name::get<CoinType>();

        fees.add_channel_moderator_fee_custom = add_channel_moderator_fee_custom;
        fees.add_channel_moderator_fee_sui = add_channel_moderator_fee_sui;
        fees.create_channel_fee_custom = create_channel_fee_custom;
        fees.create_channel_fee_sui = create_channel_fee_sui;
        fees.custom_coin_type = custom_coin_type;
        fees.join_channel_fee_custom = join_channel_fee_custom;
        fees.join_channel_fee_sui = join_channel_fee_sui;
        fees.leave_channel_fee_custom = leave_channel_fee_custom;
        fees.leave_channel_fee_sui = leave_channel_fee_sui;
        fees.post_to_channel_fee_custom = post_to_channel_fee_custom;
        fees.post_to_channel_fee_sui = post_to_channel_fee_sui;
        fees.remove_channel_moderator_fee_custom = remove_channel_moderator_fee_custom;
        fees.remove_channel_moderator_fee_sui = remove_channel_moderator_fee_sui;
        fees.update_channel_fee_custom = update_channel_fee_custom;
        fees.update_channel_fee_sui = update_channel_fee_sui;
    }

    // --------------- Friend Functions ---------------

    public(package) fun assert_add_moderator_owner_payment<CoinType> (
        fees: &ChannelFees,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>
    ): (Coin<CoinType>, Coin<SUI>) {
        assert_coin_type<CoinType>(fees);

        assert_payment<CoinType>(
            custom_payment,
            sui_payment,
            fees.add_channel_moderator_fee_custom,
            fees.add_channel_moderator_fee_sui
        )
    }

    public(package) fun assert_create_channel_payment<CoinType> (
        fees: &ChannelFees,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>
    ): (Coin<CoinType>, Coin<SUI>) {
        assert_coin_type<CoinType>(fees);

        assert_payment<CoinType>(
            custom_payment,
            sui_payment,
            fees.create_channel_fee_custom,
            fees.create_channel_fee_sui
        )
    }

    public(package) fun assert_join_channel_payment<CoinType> (
        fees: &ChannelFees,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>
    ): (Coin<CoinType>, Coin<SUI>) {
        assert_coin_type<CoinType>(fees);

        assert_payment<CoinType>(
            custom_payment,
            sui_payment,
            fees.join_channel_fee_custom,
            fees.join_channel_fee_sui
        )
    }

    public(package) fun assert_leave_channel_payment<CoinType> (
        fees: &ChannelFees,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>
    ): (Coin<CoinType>, Coin<SUI>) {
        assert_coin_type<CoinType>(fees);

        assert_payment<CoinType>(
            custom_payment,
            sui_payment,
            fees.leave_channel_fee_custom,
            fees.leave_channel_fee_sui
        )
    }

    public(package) fun assert_post_to_channel_payment<CoinType> (
        fees: &ChannelFees,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>
    ): (Coin<CoinType>, Coin<SUI>) {
        assert_coin_type<CoinType>(fees);

        assert_payment<CoinType>(
            custom_payment,
            sui_payment,
            fees.post_to_channel_fee_custom,
            fees.post_to_channel_fee_sui
        )
    }

    public(package) fun assert_remove_moderator_owner_payment<CoinType> (
        fees: &ChannelFees,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>
    ): (Coin<CoinType>, Coin<SUI>) {
        assert_coin_type<CoinType>(fees);

        assert_payment<CoinType>(
            custom_payment,
            sui_payment,
            fees.remove_channel_moderator_fee_custom,
            fees.remove_channel_moderator_fee_sui
        )
    }

    public(package) fun assert_update_channel_payment<CoinType> (
        fees: &ChannelFees,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>
    ): (Coin<CoinType>, Coin<SUI>) {
        assert_coin_type<CoinType>(fees);

        assert_payment<CoinType>(
            custom_payment,
            sui_payment,
            fees.update_channel_fee_custom,
            fees.update_channel_fee_sui
        )
    }

    // --------------- Internal Functions ---------------

    fun assert_coin_type<CoinType> (
        fees: &ChannelFees
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
