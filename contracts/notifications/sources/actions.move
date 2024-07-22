module sage_notification::notification_actions {
    use std::string::{String};

    use sui::clock::{Clock};
    use sui::event;

    use sage_admin::{admin::{NotificationCap}};

    use sage_notification::{
        notification::{Self, Notification},
        notification_registry::{Self, NotificationRegistry}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    // --------------- Events ---------------

    public struct NotificationCreated has copy, drop {
        created_at: u64,
        created_for: address,
        message: String,
        reward_amount: u64
    }

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    // --------------- Friend Functions ---------------

    public fun create(
        _: &NotificationCap,
        clock: &Clock,
        notification_registry: &mut NotificationRegistry,
        user: address,
        message: String,
        reward_amount: u64
    ): Notification {
        let timestamp = clock.timestamp_ms();

        let notification = notification::create(
            timestamp,
            message,
            reward_amount
        );

        let has_record = notification_registry::has_user_notifications(
            notification_registry,
            user
        );

        if (!has_record) {
            notification_registry::create_user_notifications(
                notification_registry,
                user
            );
        };

        let user_notifications = notification_registry::borrow_user_notifications(
            notification_registry,
            user
        );

        notification_registry::add(
            user_notifications,
            notification
        );

        if (reward_amount != 0) {
            // send token here
        };

        event::emit(NotificationCreated {
            created_at: timestamp,
            created_for: user,
            message,
            reward_amount
        });

        notification
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
