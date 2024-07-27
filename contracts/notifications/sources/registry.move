module sage_notification::notification_registry {
    use sage_admin::{admin::{AdminCap}};

    use sage_notification::{notification::{Notification}};

    use sage_immutable::{
        immutable_table::{Self, ImmutableTable},
        immutable_vector::{Self, ImmutableVector}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EUserNotificationsExists: u64 = 370;

    // --------------- Name Tag ---------------

    public struct NotificationRegistry has store {
        registry: ImmutableTable<address, UserNotifications>
    }

    public struct UserNotifications has store {
        notifications: ImmutableVector<Notification>
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun borrow_user_notifications(
        notification_registry: &mut NotificationRegistry,
        user: address
    ): &mut UserNotifications {
        notification_registry.registry.borrow_mut(user)
    }

    public fun create_notification_registry(
        _: &AdminCap,
        ctx: &mut TxContext
    ): NotificationRegistry {
        NotificationRegistry {
            registry: immutable_table::new(ctx)
        }
    }

    public fun get_user_notifications_count(
        user_notifications: &UserNotifications
    ): u64 {
        user_notifications.notifications.length()
    }

    public fun has_user_notifications(
        notification_registry: &NotificationRegistry,
        user: address
    ): bool {
        notification_registry.registry.contains(user)
    }

    // --------------- Friend Functions ---------------

    public(package) fun add(
        user_notifications: &mut UserNotifications,
        notification: Notification
    ) {
        user_notifications.notifications.push_back(notification);
    }

    public(package) fun create_user_notifications(
        notification_registry: &mut NotificationRegistry,
        user: address
    ) {
        let has_record = has_user_notifications(
            notification_registry,
            user
        );

        assert!(!has_record, EUserNotificationsExists);

        let user_notifications = UserNotifications {
            notifications: immutable_vector::empty<Notification>()
        };

        notification_registry.registry.add(user, user_notifications);
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public fun destroy_for_testing(
        notification_registry: NotificationRegistry
    ) {
        let NotificationRegistry {
            registry
        } = notification_registry;

        registry.destroy_for_testing();
    }
}
