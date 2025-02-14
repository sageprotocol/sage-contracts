module sage_user::user {
    use std::string::{String};

    use sage_user::{
        user::{User},
        user_posts::{Self}
    };

    use sage_utils::{
        string_helpers::{Self}
    };

    // --------------- Constants ---------------

    const DESCRIPTION_MAX_LENGTH: u64 = 370;

    const USERNAME_MIN_LENGTH: u64 = 3;
    const USERNAME_MAX_LENGTH: u64 = 15;

    // --------------- Errors ---------------

    const EInvalidUserDescription: u64 = 370;
    const EInvalidUsername: u64 = 371;

    // --------------- Name Tag ---------------

    public struct User has key {
        id: UID,
        avatar_hash: String,
        banner_hash: String,
        created_at: u64,
        // current_shard: address,
        description: String,
        first_shard: address,
        owner: address,
        name: String,
        total_earnings: u64,
        updated_at: u64
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun get_immutable_name(
        user: &User
    ): String {
        user.name
    }

    // --------------- Friend Functions ---------------

    public(package) fun create(
        avatar_hash: String,
        banner_hash: String,
        created_at: u64,
        description: String,
        owner: address,
        name: String,
        ctx: &mut TxContext
    ): address {
        let is_valid_name = string_helpers::is_valid_name(
            &name,
            USERNAME_MIN_LENGTH,
            USERNAME_MAX_LENGTH
        );

        assert!(is_valid_name, EInvalidUsername);

        let is_valid_description = is_valid_description(&description);

        assert!(is_valid_description, EInvalidUserDescription);

        let shard_address = user_posts::create(
            created_at,
            ctx
        );

        let user = User {
            id: object::new(ctx),
            avatar_hash,
            banner_hash,
            created_at,
            // current_shard: shard_address,
            description,
            first_shard: shard_address,
            owner,
            name,
            total_earnings: 0,
            updated_at: created_at
        };

        let user_address = user.id.to_address();

        transfer::share_object(user);

        user_address
    }

    public(package) fun update (
        user: &mut User,
        avatar_hash: String,
        banner_hash: String,
        description: String,
        name: String,
        updated_at: u64
    ) {
        user.avatar_hash = avatar_hash;
        user.banner_hash = banner_hash;
        user.description = description;
        user.name = name;
        user.updated_at = updated_at;
    }

    // --------------- Internal Functions ---------------

    fun is_valid_description(
        description: &String
    ): bool {
        let len = description.length();

        if (len > DESCRIPTION_MAX_LENGTH) {
            return false
        };

        true
    }

    // --------------- Test Functions ---------------

    #[test_only]
    public fun is_valid_description_for_testing(
        name: &String
    ): bool {
        is_valid_description(name)
    }
}
