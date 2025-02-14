module sage_user::user_posts {
    use sui::{
        clock::Clock,
        table::{Self, Table}
    };

    // --------------- Constants ---------------

    const MAX_POSTS: u64 = 2700;

    // --------------- Errors ---------------

    const ECompletedShard: u64 = 370;

    // --------------- Name Tag ---------------

    public struct UserPostShard has key {
        id: UID,
        end_time: u64,
        next_shard: Option<address>,
        posts: Table<u64, address>,
        prev_shard: Option<address>,
        start_time: u64
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun get_address(
        user_post_shard: &UserPostShard
    ): address {
        user_post_shard.id.to_address()
    }

    public fun is_complete(
        user_post_shard: &UserPostShard
    ): bool {
        user_post_shard.end_time != 0 && option::is_some(&user_post_shard.next_shard)
    }

    public fun is_full(
        user_post_shard: &UserPostShard
    ): bool {
        let length = user_post_shard.posts.length();

        length >= MAX_POSTS
    }

    public fun new(
        clock: &Clock,
        prev_shard: &mut UserPostShard,
        ctx: &mut TxContext
    ): (UserPostShard, address) {
        let is_complete = is_complete(prev_shard);

        assert!(!is_complete, ECompletedShard);

        let prev_shard_address = prev_shard.id.to_address();

        let timestamp = clock.timestamp_ms();

        let next_shard = UserPostShard {
            id: object::new(ctx),
            end_time: 0,
            next_shard: option::none<address>(),
            posts: table::new(ctx),
            prev_shard: option::some(prev_shard_address),
            start_time: timestamp
        };

        prev_shard.end_time = timestamp;
        prev_shard.next_shard = option::some(next_shard.id.to_address());

        let shard_address = next_shard.id.to_address();

        (next_shard, shard_address)
    }

    public fun share(
        user_post_shard: UserPostShard
    ) {
        transfer::share_object(user_post_shard);
    }

    // --------------- Friend Functions ---------------

    public(package) fun add(
        user_post_shard: &mut UserPostShard,
        object_address: address
    ) {
        let length = user_post_shard.posts.length();

        user_post_shard.posts.add(
            length + 1,
            object_address
        );
    }

    public(package) fun create(
        timestamp: u64,
        ctx: &mut TxContext
    ): address {
        let user_post_shard = UserPostShard {
            id: object::new(ctx),
            end_time: 0,
            next_shard: option::none<address>(),
            posts: table::new(ctx),
            prev_shard: option::none<address>(),
            start_time: timestamp
        };

        let shard_address = user_post_shard.id.to_address();

        share(user_post_shard);

        shard_address
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
