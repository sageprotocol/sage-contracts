module sage_immutable::immutable_table {
    use sui::dynamic_field as field;

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    public struct ImmutableTable<phantom K: copy + drop + store, phantom V: store> has key, store {
        id: UID,
        size: u64,
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun new<K: copy + drop + store, V: store>(
        ctx: &mut TxContext
    ): ImmutableTable<K, V> {
        ImmutableTable {
            id: object::new(ctx),
            size: 0
        }
    }

    public fun add<K: copy + drop + store, V: store>(
        table: &mut ImmutableTable<K, V>,
        k: K,
        v: V
    ) {
        field::add(&mut table.id, k, v);

        table.size = table.size + 1;
    }

    public fun borrow<K: copy + drop + store, V: store>(
        table: &ImmutableTable<K, V>, k: K
    ): &V {
        field::borrow(&table.id, k)
    }

    public fun borrow_mut<K: copy + drop + store, V: store>(
        table: &mut ImmutableTable<K, V>, k: K
    ): &mut V {
        field::borrow_mut(&mut table.id, k)
    }

    public fun contains<K: copy + drop + store, V: store>(
        table: &ImmutableTable<K, V>, k: K
    ): bool {
        field::exists_with_type<K, V>(&table.id, k)
    }

    public fun length<K: copy + drop + store, V: store>(
        table: &ImmutableTable<K, V>
    ): u64 {
        table.size
    }

    public fun is_empty<K: copy + drop + store, V: store>(
        table: &ImmutableTable<K, V>
    ): bool {
        table.size == 0
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public fun destroy_for_testing<K: copy + drop + store, V: store>(
        table: ImmutableTable<K, V>
    ) {
        let ImmutableTable { id, size: _ } = table;

        object::delete(id)
    }
}
