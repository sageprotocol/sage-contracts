module sage_notification::notification {
    use std::string::{String};

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const ENegativeReward: u64 = 0;

    // --------------- Name Tag ---------------

    public struct Notification has copy, drop, store {
        created_at: u64,
        message: String,
        reward_amount: u64
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    // --------------- Friend Functions ---------------

    public(package) fun create(
        created_at: u64,
        message: String,
        reward_amount: u64
    ): Notification {
        assert!(reward_amount > 0, ENegativeReward);

        let notification = Notification {
            created_at,
            message,
            reward_amount
        };

        notification
    }

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------
}
