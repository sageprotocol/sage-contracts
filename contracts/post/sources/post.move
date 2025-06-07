module sage_post::post {
    use std::string::{String};

    use sage_shared::{
        likes::{Self, Likes},
        posts::{Self, Posts}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    public struct Post has key {
        id: UID,
        app: address,
        created_at: u64,
        created_by: address,
        data: String,
        depth: u64,
        description: String,
        likes: Likes,
        posts: Posts,
        is_deleted: bool,
        is_edited: bool,
        title: String,
        top_parent: address,
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

    public fun get_app(
        post: &Post
    ): address {
        post.app
    }

    public fun get_author(
        post: &Post
    ): address {
        post.created_by
    }

    public fun get_comments_count(
        post: &Post
    ): u64 {
        post.posts.get_length()
    }

    public fun get_created_at(
        post: &Post
    ): u64 {
        post.created_at
    }

    public fun get_depth(
        post: &Post
    ): u64 {
        post.depth
    }

    public fun get_likes_count(
        post: &Post
    ): u64 {
        post.likes.get_length()
    }

    public fun get_top_parent(
        post: &Post
    ): address {
        post.top_parent
    }

    public fun get_updated_at(
        post: &Post
    ): u64 {
        post.updated_at
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
        app: address,
        data: String,
        depth: u64,
        description: String,
        timestamp: u64,
        title: String,
        top_parent: address,
        ctx: &mut TxContext
    ): (address, address) {
        let self = tx_context::sender(ctx);

        let likes = likes::create(ctx);
        let posts = posts::create(ctx);

        let post = Post {
            id: object::new(ctx),
            app,
            created_at: timestamp,
            created_by: self,
            data,
            depth,
            description,
            is_deleted: false,
            is_edited: false,
            likes,
            posts,
            title,
            top_parent,
            updated_at: timestamp
        };

        let post_address = post.id.to_address();

        transfer::share_object(post);

        (post_address, self)
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
