module sage_post::post {
    use std::string::{String, utf8};

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    public struct Post has key {
        id: UID,
        key: String,
        created_at: u64,
        created_by: address,
        data: String,
        description: String,
        is_deleted: bool,
        is_edited: bool,
        title: String,
        updated_at: u64
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun get_author(
        post: &Post
    ): address {
        post.created_by
    }

    public fun get_key(
        post: &Post
    ): String {
        post.key
    }

    // --------------- Friend Functions ---------------

    public(package) fun create(
        user_address: address,
        data: String,
        description: String,
        title: String,
        timestamp: u64,
        ctx: &mut TxContext
    ): (String, address) {
        let uid = object::new(ctx);
        let id = uid.to_inner();
        let key = id_to_key(id);

        let post = Post {
            id: uid,
            key,
            created_at: timestamp,
            created_by: user_address,
            data,
            description,
            is_deleted: false,
            is_edited: false,
            title,
            updated_at: timestamp
        };

        let post_address = post.id.to_address();

        transfer::share_object(post);

        (key, post_address)
    }

    // --------------- Internal Functions ---------------

    fun id_to_key(
        id: ID
    ): String {
        let bytes = id.to_bytes();

        let len = bytes.length();
        let mut index = 0;

        let hex_chars = b"0123456789abcdef";
        let mut hex_bytes = vector::empty<u8>();

        while (index < len) {
            let byte = &bytes[index];

            let high_nibble = (*byte >> 4) & 0x0F;
            let low_nibble = *byte & 0x0F;

            vector::push_back(&mut hex_bytes, hex_chars[high_nibble as u64]);
            vector::push_back(&mut hex_bytes, hex_chars[low_nibble as u64]);

            index = index + 1;
        };

        let hex_string = utf8(hex_bytes);

        hex_string
    }

    // --------------- Test Functions ---------------
}
