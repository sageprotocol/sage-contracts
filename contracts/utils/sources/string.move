module sage_utils::string_helpers {
    use std::string::{String, utf8};

    // --------------- Constants ---------------

    const CHAR_CASE_OFFSET: u8 = 0x20;

    const CHAR_LOWER_A: u8 = 0x61;
    const CHAR_LOWER_Z: u8 = 0x7A;
    const CHAR_UPPER_A: u8 = 0x41;
    const CHAR_UPPER_Z: u8 = 0x5A;

    const CHAR_ZERO: u8 = 0x30;
    const CHAR_NINE: u8 = 0x39;

    const CHAR_DASH: u8 = 0x2D;

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun is_valid_name(
        name: &String,
        min_length: u64,
        max_length: u64
    ): bool {
        let len = name.length();
        let name_bytes = name.as_bytes();
        let mut index = 0;

        if (!(len >= min_length && len <= max_length)) {
            return false
        };

        while (index < len) {
            let character = name_bytes[index];
            let is_valid_character =
                (CHAR_UPPER_A <= character && character <= CHAR_UPPER_Z)
                || (CHAR_LOWER_A <= character && character <= CHAR_LOWER_Z)
                || (CHAR_ZERO <= character && character <= CHAR_NINE)
                || (character == CHAR_DASH && index != 0 && index != len - 1);  // '-' not at beginning or end

            if (!is_valid_character) {
                return false
            };

            index = index + 1;
        };

        true
    }

    public fun to_lowercase(
        name: &String
    ): String {
        let len = name.length();
        let name_bytes = name.as_bytes();
        let mut index = 0;

        let mut lowercase_bytes = vector::empty<u8>();

        while (index < len) {
            let character = name_bytes[index];

            let lowercase = if (
                CHAR_UPPER_A <= character && character <= CHAR_UPPER_Z
            ) {
                character + CHAR_CASE_OFFSET
            } else {
                character
            };

            lowercase_bytes.push_back(lowercase);

            index = index + 1;
        };

        utf8(lowercase_bytes)
    }

    public fun to_uppercase(
        name: &String
    ): String {
        let len = name.length();
        let name_bytes = name.as_bytes();
        let mut index = 0;

        let mut lowercase_bytes = vector::empty<u8>();

        while (index < len) {
            let character = name_bytes[index];

            let lowercase = if (
                CHAR_LOWER_A <= character && character <= CHAR_LOWER_Z
            ) {
                character - CHAR_CASE_OFFSET
            } else {
                character
            };

            lowercase_bytes.push_back(lowercase);

            index = index + 1;
        };

        utf8(lowercase_bytes)
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------
}
