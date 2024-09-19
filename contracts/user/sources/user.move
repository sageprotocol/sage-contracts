module sage_user::user {
    use std::string::{String};

    use sui::event;

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

    public struct User has copy, drop, store {
        address: address,
        avatar_hash: String,
        banner_hash: String,
        created_at: u64,
        description: String,
        name: String,
        total_earnings: u64,
        updated_at: u64
    }

    // --------------- Events ---------------

    public struct UserCreated has copy, drop {
        address: address,
        avatar_hash: String,
        banner_hash: String,
        created_at: u64,
        description: String,
        invited_by: Option<address>,
        user_key: String,
        user_name: String
    }

    public struct UserUpdated has copy, drop {
        avatar_hash: String,
        banner_hash: String,
        description: String,
        updated_at: u64,
        user_key: String,
        user_name: String
    }

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun get_avatar(
        user: User
    ): String {
        let User {
            avatar_hash,
            ..
        } = user;

        avatar_hash
    }

    public fun get_banner(
        user: User
    ): String {
        let User {
            banner_hash,
            ..
        } = user;

        banner_hash
    }

    public fun get_description(
        user: User
    ): String {
        let User {
            description,
            ..
        } = user;

        description
    }

    public fun get_name(
        user: User
    ): String {
        let User {
            name,
            ..
        } = user;

        name
    }

    // --------------- Friend Functions ---------------

    public(package) fun create(
        address: address,
        avatar_hash: String,
        banner_hash: String,
        created_at: u64,
        description: String,
        invited_by: Option<address>,
        name: String,
        user_key: String
    ): User {
        let is_valid_name = string_helpers::is_valid_name(
            &name,
            USERNAME_MIN_LENGTH,
            USERNAME_MAX_LENGTH
        );

        assert!(is_valid_name, EInvalidUsername);

        let is_valid_description = is_valid_description(&description);

        assert!(is_valid_description, EInvalidUserDescription);

        event::emit(UserCreated {
            address,
            avatar_hash,
            banner_hash,
            created_at,
            description,
            invited_by,
            user_key,
            user_name: name
        });

        User {
            address,
            avatar_hash,
            banner_hash,
            created_at,
            description,
            name,
            total_earnings: 0,
            updated_at: created_at
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

    public(package) fun update_avatar (
        user_key: String,
        user: &mut User,
        avatar_hash: String,
        updated_at: u64
    ): User {
        user.avatar_hash = avatar_hash;
        user.updated_at = updated_at;

        let User {
            banner_hash,
            description,
            name,
            ..
        } = user;

        event::emit(UserUpdated {
            avatar_hash,
            banner_hash: *banner_hash,
            user_key,
            user_name: *name,
            description: *description,
            updated_at
        });

        *user
    }

    public(package) fun update_banner (
        user_key: String,
        user: &mut User,
        banner_hash: String,
        updated_at: u64
    ): User {
        user.banner_hash = banner_hash;
        user.updated_at = updated_at;

        let User {
            avatar_hash,
            description,
            name,
            ..
        } = user;

        event::emit(UserUpdated {
            avatar_hash: *avatar_hash,
            banner_hash,
            user_key,
            user_name: *name,
            description: *description,
            updated_at
        });

        *user
    }

    public(package) fun update_description (
        user_key: String,
        user: &mut User,
        description: String,
        updated_at: u64
    ): User {
        let is_valid_description = is_valid_description(&description);

        assert!(is_valid_description, EInvalidUserDescription);

        user.description = description;
        user.updated_at = updated_at;

        let User {
            avatar_hash,
            banner_hash,
            name,
            ..
        } = user;

        event::emit(UserUpdated {
            avatar_hash: *avatar_hash,
            banner_hash: *banner_hash,
            user_key,
            user_name: *name,
            description,
            updated_at
        });

        *user
    }

    public(package) fun update_name (
        user_key: String,
        user: &mut User,
        user_name: String,
        updated_at: u64
    ): User {
        user.name = user_name;
        user.updated_at = updated_at;

        let User {
            avatar_hash,
            banner_hash,
            description,
            ..
        } = user;

        event::emit(UserUpdated {
            avatar_hash: *avatar_hash,
            banner_hash: *banner_hash,
            user_key,
            user_name,
            description: *description,
            updated_at
        });

        *user
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
        invited_by: Option<address>,
        name: String,
        user_key: String
    ): User {
        create(
            address,
            avatar_hash,
            banner_hash,
            created_at,
            description,
            invited_by,
            name,
            user_key
        )
    }

    #[test_only]
    public fun is_valid_description_for_testing(
        name: &String
    ): bool {
        is_valid_description(name)
    }
}
