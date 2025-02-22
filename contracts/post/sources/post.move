module sage_post::post {
    use std::string::{String};

    use sage_post::{
        posts::{Self, Posts},
        post_likes::{Self, Likes}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    public struct Post has key {
        id: UID,
        created_at: u64,
        created_by: address,
        data: String,
        description: String,
        likes: Likes,
        posts: Posts,
        is_deleted: bool,
        is_edited: bool,
        title: String,
        updated_at: u64
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun get_address(
        post: &Post
    ): address {
        post.id.to_address()
    }

    public fun get_author(
        post: &Post
    ): address {
        post.created_by
    }

    // --------------- Friend Functions ---------------

    public(package) fun borrow_likes_mut(
        post: &mut Post
    ): &mut Likes {
        &mut post.likes
    }

    public(package) fun borrow_posts_mut(
        post: &mut Post
    ): &mut Posts {
        &mut post.posts
    }

    public(package) fun create(
        data: String,
        description: String,
        timestamp: u64,
        title: String,
        ctx: &mut TxContext
    ): (address, address) {
        let self = tx_context::sender(ctx);

        let likes = post_likes::create(ctx);
        let posts = posts::create(ctx);

        let post = Post {
            id: object::new(ctx),
            created_at: timestamp,
            created_by: self,
            data,
            description,
            is_deleted: false,
            is_edited: false,
            likes,
            posts,
            title,
            updated_at: timestamp
        };

        let post_address = post.id.to_address();

        transfer::share_object(post);

        (post_address, self)
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
