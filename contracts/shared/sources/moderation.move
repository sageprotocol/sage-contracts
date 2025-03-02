module sage_shared::moderation {
    use sui::{
        table::{Self, Table}
    };

    // --------------- Constants ---------------

    const OWNER: u8 = 0;
    const MODERATOR: u8 = 1;

    const MODERATOR_ADD: u8 = 10;
    const MODERATOR_REMOVE: u8 = 11;

    // --------------- Errors ---------------

    const EIsOwner: u64 = 370;
    const EIsNotModerator: u64 = 371;
    const EIsNotOwner: u64 = 372;

    // --------------- Name Tag ---------------

    public struct Moderation has store {
        moderation: Table<address, u8>
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun assert_is_moderator(
        moderation: &Moderation,
        user: address
    ) {
        let is_moderator = is_moderator(
            moderation,
            user
        );

        assert!(is_moderator, EIsNotModerator);
    }

    public fun assert_is_owner(
        moderation: &Moderation,
        user: address
    ) {
        let is_owner = is_owner(
            moderation,
            user
        );

        assert!(is_owner, EIsNotOwner);
    }

    public fun create(
        ctx: &mut TxContext
    ): (Moderation, u8, u8) {
        let self = tx_context::sender(ctx);

        let mut moderation = Moderation {
            moderation: table::new(ctx)
        };

        let (event, message) = make_owner(
            &mut moderation,
            self
        );

        (moderation, event, message)
    }

    public fun get_length(
        moderation: &Moderation
    ): u64 {
        moderation.moderation.length()
    }

    public fun is_moderator(
        moderation: &Moderation,
        user: address
    ): bool {
        moderation.moderation.contains(user)
    }

    public fun is_owner(
        moderation: &Moderation,
        user: address
    ): bool {
        let is_moderator = is_moderator(
            moderation,
            user
        );

        if (!is_moderator) {
            false
        } else {
            moderation.moderation[user] == OWNER
        }
    }

    public fun make_moderator(
        moderation: &mut Moderation,
        user: address
    ): (u8, u8) {
        moderation.moderation.add(
            user,
            MODERATOR
        );

        (MODERATOR_ADD, MODERATOR)
    }

    public fun make_owner(
        moderation: &mut Moderation,
        user: address
    ): (u8, u8) {
        moderation.moderation.add(
            user,
            OWNER
        );

        (MODERATOR_ADD, OWNER)
    }

    public fun remove_moderator(
        moderation: &mut Moderation,
        user: address
    ): (u8, u8) {
        let is_owner = is_owner(
            moderation,
            user
        );

        assert!(!is_owner, EIsOwner);

        moderation.moderation.remove(user);

        (MODERATOR_REMOVE, MODERATOR)
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
