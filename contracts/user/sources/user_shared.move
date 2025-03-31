module sage_user::user_shared {
    use std::{
        string::{String}
    };

    use sage_shared::{
        membership::{Membership},
        posts::{Posts}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    public struct UserShared has key {
        id: UID,
        created_at: u64,
        follows: Membership,
        key: String,
        owned_user: address,
        owner: address,
        posts: Posts,
        updated_at: u64
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun get_key(
        shared_user: &UserShared
    ): String {
        shared_user.key
    }

     public fun get_owner(
        shared_user: &UserShared
    ): address {
        shared_user.owner
    }

    public fun get_owned_user(
        shared_user: &UserShared
    ): address {
        shared_user.owned_user
    }

    // --------------- Friend Functions ---------------

    public(package) fun borrow_follows_mut(
        shared_user: &mut UserShared
    ): &mut Membership {
        &mut shared_user.follows
    }

    public(package) fun borrow_posts_mut(
        shared_user: &mut UserShared
    ): &mut Posts {
        &mut shared_user.posts
    }

    public(package) fun create(
        created_at: u64,
        follows: Membership,
        key: String,
        owned_user: address,
        owner: address,
        posts: Posts,
        ctx: &mut TxContext
    ): address {
        let shared_user = UserShared {
            id: object::new(ctx),
            created_at,
            follows,
            key,
            owned_user,
            owner,
            posts,
            updated_at: created_at
        };

        let user_address = shared_user.id.to_address();

        transfer::share_object(shared_user);

        user_address
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
