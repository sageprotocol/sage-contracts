 #[test_only]
module sage_notification::test_notification_actions {
    use std::string::{utf8};

    use sui::{
        clock::{Self, Clock},
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy}
    };

    use sage_admin::{admin::{
        Self,
        NotificationCap
    }};

    use sage_notification::{
        notification_actions::{Self},
        notification_registry::{Self, NotificationRegistry}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;
    const NOTIFICATION: address = @notification;

    // --------------- Errors ---------------

    const EUserNotificationsMismatch: u64 = 0;

    // --------------- Test Functions ---------------

    #[test_only]
    fun setup_for_testing(): (Scenario, NotificationRegistry, NotificationCap) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
            notification_registry::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, NOTIFICATION);
        let notification_cap = {
            let notification_cap = ts::take_from_sender<NotificationCap>(scenario);

            notification_cap
        };

        ts::next_tx(scenario, ADMIN);
        let notification_registry = {
            let notification_registry = scenario.take_shared<NotificationRegistry>();

            notification_registry
        };

        (scenario_val, notification_registry, notification_cap)
    }

    #[test]
    fun test_notification_actions_init() {
        let (
            mut scenario_val,
            notification_registry_val,
            notification_cap
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, NOTIFICATION);
        {
            ts::return_to_sender(scenario, notification_cap);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy(notification_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_notification_create() {
        let (
            mut scenario_val,
            mut notification_registry_val,
            notification_cap
        ) = setup_for_testing();

        let notification_registry = &mut notification_registry_val;

        let scenario = &mut scenario_val;
        
        ts::next_tx(scenario, ADMIN);
        {
            let mut clock = clock::create_for_testing(ts::ctx(scenario));

            clock::set_for_testing(&mut clock, 0);
            clock::share_for_testing(clock);
        };

        ts::next_tx(scenario, ADMIN);
        {
            let reward_amount: u64 = 5;
            let user: address = @0xaaa;

            let clock: Clock = ts::take_shared(scenario);

            let _notification = notification_actions::create(
                &notification_cap,
                &clock,
                notification_registry,
                user,
                utf8(b"message"),
                reward_amount
            );

            let user_notifications = notification_registry::borrow_user_notifications(
                notification_registry,
                user
            );

            let notifications_count = notification_registry::get_user_notifications_count(
                user_notifications
            );

            assert!(notifications_count == 1, EUserNotificationsMismatch);

            ts::return_shared(clock);
        };

        ts::next_tx(scenario, NOTIFICATION);
        {
            ts::return_to_sender(scenario, notification_cap);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy(notification_registry_val);
        };

        ts::end(scenario_val);
    }
}
