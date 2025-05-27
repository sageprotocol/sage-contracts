module sage_trust::access {
    use std::{
        type_name::{Self, TypeName}
    };

    use sui::{
        package::{claim_and_keep}
    };

    use sage_admin::{
        admin::{AdminCap}
    };

    // --------------- Constants ---------------

    // --------------- Errors ---------------

    const EIsFinalized: u64 = 370;
    const ETypeMismatch: u64 = 371;

    // --------------- Name Tag ---------------

    public struct RewardWitnessConfig has key {
        id: UID,
        finalized: bool,
        type_name: TypeName
    }

    public struct ACCESS has drop {}

    #[test_only]
    public struct InvalidWitness has drop {}

    #[test_only]
    public struct ValidWitness has drop {}

    // --------------- Events ---------------

    // --------------- Constructor ---------------

    fun init(
        otw: ACCESS,
        ctx: &mut TxContext
    ) {
        claim_and_keep(otw, ctx);

        let type_name = type_name::get<RewardWitnessConfig>();

        let reward_witness_config = RewardWitnessConfig {
            id: object::new(ctx),
            finalized: false,
            type_name
        };

        transfer::share_object(reward_witness_config);
    }

    // --------------- Public Functions ---------------

    public fun assert_reward_witness<WitnessType: drop> (
        reward_witness: &WitnessType,
        reward_witness_config: &RewardWitnessConfig
    ) {
        let is_reward_witness = verify_reward_witness<WitnessType>(
            reward_witness,
            reward_witness_config
        );

        assert!(is_reward_witness, ETypeMismatch);
    }

    public fun update<TypeName> (
        _: &AdminCap,
        reward_witness_config: &mut RewardWitnessConfig
    ) {
        assert!(!reward_witness_config.finalized, EIsFinalized);

        let type_name = type_name::get<TypeName>();

        reward_witness_config.finalized = true;
        reward_witness_config.type_name = type_name;
    }

    public fun verify_reward_witness<WitnessType: drop> (
        _reward_witness: &WitnessType,
        reward_witness_config: &RewardWitnessConfig
    ): bool {
        let type_name = type_name::get<WitnessType>();

        type_name == reward_witness_config.type_name
    }

    // --------------- Friend Functions ---------------

    // --------------- Internal Functions ---------------

    // --------------- Test Functions ---------------

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ACCESS {}, ctx);
    }

    #[test_only]
    public fun create_invalid_witness(): InvalidWitness {
        InvalidWitness {}
    }

    #[test_only]
    public fun create_valid_witness(): ValidWitness {
        ValidWitness {}
    }
}
