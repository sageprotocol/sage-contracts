 #[test_only]
module sage_notification::test_registry {
    use std::string::{utf8};

    use sui::{
        test_scenario::{Self as ts, Scenario},
        test_utils::{destroy}
    };

    use sage_admin::{admin::{Self}};

    use sage_notification::{
        notification::{Self},
        notification_registry::{Self, NotificationRegistry}
    };

    // --------------- Constants ---------------

    const ADMIN: address = @admin;

    // --------------- Errors ---------------

    const EUserNotificationsDoesNotExist: u64 = 0;
    const EUserNotificationsMismatch: u64 = 1;

    // --------------- Test Functions ---------------

    #[test_only]
    fun setup_for_testing(): (Scenario, NotificationRegistry) {
        let mut scenario_val = ts::begin(ADMIN);
        let scenario = &mut scenario_val;
        {
            admin::init_for_testing(ts::ctx(scenario));
            notification_registry::init_for_testing(ts::ctx(scenario));
        };

        ts::next_tx(scenario, ADMIN);
        let notification_registry = {
            let notification_registry = scenario.take_shared<NotificationRegistry>();

            notification_registry
        };

        (scenario_val, notification_registry)
    }

    #[test]
    fun test_notification_init() {
        let (
            mut scenario_val,
            notification_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            destroy(notification_registry_val);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_notification_registry() {
        let (
            mut scenario_val,
            mut notification_registry_val
        ) = setup_for_testing();

        let scenario = &mut scenario_val;

        ts::next_tx(scenario, ADMIN);
        {
            let reward_amount: u64 = 5;
            let timestamp: u64 = 999;
            let user: address = @0xaaa;

            let notification = notification::create(
                timestamp,
                utf8(b"message"),
                reward_amount
            );

            let notification_registry = &mut notification_registry_val;

            notification_registry::create_user_notifications(
                notification_registry,
                user
            );

            let has_user_notifications = notification_registry::has_user_notifications(
                notification_registry,
                user
            );

            assert!(has_user_notifications, EUserNotificationsDoesNotExist);

            let user_notifications = notification_registry::borrow_user_notifications(
                notification_registry,
                user
            );

            notification_registry::add(
                user_notifications,
                notification
            );

            let notifications_count = notification_registry::get_user_notifications_count(
                user_notifications
            );

            assert!(notifications_count == 1, EUserNotificationsMismatch);
        };

        ts::next_tx(scenario, ADMIN);
        {
            destroy(notification_registry_val);
        };

        ts::end(scenario_val);
    }
}
