module sage_shared::favorites {
    use sui::{
        table::{Self, Table}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EAlreadyFavorited: u64 = 370;
    const EIsNotFavorite: u64 = 371;

    // --------------- Name Tag ---------------

    public struct Favorite has store {
        count: u64,
        created_at: u64,
        is_favorite: bool,
        updated_at: u64
    }

    public struct Favorites has store {
        current_favorites: u64,
        favorites: Table<address, Favorite>
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun add(
        favorites: &mut Favorites,
        key: address,
        timestamp: u64
    ): u64 {
        let does_exist = favorites.favorites.contains(key);
        let mut favorite_count = 1;

        if (does_exist) {
            let favorite = favorites.favorites.borrow_mut(key);

            assert!(!favorite.is_favorite, EAlreadyFavorited);

            favorite.count = favorite.count + 1;
            favorite.is_favorite = true;
            favorite.updated_at = timestamp;

            favorite_count = favorite.count;
        } else {
            let favorite = Favorite {
                count: favorite_count,
                created_at: timestamp,
                is_favorite: true,
                updated_at: timestamp
            };

            favorites.favorites.add(key, favorite);
        };

        favorites.current_favorites = favorites.current_favorites + 1;

        favorite_count
    }

    public fun assert_has_not_favorited(
        favorites: &Favorites,
        key: address
    ) {
        let is_favorite = is_favorite(
            favorites,
            key
        );

        assert!(!is_favorite, EAlreadyFavorited);
    }

    public fun create(
        ctx: &mut TxContext
    ): Favorites {
        let favorites = Favorites {
            current_favorites: 0,
            favorites: table::new(ctx)
        };

        favorites
    }

    public fun get_count(
        favorites: &Favorites,
        key: address
    ): u64 {
        favorites.favorites[key].count
    }

    public fun get_created_at(
        favorites: &Favorites,
        key: address
    ): u64 {
        favorites.favorites[key].created_at
    }

    public fun get_length(
        favorites: &Favorites
    ): u64 {
        favorites.current_favorites
    }

    public fun get_updated_at(
        favorites: &Favorites,
        key: address
    ): u64 {
        favorites.favorites[key].updated_at
    }

    public fun is_favorite(
        favorites: &Favorites,
        key: address
    ): bool {
        favorites.favorites.contains(key) &&
        favorites.favorites[key].is_favorite
    }

    public fun remove(
        favorites: &mut Favorites,
        key: address,
        timestamp: u64
    ): u64 {
        let favorite = favorites.favorites.borrow_mut(key);

        assert!(favorite.is_favorite, EIsNotFavorite);

        favorite.is_favorite = false;
        favorite.updated_at = timestamp;

        favorites.current_favorites = favorites.current_favorites - 1;

        favorite.count
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
