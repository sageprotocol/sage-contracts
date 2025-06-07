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

    public struct Claim has copy, drop, store {
        app: address
    }

    public struct AnalyticsMetric has copy, drop, store {
        metric: String
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun claim_exists(
        analytics: &Analytics,
        app_address: address
    ): bool {
        let claim = Claim {
            app: app_address
        };

        df::exists_with_type<Claim, u64>(
            &analytics.id,
            claim
        )
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

    public fun get_claim(
        analytics: &Analytics,
        app_address: address
    ): u64 {
        let does_exist = claim_exists(
            analytics,
            app_address
        );

        if (does_exist) {
            let claim = Claim {
                app: app_address
            };

            *df::borrow<Claim, u64>(
                &analytics.id,
                claim
            )
        } else {
            0
        }
    }

    public fun get_field(
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

    // --------------- Friend Functions ---------------

    public(package) fun add_claim(
        analytics: &mut Analytics,
        app_address: address,
        value: u64
    ) {
        let claim = Claim {
            app: app_address
        };

        df::add<Claim, u64>(
            &mut analytics.id,
            claim,
            value
        );
    }

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

    public(package) fun add_to_claim(
        analytics: &mut Analytics,
        app_address: address,
        value: u64
    ) {
        let does_exist = claim_exists(
            analytics,
            app_address
        );

        let claim = Claim {
            app: app_address
        };

        let new_claim = if (does_exist) {
            let old_claim = df::remove<Claim, u64>(
                &mut analytics.id,
                claim
            );

            old_claim + value
        } else {
            value
        };

        df::add<Claim, u64>(
            &mut analytics.id,
            claim,
            new_claim
        );
    }

    public(package) fun create(
        ctx: &mut TxContext
    ): Analytics {
        Analytics {
            id: object::new(ctx)
        }
    }

    public(package) fun remove_claim(
        analytics: &mut Analytics,
        app_address: address
    ): u64 {
        let claim = Claim {
            app: app_address
        };

        df::remove<Claim, u64>(
            &mut analytics.id,
            claim
        )
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

    #[test_only]
    public fun create_for_testing(
        ctx: &mut TxContext
    ): Analytics {
        create(ctx)
    }
}
