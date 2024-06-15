module sage::channel_record {
    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    public struct ChannelRecord has copy, store, drop {
        channel_id: ID
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Functions ---------------

    public fun create(
        channel_id: ID
    ): ChannelRecord {
        ChannelRecord {
            channel_id
        }
    }
}
