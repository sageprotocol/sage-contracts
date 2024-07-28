module sage_user::user {
    use std::string::{String};

    use sage_utils::{
        string_helpers::{Self}
    };

    // --------------- Constants ---------------

    const DESCRIPTION_MAX_LENGTH: u64 = 370;

    const USERNAME_MIN_LENGTH: u64 = 3;
    const USERNAME_MAX_LENGTH: u64 = 15;

    // --------------- Errors ---------------

    const EInvalidDescription: u64 = 370;
    const EInvalidUsername: u64 = 371;

    // --------------- Name Tag ---------------

    public struct User has copy, drop, store {
        address: address,
        avatar_hash: String,
        banner_hash: String,
        created_at: u64,
        description: String,
        name: String,
        total_earnings: u64
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    // --------------- Friend Functions ---------------

    public(package) fun create(
        address: address,
        avatar_hash: String,
        banner_hash: String,
        created_at: u64,
        description: String,
        name: String
    ): User {
        let is_valid_name = string_helpers::is_valid_name(
            &name,
            USERNAME_MIN_LENGTH,
            USERNAME_MAX_LENGTH
        );

        assert!(is_valid_name, EInvalidUsername);

        let is_valid_description = is_valid_description(&description);

        assert!(is_valid_description, EInvalidDescription);

        User {
            address,
            avatar_hash,
            banner_hash,
            created_at,
            description,
            name,
            total_earnings: 0
        }
    }

    public(package) fun get_address(
        user: User
    ): address {
        let User {
            address,
            ..
        } = user;

        address
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
    public fun create_for_testing(
        address: address,
        avatar_hash: String,
        banner_hash: String,
        created_at: u64,
        description: String,
        name: String
    ): User {
        create(
            address,
            avatar_hash,
            banner_hash,
            created_at,
            description,
            name
        )
    }

    #[test_only]
    public fun is_valid_description_for_testing(
        name: &String
    ): bool {
        is_valid_description(name)
    }
}
