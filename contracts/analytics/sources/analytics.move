module sage_analytics::analytics {
    use std::{
        string::{String}
    };

    use sui::{
        dynamic_field::{Self as df}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    public struct Analytics has key, store {
        id: UID
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun borrow_field(
        analytics: &Analytics,
        key: String
    ): u64 {
        let does_exist = field_exists(
            analytics,
            key
        );

        if (does_exist) {
            *df::borrow<String, u64>(
                &analytics.id,
                key
            )
        } else {
            0
        }
    }

    public fun field_exists(
        analytics: &Analytics,
        key: String
    ): bool {
        df::exists_with_type<String, u64>(
            &analytics.id,
            key
        )
    }

    // --------------- Friend Functions ---------------

    public(package) fun add_field(
        analytics: &mut Analytics,
        key: String,
        value: u64
    ) {
        df::add(
            &mut analytics.id,
            key,
            value
        );
    }

    public(package) fun create(
        ctx: &mut TxContext
    ): Analytics {
        Analytics {
            id: object::new(ctx)
        }
    }

    public(package) fun remove_field(
        analytics: &mut Analytics,
        key: String
    ): u64 {
        df::remove<String, u64>(
            &mut analytics.id,
            key
        )
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
