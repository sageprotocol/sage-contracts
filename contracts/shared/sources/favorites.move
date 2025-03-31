module sage_shared::favorites {
    use sui::{
        table::{Self, Table}
    };

    // --------------- Constants ---------------

    const FAVORITE: u8 = 1;

    // --------------- Errors ---------------

    const EAlreadyFavorited: u64 = 370;

    // --------------- Name Tag ---------------

    public struct Favorites has store {
        favorites: Table<address, u8>
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun add(
        favorites: &mut Favorites,
        key: address
    ) {
        favorites.favorites.add(key, FAVORITE);
    }

    public fun assert_has_not_favorited(
        favorites: &Favorites,
        key: address
    ) {
        let has_favorited = has_favorited(
            favorites,
            key
        );

        assert!(!has_favorited, EAlreadyFavorited);
    }

    public fun create(
        ctx: &mut TxContext
    ): Favorites {
        let favorites = Favorites {
            favorites: table::new(ctx)
        };

        favorites
    }

    public fun get_length(
        favorites: &Favorites
    ): u64 {
        favorites.favorites.length()
    }

    public fun has_favorited(
        favorites: &Favorites,
        key: address
    ): bool {
        favorites.favorites.contains(key)
    }

    public fun remove(
        favorites: &mut Favorites,
        key: address
    ) {
        favorites.favorites.remove(key);
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
