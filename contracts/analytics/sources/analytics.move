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

    public struct AnalyticsMetric has copy, drop, store {
        metric: String
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun borrow_field(
        analytics: &Analytics,
        metric: String
    ): u64 {
        let does_exist = field_exists(
            analytics,
            metric
        );

        if (does_exist) {
            let analytics_metric = AnalyticsMetric {
                metric
            };

            *df::borrow<AnalyticsMetric, u64>(
                &analytics.id,
                analytics_metric
            )
        } else {
            0
        }
    }

    public fun field_exists(
        analytics: &Analytics,
        metric: String
    ): bool {
        let analytics_metric = AnalyticsMetric {
            metric
        };

        df::exists_with_type<AnalyticsMetric, u64>(
            &analytics.id,
            analytics_metric
        )
    }

    // --------------- Friend Functions ---------------

    public(package) fun add_field(
        analytics: &mut Analytics,
        metric: String,
        value: u64
    ) {
        let analytics_metric = AnalyticsMetric {
            metric
        };

        df::add(
            &mut analytics.id,
            analytics_metric,
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
        metric: String
    ): u64 {
        let analytics_metric = AnalyticsMetric {
            metric
        };

        df::remove<AnalyticsMetric, u64>(
            &mut analytics.id,
            analytics_metric
        )
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
