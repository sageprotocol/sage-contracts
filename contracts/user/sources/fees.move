module sage_user::user_fees {
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

    public struct UserFees has key {
        id: UID,
        app: address,
        custom_coin_type: TypeName,
        create_invite_fee_custom: u64,
        create_invite_fee_sui: u64,
        create_user_fee_custom: u64,
        create_user_fee_sui: u64,
        follow_user_fee_custom: u64,
        follow_user_fee_sui: u64,
        friend_user_fee_custom: u64,
        friend_user_fee_sui: u64,
        post_to_user_fee_custom: u64,
        post_to_user_fee_sui: u64,
        unfollow_user_fee_custom: u64,
        unfollow_user_fee_sui: u64,
        unfriend_user_fee_custom: u64,
        unfriend_user_fee_sui: u64,
        update_user_fee_custom: u64,
        update_user_fee_sui: u64
    }

    // --------------- Events ---------------

    public struct UserFeesCreated has copy, drop {
        id: address,
        app: address,
        custom_coin_type: TypeName,
        create_invite_fee_custom: u64,
        create_invite_fee_sui: u64,
        create_user_fee_custom: u64,
        create_user_fee_sui: u64,
        follow_user_fee_custom: u64,
        follow_user_fee_sui: u64,
        friend_user_fee_custom: u64,
        friend_user_fee_sui: u64,
        post_to_user_fee_custom: u64,
        post_to_user_fee_sui: u64,
        unfollow_user_fee_custom: u64,
        unfollow_user_fee_sui: u64,
        unfriend_user_fee_custom: u64,
        unfriend_user_fee_sui: u64,
        update_user_fee_custom: u64,
        update_user_fee_sui: u64
    }

    public struct UserFeesUpdated has copy, drop {
        id: address,
        custom_coin_type: TypeName,
        create_invite_fee_custom: u64,
        create_invite_fee_sui: u64,
        create_user_fee_custom: u64,
        create_user_fee_sui: u64,
        follow_user_fee_custom: u64,
        follow_user_fee_sui: u64,
        friend_user_fee_custom: u64,
        friend_user_fee_sui: u64,
        post_to_user_fee_custom: u64,
        post_to_user_fee_sui: u64,
        unfollow_user_fee_custom: u64,
        unfollow_user_fee_sui: u64,
        unfriend_user_fee_custom: u64,
        unfriend_user_fee_sui: u64,
        update_user_fee_custom: u64,
        update_user_fee_sui: u64
    }

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun create<CoinType> (
        fee_cap: &FeeCap,
        app: &mut App,
        create_invite_fee_custom: u64,
        create_invite_fee_sui: u64,
        create_user_fee_custom: u64,
        create_user_fee_sui: u64,
        follow_user_fee_custom: u64,
        follow_user_fee_sui: u64,
        friend_user_fee_custom: u64,
        friend_user_fee_sui: u64,
        post_to_user_fee_custom: u64,
        post_to_user_fee_sui: u64,
        unfollow_user_fee_custom: u64,
        unfollow_user_fee_sui: u64,
        unfriend_user_fee_custom: u64,
        unfriend_user_fee_sui: u64,
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
            follow_user_fee_custom,
            follow_user_fee_sui,
            friend_user_fee_custom,
            friend_user_fee_sui,
            post_to_user_fee_custom,
            post_to_user_fee_sui,
            unfollow_user_fee_custom,
            unfollow_user_fee_sui,
            unfriend_user_fee_custom,
            unfriend_user_fee_sui,
            update_user_fee_custom,
            update_user_fee_sui
        };

        let fees_address = fees.id.to_address();

        apps::add_fee_config(
            fee_cap,
            app,
            utf8(b"user"),
            fees_address
        );

        event::emit(UserFeesCreated {
            id: fees_address,
            app: app_address,
            custom_coin_type,
            create_invite_fee_custom,
            create_invite_fee_sui,
            create_user_fee_custom,
            create_user_fee_sui,
            follow_user_fee_custom,
            follow_user_fee_sui,
            friend_user_fee_custom,
            friend_user_fee_sui,
            post_to_user_fee_custom,
            post_to_user_fee_sui,
            unfollow_user_fee_custom,
            unfollow_user_fee_sui,
            unfriend_user_fee_custom,
            unfriend_user_fee_sui,
            update_user_fee_custom,
            update_user_fee_sui
        });

        transfer::share_object(fees);
    }

    public fun update<CoinType> (
        _: &FeeCap,
        fees: &mut UserFees,
        create_invite_fee_custom: u64,
        create_invite_fee_sui: u64,
        create_user_fee_custom: u64,
        create_user_fee_sui: u64,
        follow_user_fee_custom: u64,
        follow_user_fee_sui: u64,
        friend_user_fee_custom: u64,
        friend_user_fee_sui: u64,
        post_to_user_fee_custom: u64,
        post_to_user_fee_sui: u64,
        unfollow_user_fee_custom: u64,
        unfollow_user_fee_sui: u64,
        unfriend_user_fee_custom: u64,
        unfriend_user_fee_sui: u64,
        update_user_fee_custom: u64,
        update_user_fee_sui: u64
    ) {
        let custom_coin_type = type_name::get<CoinType>();

        fees.custom_coin_type = custom_coin_type;
        fees.create_invite_fee_custom = create_invite_fee_custom;
        fees.create_invite_fee_sui = create_invite_fee_sui;
        fees.create_user_fee_custom = create_user_fee_custom;
        fees.create_user_fee_sui = create_user_fee_sui;
        fees.follow_user_fee_custom = follow_user_fee_custom;
        fees.follow_user_fee_sui = follow_user_fee_sui;
        fees.friend_user_fee_custom = friend_user_fee_custom;
        fees.friend_user_fee_sui = friend_user_fee_sui;
        fees.post_to_user_fee_custom = post_to_user_fee_custom;
        fees.post_to_user_fee_sui = post_to_user_fee_sui;
        fees.unfollow_user_fee_custom = unfollow_user_fee_custom;
        fees.unfollow_user_fee_sui = unfollow_user_fee_sui;
        fees.unfriend_user_fee_custom = unfriend_user_fee_custom;
        fees.unfriend_user_fee_sui = unfriend_user_fee_sui;
        fees.update_user_fee_custom = update_user_fee_custom;
        fees.update_user_fee_sui = update_user_fee_sui;

        event::emit(UserFeesUpdated {
            id: fees.id.to_address(),
            custom_coin_type,
            create_invite_fee_custom,
            create_invite_fee_sui,
            create_user_fee_custom,
            create_user_fee_sui,
            follow_user_fee_custom,
            follow_user_fee_sui,
            friend_user_fee_custom,
            friend_user_fee_sui,
            post_to_user_fee_custom,
            post_to_user_fee_sui,
            unfollow_user_fee_custom,
            unfollow_user_fee_sui,
            unfriend_user_fee_custom,
            unfriend_user_fee_sui,
            update_user_fee_custom,
            update_user_fee_sui
        });
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

    public(package) fun assert_follow_user_payment<CoinType> (
        fees: &UserFees,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>
    ): (Coin<CoinType>, Coin<SUI>) {
        assert_coin_type<CoinType>(fees);

        assert_payment<CoinType>(
            custom_payment,
            sui_payment,
            fees.follow_user_fee_custom,
            fees.follow_user_fee_sui
        )
    }

    public(package) fun assert_friend_user_payment<CoinType> (
        fees: &UserFees,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>
    ): (Coin<CoinType>, Coin<SUI>) {
        assert_coin_type<CoinType>(fees);

        assert_payment<CoinType>(
            custom_payment,
            sui_payment,
            fees.friend_user_fee_custom,
            fees.friend_user_fee_sui
        )
    }

    public(package) fun assert_post_from_user_payment<CoinType> (
        fees: &UserFees,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>
    ): (Coin<CoinType>, Coin<SUI>) {
        assert_coin_type<CoinType>(fees);

        assert_payment<CoinType>(
            custom_payment,
            sui_payment,
            fees.post_to_user_fee_custom,
            fees.post_to_user_fee_sui
        )
    }

    public(package) fun assert_unfollow_user_payment<CoinType> (
        fees: &UserFees,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>
    ): (Coin<CoinType>, Coin<SUI>) {
        assert_coin_type<CoinType>(fees);

        assert_payment<CoinType>(
            custom_payment,
            sui_payment,
            fees.unfollow_user_fee_custom,
            fees.unfollow_user_fee_sui
        )
    }

    public(package) fun assert_unfriend_user_payment<CoinType> (
        fees: &UserFees,
        custom_payment: Coin<CoinType>,
        sui_payment: Coin<SUI>
    ): (Coin<CoinType>, Coin<SUI>) {
        assert_coin_type<CoinType>(fees);

        assert_payment<CoinType>(
            custom_payment,
            sui_payment,
            fees.unfriend_user_fee_custom,
            fees.unfriend_user_fee_sui
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
}
