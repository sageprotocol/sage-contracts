module sage::post {
    use std::string::{String};

    use sui::event;

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // const EPostNotOwned: u64 = 0;

    // --------------- Name Tag ---------------

    public struct Post has key, store {
        id: UID,
        created_at: u64,
        created_by: address,
        data: String,
        description: String,
        edited: bool,
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
        edited: bool,
        title: String,
        updated_at: u64
    }

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun get_id (
        post: Post
    ): (UID, ID) {
        let Post {
            id: uid,
            created_at: _,
            created_by: _,
            data: _,
            description: _,
            edited: _,
            title: _,
            updated_at: _
        } = post;

        let id = object::uid_to_inner(&uid);

        (uid, id)
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
        let id = object::uid_to_inner(&uid);

        event::emit(PostCreated {
            id,
            created_at: timestamp,
            created_by: user,
            data,
            description,
            edited: false,
            title,
            updated_at: timestamp
        });

        let post = Post {
            id: uid,
            created_at: timestamp,
            created_by: user,
            data,
            description,
            edited: false,
            title,
            updated_at: timestamp
        };

        (post, id)
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
