module sage_trust::trust {
    use sui::{
        coin::{Self, Coin, TreasuryCap},
        dynamic_object_field::{Self as dof},
        url::{new_unsafe_from_bytes}
    };

    use sage_trust::{
        access::{Self, TrustConfig}
    };

    // --------------- Constants ---------------

    const DECIMALS: u8 = 9;
    const DESCRIPTION: vector<u8> = b"";
    const ICON_URL: vector<u8> = b"";
    const NAME: vector<u8> = b"";
    const SYMBOL: vector<u8> = b"";

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    public struct ProtectedTreasury has key {
        id: UID
    }

    public struct TreasuryCapKey has copy, drop, store {}

    public struct TRUST has drop {}

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    fun init(
        otw: TRUST,
        ctx: &mut TxContext
    ) {
        let (
            cap,
            metadata
        ) = coin::create_currency(
            otw,
            DECIMALS,
            SYMBOL,
            NAME,
            DESCRIPTION,
            option::some(new_unsafe_from_bytes(ICON_URL)),
            ctx
        );

        transfer::public_freeze_object(metadata);

        let mut protected_treasury = ProtectedTreasury {
            id: object::new(ctx)
        };

        dof::add(
            &mut protected_treasury.id,
            TreasuryCapKey {},
            cap
        );

        transfer::share_object(protected_treasury);
    }

    // --------------- Public Functions ---------------

    public fun burn<WitnessType: drop> (
        reward_witness: &WitnessType,
        treasury: &mut ProtectedTreasury,
        trust_config: &TrustConfig,
        coin: Coin<TRUST>
    ) {
        access::assert_reward_witness<WitnessType>(
            reward_witness,
            trust_config
        );

        let cap = treasury.borrow_cap_mut();

        cap.burn(coin);
    }
    
    public fun mint<WitnessType: drop> (
        reward_witness: &WitnessType,
        treasury: &mut ProtectedTreasury,
        trust_config: &TrustConfig,
        amount: u64,
        ctx: &mut TxContext
    ): Coin<TRUST> {
        access::assert_reward_witness<WitnessType>(
            reward_witness,
            trust_config
        );

        let cap = treasury.borrow_cap_mut();

        cap.mint(
            amount,
            ctx
        )
    }

    public fun total_supply(
        treasury: &ProtectedTreasury
    ): u64 {
        let cap = treasury.borrow_cap();

        cap.total_supply()
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    fun borrow_cap(
        treasury: &ProtectedTreasury
    ): &TreasuryCap<TRUST> {
        dof::borrow(
            &treasury.id,
            TreasuryCapKey {}
        )
    }

    fun borrow_cap_mut(
        treasury: &mut ProtectedTreasury
    ): &mut TreasuryCap<TRUST> {
        dof::borrow_mut(
            &mut treasury.id,
            TreasuryCapKey {}
        )
    }

    // --------------- Test Functions ---------------

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(TRUST {}, ctx);
    }
}
