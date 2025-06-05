module sage_trust::trust {
    use sui::{
        coin::{Self, Coin, TreasuryCap},
        url::{new_unsafe_from_bytes}
    };

    use sage_admin::{
        admin::{MintCap}
    };

    use sage_trust::{
        trust_access::{
            Self,
            GovernanceWitnessConfig,
            RewardWitnessConfig
        }
    };

    // --------------- Constants ---------------

    const DECIMALS: u8 = 6;
    const DESCRIPTION: vector<u8> = b"Testnet TRUST";
    const ICON_BYTES: vector<u8> = b"data:image/png;base64,xxxxxxxxx";
    const NAME: vector<u8> = b"tTRUST";
    const SYMBOL: vector<u8> = b"tTRUST";

    // --------------- Errors ---------------

    // --------------- Name Tag ---------------

    public struct MintConfig has key {
        id: UID,
        enabled: bool,
        max_supply: Option<u64>
    }

    public struct ProtectedTreasury has key {
        id: UID,
        cap: TreasuryCap<TRUST>
    }

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
            option::some(new_unsafe_from_bytes(ICON_BYTES)),
            ctx
        );

        transfer::public_freeze_object(metadata);

        let mint_config = MintConfig {
            id: object::new(ctx),
            enabled: true,
            max_supply: option::none()
        };
        let protected_treasury = ProtectedTreasury {
            id: object::new(ctx),
            cap
        };

        transfer::share_object(mint_config);
        transfer::share_object(protected_treasury);
    }

    // --------------- Public Functions ---------------

    public fun burn<WitnessType: drop> (
        reward_witness: &WitnessType,
        treasury: &mut ProtectedTreasury,
        reward_witness_config: &RewardWitnessConfig,
        coin: Coin<TRUST>
    ) {
        trust_access::assert_reward_witness<WitnessType>(
            reward_witness,
            reward_witness_config
        );

        treasury.cap.burn(coin);
    }

    public fun is_minting_enabled(
        mint_config: &MintConfig
    ): bool {
        mint_config.enabled
    }

    public fun max_supply(
        mint_config: &MintConfig
    ): Option<u64> {
        mint_config.max_supply
    }
    
    public fun mint<WitnessType: drop> (
        mint_config: &MintConfig,
        reward_witness: &WitnessType,
        reward_witness_config: &RewardWitnessConfig,
        treasury: &mut ProtectedTreasury,
        amount: u64,
        ctx: &mut TxContext
    ): Coin<TRUST> {
        trust_access::assert_reward_witness<WitnessType>(
            reward_witness,
            reward_witness_config
        );

        let mint_amount = if (!mint_config.enabled) {
            0
        } else if (option::is_some(&mint_config.max_supply)) {
            let max_supply = *option::borrow(&mint_config.max_supply);
            let total_supply = total_supply(treasury);

            if (total_supply + amount <= max_supply) {
                amount
            } else {
                max_supply - total_supply
            }
        } else {
            amount
        };

        treasury.cap.mint(
            mint_amount,
            ctx
        )
    }

    public fun total_supply(
        treasury: &ProtectedTreasury
    ): u64 {
        treasury.cap.total_supply()
    }

    public fun update_mint_config_admin(
        _: &MintCap,
        mint_config: &mut MintConfig,
        enabled: bool,
        max_supply: Option<u64>
    ) {
        update_mint_config(
            mint_config,
            enabled,
            max_supply
        );
    }

    public fun update_mint_config_for_governance<GovernanceWitness: drop>(
        governance_witness: &GovernanceWitness,
        governance_witness_config: &GovernanceWitnessConfig,
        mint_config: &mut MintConfig,
        enabled: bool,
        max_supply: Option<u64>
    ) {
        trust_access::assert_governance_witness(
            governance_witness,
            governance_witness_config
        );

        update_mint_config(
            mint_config,
            enabled,
            max_supply
        );
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    fun update_mint_config (
        mint_config: &mut MintConfig,
        enabled: bool,
        max_supply: Option<u64>
    ) {
        mint_config.enabled = enabled;
        mint_config.max_supply = max_supply;
    }

    // --------------- Test Functions ---------------

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(TRUST {}, ctx);
    }
}
