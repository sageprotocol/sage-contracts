module sage_notification::notification_registry {
    use sui::package::{claim_and_keep};

    use sage_notification::{notification::{Notification}};

    use sage_immutable::{
        immutable_table::{Self, Table},
        immutable_vector::{Self, Vector}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EUserNotificationsExists: u64 = 370;

    // --------------- Name Tag ---------------

    public struct NotificationRegistry has key, store {
        id: UID,
        registry: Table<address, UserNotifications>
    }

    public struct UserNotifications has store {
        notifications: Vector<Notification>
    }

    public struct NOTIFICATION_REGISTRY has drop {}

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    fun init(
        otw: NOTIFICATION_REGISTRY,
        ctx: &mut TxContext
    ) {
        claim_and_keep(otw, ctx);

        let notification_registry = NotificationRegistry {
            id: object::new(ctx),
            registry: immutable_table::new(ctx)
        };

        transfer::share_object(notification_registry);
    }

    // --------------- Public Functions ---------------

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

    public(package) fun borrow_user_notifications_mut(
        notification_registry: &mut NotificationRegistry,
        user: address
    ): &mut UserNotifications {
        notification_registry.registry.borrow_mut(user)
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
    public fun init_for_testing(ctx: &mut TxContext) {
        init(NOTIFICATION_REGISTRY {}, ctx);
    }
}
