module sage_user::user {
    use std::string::{String};

    use sage_shared::{
        membership::{Membership},
        posts::{Posts}
    };

    use sage_utils::{
        string_helpers::{Self}
    };

    // --------------- Constants ---------------

    const DESCRIPTION_MAX_LENGTH: u64 = 370;

    const USERNAME_MIN_LENGTH: u64 = 3;
    const USERNAME_MAX_LENGTH: u64 = 20;

    // --------------- Errors ---------------

    const EInvalidUserDescription: u64 = 370;
    const EInvalidUsername: u64 = 371;

    // --------------- Name Tag ---------------

    public struct User has key {
        id: UID,
        avatar_hash: String,
        banner_hash: String,
        channel_following: Membership,
        created_at: u64,
        description: String,
        follows: Membership,
        key: String,
        owner: address,
        name: String,
        posts: Posts,
        soul: address,
        total_earnings: u64,
        user_following: Membership,
        updated_at: u64
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun assert_user_description(
        description: &String
    ) {
        let is_valid_description = is_valid_description(description);

        assert!(is_valid_description, EInvalidUserDescription);
    }

    public fun assert_user_name(
        name: &String
    ) {
        let is_valid_name = string_helpers::is_valid_name(
            name,
            USERNAME_MIN_LENGTH,
            USERNAME_MAX_LENGTH
        );

        assert!(is_valid_name, EInvalidUsername);
    }

    public fun get_avatar(
        user: &User
    ): String {
        user.avatar_hash
    }

    public fun get_banner(
        user: &User
    ): String {
        user.banner_hash
    }

    public fun get_description(
        user: &User
    ): String {
        user.description
    }

    public fun get_owner(
        user: &User
    ): address {
        user.owner
    }

    public fun get_key(
        user: &User
    ): String {
        user.key
    }

    public fun get_name(
        user: &User
    ): String {
        user.name
    }

    // --------------- Friend Functions ---------------

    public(package) fun borrow_channel_following_mut(
        user: &mut User
    ): &mut Membership {
        &mut user.channel_following
    }

    public(package) fun borrow_follows_mut(
        user: &mut User
    ): &mut Membership {
        &mut user.follows
    }

    public(package) fun borrow_posts_mut(
        user: &mut User
    ): &mut Posts {
        &mut user.posts
    }

    public(package) fun borrow_user_following_mut(
        user: &mut User
    ): &mut Membership {
        &mut user.user_following
    }

    public(package) fun create(
        avatar_hash: String,
        banner_hash: String,
        channel_following: Membership,
        created_at: u64,
        description: String,
        follows: Membership,
        key: String,
        owner: address,
        name: String,
        posts: Posts,
        soul: address,
        user_following: Membership,
        ctx: &mut TxContext
    ): address {
        assert_user_name(&name);
        assert_user_description(&description);

        let user = User {
            id: object::new(ctx),
            avatar_hash,
            banner_hash,
            channel_following,
            created_at,
            description,
            follows,
            key,
            owner,
            name,
            posts,
            soul,
            total_earnings: 0,
            user_following,
            updated_at: created_at
        };

        let user_address = user.id.to_address();

        transfer::share_object(user);

        user_address
    }

    public(package) fun update(
        user: &mut User,
        avatar_hash: String,
        banner_hash: String,
        description: String,
        name: String,
        updated_at: u64
    ) {
        assert_user_description(&description);

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
