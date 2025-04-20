module sage_user::user_shared {
    use sui::{
        dynamic_field::{Self as df},
        dynamic_object_field::{Self as dof}
    };

    use std::{
        string::{String}
    };

    use sage_admin::{
        access::{UserWitnessConfig}
    };

    use sage_reward::{
        analytics::{Analytics},
        analytics_actions::{Self}
    };

    use sage_shared::{
        membership::{Membership},
        posts::{Self, Posts}
    };

    use sage_user::{
        user_witness::{Self}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    public struct AnalyticsKey has copy, drop, store {
        app: String,
        epoch: u64
    }

    public struct PostsKey has copy, drop, store {
        app: String
    }

    public struct UserShared has key {
        id: UID,
        created_at: u64,
        follows: Membership,
        friend_requests: Membership,
        friends: Membership,
        key: String,
        owned_user: address,
        owner: address,
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

    public(package) fun borrow_analytics_mut(
        shared_user: &mut UserShared,
        user_witness_config: &UserWitnessConfig,
        app_name: String,
        epoch: u64,
        ctx: &mut TxContext
    ): &mut Analytics {
        let analytics_key = AnalyticsKey {
            app: app_name,
            epoch
        };

        let does_exist = dof::exists_with_type<AnalyticsKey, Analytics>(
            &shared_user.id,
            analytics_key
        );

        if (!does_exist) {
            let user_witness = user_witness::create_witness();

            let analytics = analytics_actions::create_analytics_for_user(
                user_witness,
                user_witness_config,
                ctx
            );

            dof::add(
                &mut shared_user.id,
                analytics_key,
                analytics
            );
        };

        dof::borrow_mut<AnalyticsKey, Analytics>(
            &mut shared_user.id,
            analytics_key
        )
    }

    public(package) fun borrow_follows_mut(
        shared_user: &mut UserShared
    ): &mut Membership {
        &mut shared_user.follows
    }

    public(package) fun borrow_friend_requests_mut(
        shared_user: &mut UserShared
    ): &mut Membership {
        &mut shared_user.friend_requests
    }

    public(package) fun borrow_friends_mut(
        shared_user: &mut UserShared
    ): &mut Membership {
        &mut shared_user.friends
    }

    public(package) fun create(
        created_at: u64,
        follows: Membership,
        friend_requests: Membership,
        friends: Membership,
        key: String,
        owned_user: address,
        owner: address,
        ctx: &mut TxContext
    ): address {
        let shared_user = UserShared {
            id: object::new(ctx),
            created_at,
            follows,
            friend_requests,
            friends,
            key,
            owned_user,
            owner,
            updated_at: created_at
        };

        let user_address = shared_user.id.to_address();

        transfer::share_object(shared_user);

        user_address
    }

    public(package) fun return_posts(
        shared_user: &mut UserShared,
        app_name: String,
        posts: Posts
    ) {
        let posts_key = PostsKey {
            app: app_name
        };

        df::add(
            &mut shared_user.id,
            posts_key,
            posts
        );
    }

    public(package) fun take_posts(
        shared_user: &mut UserShared,
        app_name: String,
        ctx: &mut TxContext
    ): Posts {
        let posts_key = PostsKey {
            app: app_name
        };

        let does_exist = df::exists_with_type<PostsKey, Posts>(
            &shared_user.id,
            posts_key
        );

        if (does_exist) {
            df::remove(
                &mut shared_user.id,
                posts_key
            )
        } else {
            posts::create(ctx)
        }
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public fun posts_exists(
        shared_user: &UserShared,
        app_name: String
    ): bool {
        let posts_key = PostsKey {
            app: app_name
        };

        df::exists_with_type<PostsKey, Posts>(
            &shared_user.id,
            posts_key
        )
    }
}
