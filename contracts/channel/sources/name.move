module sage::channel_name {
    use std::string::{String};

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    public struct ChannelName has copy, store, drop {
        name: String
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Functions ---------------

    public fun create(
        name: String
    ): ChannelName {
        let channel_name = ChannelName {
            name
        };

        channel_name
    }
}
