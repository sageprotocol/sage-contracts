module sage_immutable::immutable_table {
    use sui::dynamic_field as field;

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    public struct ImmutableTable<phantom Key: copy + drop + store, phantom Value: store> has key, store {
        id: UID,
        size: u64,
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun new<Key: copy + drop + store, Value: store>(
        ctx: &mut TxContext
    ): ImmutableTable<Key, Value> {
        ImmutableTable {
            id: object::new(ctx),
            size: 0
        }
    }

    public fun add<Key: copy + drop + store, Value: store>(
        table: &mut ImmutableTable<Key, Value>,
        key: Key,
        value: Value
    ) {
        field::add(&mut table.id, key, value);

        table.size = table.size + 1;
    }

    public fun borrow<Key: copy + drop + store, Value: store>(
        table: &ImmutableTable<Key, Value>, k: Key
    ): &Value {
        field::borrow(&table.id, k)
    }

    public fun borrow_mut<Key: copy + drop + store, Value: store>(
        table: &mut ImmutableTable<Key, Value>, k: Key
    ): &mut Value {
        field::borrow_mut(&mut table.id, k)
    }

    public fun contains<Key: copy + drop + store, Value: store>(
        table: &ImmutableTable<Key, Value>, k: Key
    ): bool {
        field::exists_with_type<Key, Value>(&table.id, k)
    }

    public fun length<Key: copy + drop + store, Value: store>(
        table: &ImmutableTable<Key, Value>
    ): u64 {
        table.size
    }

    public fun is_empty<Key: copy + drop + store, Value: store>(
        table: &ImmutableTable<Key, Value>
    ): bool {
        table.size == 0
    }

    public fun replace<Key: copy + drop + store, Value: drop + store>(table: &mut ImmutableTable<Key, Value>, key: Key, value: Value) {
        field::remove<Key, Value>(&mut table.id, key);
        field::add(&mut table.id, key, value);
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public fun destroy_for_testing<Key: copy + drop + store, Value: store>(
        table: ImmutableTable<Key, Value>
    ) {
        let ImmutableTable { id, size: _ } = table;

        object::delete(id)
    }
}
