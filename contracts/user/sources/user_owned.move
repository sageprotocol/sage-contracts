module sage_user::user_owned {
    use std::{
        string::{String, utf8}
    };

    use sui::{
        dynamic_field::{Self as df}
    };

    use sage_admin::{
        apps::{Self, App}
    };

    use sage_user::{
        user_shared::{UserShared}
    };

    use sage_shared::{
        favorites::{Self, Favorites}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const ENoAppFavorites: u64 = 370;

    // --------------- Name Tag ---------------

    public struct UserOwned has key {
        id: UID,
        avatar: String,
        banner: String,
        created_at: u64,
        description: String,
        key: String,
        name: String,
        owner: address,
        shared_user: address,
        total_earnings: u64,
        updated_at: u64
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun get_avatar(
        owned_user: &UserOwned
    ): String {
        owned_user.avatar
    }

    public fun get_banner(
        owned_user: &UserOwned
    ): String {
        owned_user.banner
    }

    public fun get_description(
        owned_user: &UserOwned
    ): String {
        owned_user.description
    }

    public fun get_key(
        owned_user: &UserOwned
    ): String {
        owned_user.key
    }

    public fun get_name(
        owned_user: &UserOwned
    ): String {
        owned_user.name
    }

    public fun get_owner(
        owned_user: &UserOwned
    ): address {
        owned_user.owner
    }

    public fun get_shared_user(
        owned_user: &UserOwned
    ): address {
        owned_user.shared_user
    }

    public fun get_channel_favorites_length(
        app: &App,
        user: &UserOwned
    ): u64 {
        let (
            favorites_key,
            _app_name
        ) = apps::create_app_specific_string(
            app,
            utf8(b"favorite-channels")
        );

        let does_exist = df::exists_with_type<String, Favorites>(
            &user.id,
            favorites_key
        );

        if (does_exist) {
            let favorites = df::borrow<String, Favorites>(
                &user.id,
                favorites_key
            );

            favorites.get_length()
        } else {
            0
        }
    }

    public fun get_user_favorites_length(
        app: &App,
        user: &UserOwned
    ): u64 {
        let (
            favorites_key,
            _app_name
        ) = apps::create_app_specific_string(
            app,
            utf8(b"favorite-users")
        );

        let does_exist = df::exists_with_type<String, Favorites>(
            &user.id,
            favorites_key
        );

        if (does_exist) {
            let favorites = df::borrow<String, Favorites>(
                &user.id,
                favorites_key
            );

            favorites.get_length()
        } else {
            0
        }
    }

    // --------------- Friend Functions ---------------

    // ADD FAVORITES TO ACTIONS!!!!

    public(package) fun add_favorite_channel<ChannelType: key>(
        app: &App,
        channel: &ChannelType,
        owned_user: &mut UserOwned,
        ctx: &mut TxContext
    ): (String, address, address) {
        let (
            favorites_key,
            app_name
        ) = apps::create_app_specific_string(
            app,
            utf8(b"favorite-channels")
        );

        let does_exist = df::exists_with_type<String, Favorites>(
            &owned_user.id,
            favorites_key
        );

        let favorite_channel_address = object::id_address(channel);

        if (does_exist) {
            let favorites = df::borrow_mut<String, Favorites>(
                &mut owned_user.id,
                favorites_key
            );

            favorites.add(favorite_channel_address);
        } else {
            let mut favorites = favorites::create(ctx);

            favorites.add(favorite_channel_address);

            df::add(
                &mut owned_user.id,
                favorites_key,
                favorites
            );
        };

        (
            app_name,
            owned_user.id.to_address(),
            favorite_channel_address
        )
    }

    // public(package) fun add_favorite_channel_from_favorites<ChannelType: key>(
    //     app: &App,
    //     channel: &ChannelType,
    //     owned_user: &UserOwned,
    //     favorites: &mut Favorites
    // ): (String, address, address) {
    //     let (
    //         favorites_key,
    //         app_name
    //     ) = apps::create_app_specific_string(
    //         app,
    //         utf8(b"favorite-channels")
    //     );

    //     let favorite_channel_address = object::id_address(channel);

    //     let retrieved_favorites = dof::borrow<String, Favorites>(
    //         &owned_user.id,
    //         favorites_key
    //     );

    //     assert!(
    //         object::id_address(favorites) == object::id_address(retrieved_favorites),
    //         EFavoritesMismatch
    //     );

    //     favorites.add(favorite_channel_address);

    //     (
    //         app_name,
    //         owned_user.id.to_address(),
    //         favorite_channel_address
    //     )
    // }

    public(package) fun add_favorite_user(
        app: &App,
        owned_user: &mut UserOwned,
        user: &UserShared,
        ctx: &mut TxContext
    ): (String, address, address) {
        let (
            favorites_key,
            app_name
        ) = apps::create_app_specific_string(
            app,
            utf8(b"favorite-users")
        );

        let does_exist = df::exists_with_type<String, Favorites>(
            &owned_user.id,
            favorites_key
        );

        let favorite_user_wallet_address = user.get_owner();

        if (does_exist) {
            let favorites = df::borrow_mut<String, Favorites>(
                &mut owned_user.id,
                favorites_key
            );

            favorites.add(favorite_user_wallet_address);
        } else {
            let mut favorites = favorites::create(ctx);

            favorites.add(favorite_user_wallet_address);

            df::add(
                &mut owned_user.id,
                favorites_key,
                favorites
            );
        };

        (
            app_name,
            owned_user.id.to_address(),
            favorite_user_wallet_address
        )
    }

    public(package) fun create(
        avatar: String,
        banner: String,
        created_at: u64,
        description: String,
        key: String,
        name: String,
        owner: address,
        ctx: &mut TxContext
    ): (UserOwned, address) {
        let owned_user = UserOwned {
            id: object::new(ctx),
            avatar,
            banner,
            created_at,
            description,
            key,
            name,
            owner,
            shared_user: @0x0,
            total_earnings: 0,
            updated_at: created_at
        };

        let owned_user_address = owned_user.id.to_address();

        (
            owned_user,
            owned_user_address
        )
    }

    public(package) fun remove_favorite_channel<ChannelType: key>(
        app: &App,
        channel: &ChannelType,
        owned_user: &mut UserOwned
    ): (String, address, address) {
        let (
            favorites_key,
            app_name
        ) = apps::create_app_specific_string(
            app,
            utf8(b"favorite-channels")
        );

        let does_exist = df::exists_with_type<String, Favorites>(
            &owned_user.id,
            favorites_key
        );

        assert!(does_exist, ENoAppFavorites);

        let favorite_channel_address = object::id_address(channel);

        let favorites = df::borrow_mut<String, Favorites>(
            &mut owned_user.id,
            favorites_key
        );

        favorites.remove(favorite_channel_address);

        (
            app_name,
            owned_user.id.to_address(),
            favorite_channel_address
        )
    }

    public(package) fun remove_favorite_user(
        app: &App,
        owned_user: &mut UserOwned,
        user: &UserShared
    ): (String, address, address) {
        let (
            favorites_key,
            app_name
        ) = apps::create_app_specific_string(
            app,
            utf8(b"favorite-users")
        );

        let does_exist = df::exists_with_type<String, Favorites>(
            &owned_user.id,
            favorites_key
        );

        assert!(does_exist, ENoAppFavorites);

        let favorite_user_address = user.get_owner();

        let favorites = df::borrow_mut<String, Favorites>(
            &mut owned_user.id,
            favorites_key
        );

        favorites.remove(favorite_user_address);

        (
            app_name,
            owned_user.id.to_address(),
            favorite_user_address
        )
    }

    public(package) fun set_shared_user(
        mut owned_user: UserOwned,
        owner: address,
        shared_user_address: address
    ) {
        owned_user.shared_user = shared_user_address;

        transfer::transfer(owned_user, owner);
    }

    public(package) fun update(
        owned_user: &mut UserOwned,
        avatar: String,
        banner: String,
        description: String,
        name: String,
        updated_at: u64
    ) {
        owned_user.avatar = avatar;
        owned_user.banner = banner;
        owned_user.description = description;
        owned_user.name = name;
        owned_user.updated_at = updated_at;
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
