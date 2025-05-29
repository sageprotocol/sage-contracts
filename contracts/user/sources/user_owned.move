module sage_user::user_owned {
    use std::{
        string::{String}
    };

    use sui::{
        dynamic_field::{Self as df},
        dynamic_object_field::{Self as dof}
    };

    use sage_admin::{
        admin_access::{
            Self,
            ChannelWitnessConfig,
            UserWitnessConfig
        },
        apps::{App}
    };

    use sage_analytics::{
        analytics::{Analytics},
        analytics_actions::{Self}
    };

    use sage_post::{
        post::{Post}
    };

    use sage_user::{
        user_shared::{UserShared},
        user_witness::{Self}
    };

    use sage_shared::{
        favorites::{Self, Favorites}
    };

    // --------------- Constants ---------------

    const FAVORITE_ADD: u8 = 10;
    const FAVORITE_REMOVE: u8 = 11;

    // --------------- Errors ---------------

    const ENoAppFavorites: u64 = 370;

    // --------------- Name Tag ---------------

    public struct AnalyticsKey has copy, drop, store {
        app: address,
        epoch: u64
    }

    public struct ChannelFavoritesKey has copy, drop, store {
        app: address
    }

    public struct PostFavoritesKey has copy, drop, store {
        app: address
    }

    public struct UserFavoritesKey has copy, drop, store {
        app: address
    }

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

    public fun borrow_analytics_mut_for_channel<ChannelWitness: drop>(
        channel_witness: &ChannelWitness,
        channel_witness_config: &ChannelWitnessConfig,
        owned_user: &mut UserOwned,
        user_witness_config: &UserWitnessConfig,
        app_address: address,
        epoch: u64,
        ctx: &mut TxContext
    ): &mut Analytics {
        admin_access::assert_channel_witness<ChannelWitness>(
            channel_witness_config,
            channel_witness
        );

        borrow_or_create_analytics_mut(
            owned_user,
            user_witness_config,
            app_address,
            epoch,
            ctx
        )
    }

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
        let app_address = object::id_address(app);

        let favorites_key = ChannelFavoritesKey {
            app: app_address
        };

        let does_exist = df::exists_with_type<ChannelFavoritesKey, Favorites>(
            &user.id,
            favorites_key
        );

        if (does_exist) {
            let favorites = df::borrow<ChannelFavoritesKey, Favorites>(
                &user.id,
                favorites_key
            );

            favorites.get_length()
        } else {
            0
        }
    }

    public fun get_post_favorites_length(
        app: &App,
        user: &UserOwned
    ): u64 {
        let app_address = object::id_address(app);

        let favorites_key = PostFavoritesKey {
            app: app_address
        };

        let does_exist = df::exists_with_type<PostFavoritesKey, Favorites>(
            &user.id,
            favorites_key
        );

        if (does_exist) {
            let favorites = df::borrow<PostFavoritesKey, Favorites>(
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
        let app_address = object::id_address(app);

        let favorites_key = UserFavoritesKey {
            app: app_address
        };

        let does_exist = df::exists_with_type<UserFavoritesKey, Favorites>(
            &user.id,
            favorites_key
        );

        if (does_exist) {
            let favorites = df::borrow<UserFavoritesKey, Favorites>(
                &user.id,
                favorites_key
            );

            favorites.get_length()
        } else {
            0
        }
    }

    public fun has_analytics(
        owned_user: &mut UserOwned,
        app_address: address,
        epoch: u64,
    ): bool {
        let analytics_key = AnalyticsKey {
            app: app_address,
            epoch
        };

        dof::exists_with_type<AnalyticsKey, Analytics>(
            &owned_user.id,
            analytics_key
        )
    }

    // --------------- Friend Functions ---------------

    public(package) fun add_favorite_channel<ChannelType: key>(
        channel: &ChannelType,
        owned_user: &mut UserOwned,
        app_address: address,
        timestamp: u64,
        ctx: &mut TxContext
    ): (
        u8,
        address,
        address,
        u64
    ) {
        let favorites_key = ChannelFavoritesKey {
            app: app_address
        };

        let does_exist = df::exists_with_type<ChannelFavoritesKey, Favorites>(
            &owned_user.id,
            favorites_key
        );

        let favorite_channel_address = object::id_address(channel);

        let count = if (does_exist) {
            let favorites = df::borrow_mut<ChannelFavoritesKey, Favorites>(
                &mut owned_user.id,
                favorites_key
            );

            favorites.add(
                favorite_channel_address,
                timestamp
            )
        } else {
            let mut favorites = favorites::create(ctx);

            let count = favorites.add(
                favorite_channel_address,
                timestamp
            );

            df::add(
                &mut owned_user.id,
                favorites_key,
                favorites
            );

            count
        };

        let self = tx_context::sender(ctx);

        (
            FAVORITE_ADD,
            self,
            favorite_channel_address,
            count
        )
    }

    public(package) fun add_favorite_post(
        post: &Post,
        owned_user: &mut UserOwned,
        app_address: address,
        timestamp: u64,
        ctx: &mut TxContext
    ): (
        u8,
        address,
        address,
        u64
    ) {
        let favorites_key = PostFavoritesKey {
            app: app_address
        };

        let does_exist = df::exists_with_type<PostFavoritesKey, Favorites>(
            &owned_user.id,
            favorites_key
        );

        let favorite_post_address = object::id_address(post);

        let count = if (does_exist) {
            let favorites = df::borrow_mut<PostFavoritesKey, Favorites>(
                &mut owned_user.id,
                favorites_key
            );

            favorites.add(
                favorite_post_address,
                timestamp
            )
        } else {
            let mut favorites = favorites::create(ctx);

            let count = favorites.add(
                favorite_post_address,
                timestamp
            );

            df::add(
                &mut owned_user.id,
                favorites_key,
                favorites
            );

            count
        };

        let self = tx_context::sender(ctx);

        (
            FAVORITE_ADD,
            self,
            favorite_post_address,
            count
        )
    }

    public(package) fun add_favorite_user(
        owned_user: &mut UserOwned,
        user: &UserShared,
        app_address: address,
        timestamp: u64,
        ctx: &mut TxContext
    ): (
        u8,
        address,
        address,
        u64
    ) {
        let favorites_key = UserFavoritesKey {
            app: app_address
        };

        let does_exist = df::exists_with_type<UserFavoritesKey, Favorites>(
            &owned_user.id,
            favorites_key
        );

        let favorite_user_wallet_address = user.get_owner();

        let count = if (does_exist) {
            let favorites = df::borrow_mut<UserFavoritesKey, Favorites>(
                &mut owned_user.id,
                favorites_key
            );

            favorites.add(
                favorite_user_wallet_address,
                timestamp
            )
        } else {
            let mut favorites = favorites::create(ctx);

            let count = favorites.add(
                favorite_user_wallet_address,
                timestamp
            );

            df::add(
                &mut owned_user.id,
                favorites_key,
                favorites
            );

            count
        };

        let self = tx_context::sender(ctx);

        (
            FAVORITE_ADD,
            self,
            favorite_user_wallet_address,
            count
        )
    }

    public(package) fun borrow_analytics_mut(
        owned_user: &mut UserOwned,
        app_address: address,
        epoch: u64
    ): &mut Analytics {
        let analytics_key = AnalyticsKey {
            app: app_address,
            epoch
        };

        dof::borrow_mut<AnalyticsKey, Analytics>(
            &mut owned_user.id,
            analytics_key
        )
    }

    public(package) fun borrow_or_create_analytics_mut(
        owned_user: &mut UserOwned,
        user_witness_config: &UserWitnessConfig,
        app_address: address,
        epoch: u64,
        ctx: &mut TxContext
    ): &mut Analytics {
        let analytics_key = AnalyticsKey {
            app: app_address,
            epoch
        };

        let does_exist = dof::exists_with_type<AnalyticsKey, Analytics>(
            &owned_user.id,
            analytics_key
        );

        if (!does_exist) {
            let user_witness = user_witness::create_witness();

            let analytics = analytics_actions::create_analytics_for_user(
                &user_witness,
                user_witness_config,
                ctx
            );

            dof::add(
                &mut owned_user.id,
                analytics_key,
                analytics
            );
        };

        dof::borrow_mut<AnalyticsKey, Analytics>(
            &mut owned_user.id,
            analytics_key
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
        channel: &ChannelType,
        owned_user: &mut UserOwned,
        app_address: address,
        timestamp: u64,
        ctx: &TxContext
    ): (
        u8,
        address,
        address,
        u64
    ) {
        let favorites_key = ChannelFavoritesKey {
            app: app_address
        };

        let does_exist = df::exists_with_type<ChannelFavoritesKey, Favorites>(
            &owned_user.id,
            favorites_key
        );

        assert!(does_exist, ENoAppFavorites);

        let favorite_channel_address = object::id_address(channel);

        let favorites = df::borrow_mut<ChannelFavoritesKey, Favorites>(
            &mut owned_user.id,
            favorites_key
        );

        let count = favorites.remove(
            favorite_channel_address,
            timestamp
        );

        let self = tx_context::sender(ctx);

        (
            FAVORITE_REMOVE,
            self,
            favorite_channel_address,
            count
        )
    }

    public(package) fun remove_favorite_post(
        post: &Post,
        owned_user: &mut UserOwned,
        app_address: address,
        timestamp: u64,
        ctx: &TxContext
    ): (
        u8,
        address,
        address,
        u64
    ) {
        let favorites_key = PostFavoritesKey {
            app: app_address
        };

        let does_exist = df::exists_with_type<PostFavoritesKey, Favorites>(
            &owned_user.id,
            favorites_key
        );

        assert!(does_exist, ENoAppFavorites);

        let favorite_post_address = object::id_address(post);

        let favorites = df::borrow_mut<PostFavoritesKey, Favorites>(
            &mut owned_user.id,
            favorites_key
        );

        let count = favorites.remove(
            favorite_post_address,
            timestamp
        );

        let self = tx_context::sender(ctx);

        (
            FAVORITE_REMOVE,
            self,
            favorite_post_address,
            count
        )
    }

    public(package) fun remove_favorite_user(
        owned_user: &mut UserOwned,
        user: &UserShared,
        app_address: address,
        timestamp: u64,
        ctx: &TxContext
    ): (
        u8,
        address,
        address,
        u64
    ) {
        let favorites_key = UserFavoritesKey {
            app: app_address
        };

        let does_exist = df::exists_with_type<UserFavoritesKey, Favorites>(
            &owned_user.id,
            favorites_key
        );

        assert!(does_exist, ENoAppFavorites);

        let favorite_user_wallet_address = user.get_owner();

        let favorites = df::borrow_mut<UserFavoritesKey, Favorites>(
            &mut owned_user.id,
            favorites_key
        );

        let count = favorites.remove(
            favorite_user_wallet_address,
            timestamp
        );

        let self = tx_context::sender(ctx);

        (
            FAVORITE_REMOVE,
            self,
            favorite_user_wallet_address,
            count
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
