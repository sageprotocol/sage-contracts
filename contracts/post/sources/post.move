module sage_post::post {
    use std::string::{String};

    use sui::event;

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    public struct Post has copy, drop, store {
        id: ID,
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

    public struct PostCreated has copy, drop {
        id: ID,
        created_at: u64,
        created_by: address,
        data: String,
        description: String,
        is_deleted: bool,
        is_edited: bool,
        title: String,
        updated_at: u64
    }

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun get_id(
        post: Post
    ): ID {
        let Post {
            id,
            created_at: _,
            created_by: _,
            data: _,
            description: _,
            is_deleted: _,
            is_edited: _,
            title: _,
            updated_at: _
        } = post;

        id
    }

    // --------------- Friend Functions ---------------

    public(package) fun create(
        user: address,
        data: String,
        description: String,
        title: String,
        timestamp: u64,
        ctx: &mut TxContext
    ): (Post, ID) {
        let uid = object::new(ctx);
        let id = uid.to_inner();

        let post = Post {
            id,
            created_at: timestamp,
            created_by: user,
            data,
            description,
            is_deleted: false,
            is_edited: false,
            title,
            updated_at: timestamp
        };

        event::emit(PostCreated {
            id,
            created_at: timestamp,
            created_by: user,
            data,
            description,
            is_deleted: false,
            is_edited: false,
            title,
            updated_at: timestamp
        });

        object::delete(uid);

        (post, id)
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
