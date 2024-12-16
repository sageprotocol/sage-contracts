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

    public struct User has key {
        id: UID,
        avatar_hash: String,
        banner_hash: String,
        created_at: u64,
        description: String,
        owner: address,
        name: String,
        total_earnings: u64,
        updated_at: u64
    }

    public struct UserRequest {
        user: User
    }

    // --------------- Events ---------------

    public struct UserCreated has copy, drop {
        avatar_hash: String,
        banner_hash: String,
        created_at: u64,
        description: String,
        owner: address,
        invited_by: Option<address>,
        user_key: String,
        user_name: String
    }

    public struct UserUpdated has copy, drop {
        avatar_hash: String,
        banner_hash: String,
        description: String,
        owner: address,
        updated_at: u64,
        user_key: String,
        user_name: String
    }

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun create_user_request (
        user: User
    ): UserRequest {
        UserRequest { user }
    }

    public fun destroy_user_request (
        user_request: UserRequest,
        self: address
    ) {
        let UserRequest { user } = user_request;

        transfer::transfer(user, self);
    }

    public fun get_avatar(
        user_request: UserRequest
    ): (String, UserRequest) {
        let UserRequest { user } = user_request;

        (user.avatar_hash, create_user_request(user))
    }

    public fun get_banner(
        user_request: UserRequest
    ): (String, UserRequest) {
        let UserRequest { user } = user_request;

        (user.banner_hash, create_user_request(user))
    }

    public fun get_description(
        user_request: UserRequest
    ): (String, UserRequest) {
        let UserRequest { user } = user_request;

        (user.description, create_user_request(user))
    }

    public fun get_owner(
        user_request: UserRequest
    ): (address, UserRequest) {
        let UserRequest { user } = user_request;

        (user.owner, create_user_request(user))
    }

    public fun get_name(
        user_request: UserRequest
    ): (String, UserRequest) {
        let UserRequest { user } = user_request;

        (user.name, create_user_request(user))
    }

    // --------------- Friend Functions ---------------

    public(package) fun create(
        avatar_hash: String,
        banner_hash: String,
        created_at: u64,
        description: String,
        invited_by: Option<address>,
        owner: address,
        name: String,
        user_key: String,
        ctx: &mut TxContext
    ): address {
        let is_valid_name = string_helpers::is_valid_name(
            &name,
            USERNAME_MIN_LENGTH,
            USERNAME_MAX_LENGTH
        );

        assert!(is_valid_name, EInvalidUsername);

        let is_valid_description = is_valid_description(&description);

        assert!(is_valid_description, EInvalidUserDescription);

        event::emit(UserCreated {
            avatar_hash,
            banner_hash,
            created_at,
            description,
            invited_by,
            owner,
            user_key,
            user_name: name
        });

        let user = User {
            id: object::new(ctx),
            avatar_hash,
            banner_hash,
            created_at,
            description,
            owner,
            name,
            total_earnings: 0,
            updated_at: created_at
        };

        let user_address = user.id.to_address();

        transfer::transfer(user, tx_context::sender(ctx));

        user_address
    }

    public(package) fun update (
        user_key: String,
        user_request: UserRequest,
        avatar_hash: String,
        banner_hash: String,
        description: String,
        name: String,
        updated_at: u64
    ): UserRequest {
        let UserRequest { mut user } = user_request;

        user.avatar_hash = avatar_hash;
        user.banner_hash = banner_hash;
        user.description = description;
        user.name = name;

        event::emit(UserUpdated {
            avatar_hash,
            banner_hash,
            owner: user.owner,
            user_key,
            user_name: name,
            description,
            updated_at
        });

        create_user_request(user)
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
