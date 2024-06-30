module sage::immutable_vector {
    // --------------- Constants ---------------

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    public struct ImmutableVector<Element: copy + drop + store> has copy, drop, store {
        inner: vector<Element>
    }

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    // --------------- Public Functions ---------------

    public fun contains<Element: copy + drop + store>(
        v: ImmutableVector<Element>,
        e: &Element
    ): bool {
        let inner = get_inner(v);

        vector::contains(&inner, e)
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
        let inner = get_inner(v);

        vector::index_of(&inner, e)
    }

    public fun insert<Element: copy + drop + store>(
        v: ImmutableVector<Element>,
        e: Element,
        i: u64
    ) {
        let mut inner = get_inner(v);

        vector::insert(&mut inner, e, i)
    }

    public fun is_empty<Element: copy + drop + store>(
        v: ImmutableVector<Element>
    ): bool {
        let inner = get_inner(v);

        vector::is_empty(&inner)
    }

    public fun length<Element: copy + drop + store>(
        v: ImmutableVector<Element>
    ): u64 {
        let inner = get_inner(v);

        vector::length(&inner)
    }

    public fun push_back<Element: copy + drop + store>(
        v: &mut ImmutableVector<Element>,
        e: Element
    ) {
        let inner = get_inner_mut(v);

        vector::push_back(inner, e)
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    fun get_inner<Element: copy + drop + store>(
        v: ImmutableVector<Element>
    ): vector<Element> {
        let ImmutableVector {
            inner
        } = v;

        inner
    }

    fun get_inner_mut<Element: copy + drop + store>(
        v: &mut ImmutableVector<Element>
    ): &mut vector<Element> {
        let ImmutableVector {
            inner
        } = v;

        inner
    }

    // --------------- Test Functions ---------------

}
