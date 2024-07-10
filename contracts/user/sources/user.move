module sage_user::user {
    use std::string::{String};

    // --------------- Constants ---------------

    const DESCRIPTION_MAX_LENGTH: u64 = 370;

    const USERNAME_MIN_LENGTH: u64 = 3;
    const USERNAME_MAX_LENGTH: u64 = 15;

    // --------------- Errors ---------------

    const EInvalidDescription: u64 = 0;
    const EInvalidUsername: u64 = 1;

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
        let is_valid_name = is_valid_username(&name);

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

    fun is_valid_username(
        name: &String
    ): bool {
        let len = name.length();
        let name_bytes = name.bytes();
        let mut index = 0;

        if (!(len >= USERNAME_MIN_LENGTH && len <= USERNAME_MAX_LENGTH)) {
            return false
        };

        while (index < len) {
            let character = name_bytes[index];
            let is_valid_character =
                (0x61 <= character && character <= 0x7A)                   // a-z
                || (0x30 <= character && character <= 0x39)                // 0-9
                || (character == 0x2D && index != 0 && index != len - 1);  // '-' not at beginning or end

            if (!is_valid_character) {
                return false
            };

            index = index + 1;
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

    #[test_only]
    public fun is_valid_username_for_testing(
        name: &String
    ): bool {
        is_valid_username(name)
    }
}
