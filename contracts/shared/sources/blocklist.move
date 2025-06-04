module sage_shared::blocklist {
    use sui::{
        table::{Self, Table}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EIsBlocked: u64 = 370;

    // --------------- Name Tag ---------------

    public struct Block has drop, store {
        block_end: Option<u64>,
        block_start: u64
    }

    public struct Blocklist has store {
        list: Table<address, Block>
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun assert_is_not_blocked(
        blocklist: &mut Blocklist,
        user_address: address,
        timestamp: u64
    ) {
        let is_blocked = is_blocked(
            blocklist,
            user_address,
            timestamp
        );

        assert!(!is_blocked, EIsBlocked);
    }

    public fun block(
        blocklist: &mut Blocklist,
        end: Option<u64>,
        start: u64,
        user_address: address
    ) {
        let block = Block {
            block_end: end,
            block_start: start
        };

        blocklist.list.add(
            user_address,
            block
        );
    }

    public fun create(
        ctx: &mut TxContext
    ): Blocklist {
        Blocklist {
            list: table::new(ctx)
        }
    }

    public fun is_blocked(
        blocklist: &mut Blocklist,
        user_address: address,
        timestamp: u64
    ): bool {
        if (blocklist.list.contains(user_address)) {
            let is_permanent = blocklist.list[user_address].block_end.is_none();

            if (is_permanent) {
                true
            } else {
                let is_blocked = timestamp < *blocklist.list[user_address].block_end.borrow();

                if (!is_blocked) {
                    unblock(
                        blocklist,
                        user_address
                    )
                };

                is_blocked
            }
        } else {
            false
        }
    }

    public fun unblock(
        blocklist: &mut Blocklist,
        user_address: address
    ) {
        blocklist.list.remove(user_address);
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
