#[test_only]
module sage_immutable::table_tests {
    use sage_immutable::immutable_table::{Self, add, contains, borrow, borrow_mut};

    use sui::test_scenario as ts;

    #[test]
    fun simple_all_functions() {
        let sender = @0x0;
        let mut scenario = ts::begin(sender);
        let mut table = immutable_table::new(ts::ctx(&mut scenario));

        // add fields
        add(&mut table, b"hello", 0);
        add(&mut table, b"goodbye", 1);

        // check they exist
        assert!(contains(&table, b"hello"), 0);
        assert!(contains(&table, b"goodbye"), 0);

        // check the values
        assert!(*borrow(&table, b"hello") == 0, 0);
        assert!(*borrow(&table, b"goodbye") == 1, 0);

        // mutate them
        *borrow_mut(&mut table, b"hello") = *borrow(&table, b"hello") * 2;
        *borrow_mut(&mut table, b"goodbye") = *borrow(&table, b"goodbye") * 2;

        // check the new value
        assert!(*borrow(&table, b"hello") == 0, 0);
        assert!(*borrow(&table, b"goodbye") == 2, 0);

        ts::end(scenario);

        immutable_table::destroy_for_testing(table);
    }

    #[test]
    #[expected_failure(abort_code = sui::dynamic_field::EFieldAlreadyExists)]
    fun add_duplicate() {
        let sender = @0x0;
        let mut scenario = ts::begin(sender);
        let mut table = immutable_table::new(ts::ctx(&mut scenario));
        add(&mut table, b"hello", 0);
        add(&mut table, b"hello", 1);
        abort 42
    }

    #[test]
    #[expected_failure(abort_code = sui::dynamic_field::EFieldDoesNotExist)]
    fun borrow_missing() {
        let sender = @0x0;
        let mut scenario = ts::begin(sender);
        let table = immutable_table::new<u64, u64>(ts::ctx(&mut scenario));
        borrow(&table, 0);
        abort 42
    }

    #[test]
    #[expected_failure(abort_code = sui::dynamic_field::EFieldDoesNotExist)]
    fun borrow_mut_missing() {
        let sender = @0x0;
        let mut scenario = ts::begin(sender);
        let mut table = immutable_table::new<u64, u64>(ts::ctx(&mut scenario));
        borrow_mut(&mut table, 0);
        abort 42
    }

    #[test]
    fun sanity_check_contains() {
        let sender = @0x0;
        let mut scenario = ts::begin(sender);
        let mut table = immutable_table::new<u64, u64>(ts::ctx(&mut scenario));
        assert!(!contains(&table, 0), 0);
        add(&mut table, 0, 0);
        assert!(contains<u64, u64>(&table, 0), 0);
        assert!(!contains<u64, u64>(&table, 1), 0);
        ts::end(scenario);
        immutable_table::destroy_for_testing(table);
    }

    #[test]
    fun sanity_check_size() {
        let sender = @0x0;
        let mut scenario = ts::begin(sender);
        let mut table = immutable_table::new<u64, u64>(ts::ctx(&mut scenario));
        assert!(immutable_table::is_empty(&table), 0);
        assert!(immutable_table::length(&table) == 0, 0);
        add(&mut table, 0, 0);
        assert!(!immutable_table::is_empty(&table), 0);
        assert!(immutable_table::length(&table) == 1, 0);
        add(&mut table, 1, 0);
        assert!(!immutable_table::is_empty(&table), 0);
        assert!(immutable_table::length(&table) == 2, 0);
        ts::end(scenario);
        immutable_table::destroy_for_testing(table);
    }
}
