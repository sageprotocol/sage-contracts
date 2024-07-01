module sage_immutable::immutable_vector {
    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    public struct ImmutableVector<Element: copy + drop + store> has copy, drop, store {
        inner: vector<Element>
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun borrow<Element: copy + drop + store>(
        v: &ImmutableVector<Element>,
        i: u64
    ): &Element {
        vector::borrow(&v.inner, i)
    }

    public fun borrow_mut<Element: copy + drop + store>(
        v: &mut ImmutableVector<Element>,
        i: u64
    ): &mut Element {
        vector::borrow_mut(&mut v.inner, i)
    }

    public fun contains<Element: copy + drop + store>(
        v: ImmutableVector<Element>,
        e: &Element
    ): bool {
        vector::contains(&v.inner, e)
    }

    public fun empty<Element: copy + drop + store>(): ImmutableVector<Element> {
        ImmutableVector<Element> {
            inner: vector::empty<Element>()
        }
    }

    public fun index_of<Element: copy + drop + store>(
        v: ImmutableVector<Element>,
        e: &Element
    ): (bool, u64) {
        vector::index_of(&v.inner, e)
    }

    public fun insert<Element: copy + drop + store>(
        v: &mut ImmutableVector<Element>,
        e: Element,
        i: u64
    ) {
        vector::insert(&mut v.inner, e, i)
    }

    public fun is_empty<Element: copy + drop + store>(
        v: ImmutableVector<Element>
    ): bool {
        vector::is_empty(&v.inner)
    }

    public fun length<Element: copy + drop + store>(
        v: ImmutableVector<Element>
    ): u64 {
        vector::length(&v.inner)
    }

    public fun push_back<Element: copy + drop + store>(
        v: &mut ImmutableVector<Element>,
        e: Element
    ) {
        vector::push_back(&mut v.inner, e)
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

}
