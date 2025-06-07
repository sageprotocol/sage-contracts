# Deployment

## Publishing

The order which the contracts are published is important, and errors will be encountered if the proper order is not taken.

1. Utils
2. Admin
3. Shared
4. Trust
5. Analytics
6. Post
7. Reward
8. User
9. Channel

This is due to dependencies between the packages:

- "Admin" depends on Utils.
- "Shared" and "Trust" depend on Admin and Utils.
- "Analytics" depends on Admin, Utils, and Trust.
- "Post" depends on Admin, Shared, and Utils.
- "Reward" depends on Admin, Shared, Trust, and Utils.
- "User" depends on Admin, Analytics, Post, Reward, Shared, and Utils.
- "Channel" depends on Admin, Analytics, Post, Reward, User, Shared, and Utils.

**Note: Document all created objects for a contract in its relevant `README.md` file.**

For local development and testing it may be easier to change all addresses in all `Move.toml` files to "0x0". Use commenting to avoid losing a reference to the published packages.

## Initialization

Create an app object:

- SWAP WALLET TO SAGE ADMIN

```sh
$ sui client call --package <ADMIN_PKG_ID> --module admin_actions --function create_app_as_admin --args <ADMIN_CAP_ID> <APP_REGISTRY_ID> sage
```

Enable rewards on Sage:

```sh
$ sui client call --package <ADMIN_PKG_ID> --module admin_actions --function update_app_rewards --args <REWARD_CAP_ID> <APP_ID> true
```

Create a royalties object:

```sh
$ sui client call --package <ADMIN_PKG_ID> --module admin_actions --function create_royalties --type-args 0x2::sui::SUI --args <FEE_CAP_ID> <APP_ID> 0 0x083819196bd7923be95bba14ab1f89931dc392a0d41c71a3eb5e2e9ad914acc9 0 0x083819196bd7923be95bba14ab1f89931dc392a0d41c71a3eb5e2e9ad914acc9
```

Create admin config objects (e.g. <CHANNEL_PKG_ID>::channel::Channel):

```sh
$ sui client call --package <ADMIN_PKG_ID> --module admin_access --function create_channel_config --type-args <CHANNEL_TYPE> --args <ADMIN_CAP_ID>
$ sui client call --package <ADMIN_PKG_ID> --module admin_access --function create_channel_witness_config --type-args <CHANNEL_WITNESS_TYPE> --args <ADMIN_CAP_ID>
$ sui client call --package <ADMIN_PKG_ID> --module admin_access --function create_group_witness_config --type-args <GROUP_WITNESS_TYPE> --args <ADMIN_CAP_ID>
$ sui client call --package <ADMIN_PKG_ID> --module admin_access --function create_owned_user_config --type-args <OWNED_USER_TYPE> --args <ADMIN_CAP_ID>
$ sui client call --package <ADMIN_PKG_ID> --module admin_access --function create_shared_user_config --type-args <SHARED_USER_TYPE> --args <ADMIN_CAP_ID>
$ sui client call --package <ADMIN_PKG_ID> --module admin_access --function create_user_witness_config --type-args <USER_WITNESS_TYPE> --args <ADMIN_CAP_ID>
```

Update trust config objects (e.g. <REWARD_PKG_ID>::reward_witness::RewardWitness):

```sh
$ sui client call --package <TRUST_PKG_ID> --module trust_access --function update_governance_witness --type-args <GOVERNANCE_WITNESS_TYPE> --args <ADMIN_CAP_ID> <GOVERNANCE_WITNESS_CONFIG_ID>
$ sui client call --package <TRUST_PKG_ID> --module trust_access --function update_reward_witness --type-args <REWARD_WITNESS_TYPE> --args <ADMIN_CAP_ID> <REWARD_WITNESS_CONFIG_ID>
```

Create a channel fees object:

```sh
$ sui client call --package <CHANNEL_PKG_ID> --module channel_fees --function create --type-args 0x2::sui::SUI --args <FEE_CAP_ID> <APP_ID> 0 0 0 0 0 0 0 0 0 0 0 0 0 0
```

Create a post fees object:

```sh
$ sui client call --package <POST_PKG_ID> --module post_fees --function create --type-args 0x2::sui::SUI --args <FEE_CAP_ID> <APP_ID> 0 0 0 0
```

Create a user fees object:

```sh
$ sui client call --package <USER_PKG_ID> --module user_fees --function create --type-args 0x2::sui::SUI --args <FEE_CAP_ID> <APP_ID> 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
```

- SWAP WALLET TO 0xRO4R
The next operation will require two zero SUI payments to complete. List out SUI balances:

```sh
$ sui client gas
```

Find a SUI coin balance greater than zero, and run this command twice to get two zero balance SUI coin IDs:

```sh
$ sui client split-coin --coin-id <SUI_COIN_ID> --amounts 0 --gas-budget 10000000
```

The very first user needs to be created without an invitation.

- Review the newly created user, go to their owned user object, and copy the owned user type.

```sh
$ sui client call --package <USER_PKG_ID> --module user_actions --function create --type-args 0x2::sui::SUI --args 0x6 <INVITE_CONFIG_ID> <USER_REG_ID> <USER_INVITE_REG_ID> <USER_FEE_ID> '[]' '[]' 0 0 "User 0x1 where authentic voices thrive without permission." "0xRO4R" <ZERO_BALANCE_COIN_ID_1> <ZERO_BALANCE_COIN_ID_2>
```

Afterwards set to the default initial growth behavior to require invitations.

- SWAP WALLET TO SAGE SERVER

```sh
$ sui client call --package <USER_PKG_ID> --module user_invite --function set_invite_config --args <INVITE_CAP_ID> <INVITE_CONFIG_ID> true
```

Begin the reward epochs:

- SWAP WALLET TO SAGE ADMIN

```sh
$ sui client call --package <REWARD_PKG_ID> --module reward_actions --function start_epochs --args <REWARD_CAP_ID> 0x6 <REWARD_COST_WEIGHTS_REG_ID>
```

Add the reward cost weights:

```sh
$ sui client call --package <REWARD_PKG_ID> --module reward_actions --function add_weight --args <REWARD_CAP_ID> <REWARD_COST_WEIGHTS_REG_ID> "channel-created" 1000000
$ sui client call --package <REWARD_PKG_ID> --module reward_actions --function add_weight --args <REWARD_CAP_ID> <REWARD_COST_WEIGHTS_REG_ID> "channel-followed" 1000000
$ sui client call --package <REWARD_PKG_ID> --module reward_actions --function add_weight --args <REWARD_CAP_ID> <REWARD_COST_WEIGHTS_REG_ID> "channel-text-posts" 1000000
$ sui client call --package <REWARD_PKG_ID> --module reward_actions --function add_weight --args <REWARD_CAP_ID> <REWARD_COST_WEIGHTS_REG_ID> "followed-channel" 1000000
$ sui client call --package <REWARD_PKG_ID> --module reward_actions --function add_weight --args <REWARD_CAP_ID> <REWARD_COST_WEIGHTS_REG_ID> "comment-given" 1000000
$ sui client call --package <REWARD_PKG_ID> --module reward_actions --function add_weight --args <REWARD_CAP_ID> <REWARD_COST_WEIGHTS_REG_ID> "comment-received" 1000000
$ sui client call --package <REWARD_PKG_ID> --module reward_actions --function add_weight --args <REWARD_CAP_ID> <REWARD_COST_WEIGHTS_REG_ID> "favorited-post" 1000000
$ sui client call --package <REWARD_PKG_ID> --module reward_actions --function add_weight --args <REWARD_CAP_ID> <REWARD_COST_WEIGHTS_REG_ID> "followed-user" 1000000
$ sui client call --package <REWARD_PKG_ID> --module reward_actions --function add_weight --args <REWARD_CAP_ID> <REWARD_COST_WEIGHTS_REG_ID> "liked-post" 1000000
$ sui client call --package <REWARD_PKG_ID> --module reward_actions --function add_weight --args <REWARD_CAP_ID> <REWARD_COST_WEIGHTS_REG_ID> "post-favorited" 1000000
$ sui client call --package <REWARD_PKG_ID> --module reward_actions --function add_weight --args <REWARD_CAP_ID> <REWARD_COST_WEIGHTS_REG_ID> "post-liked" 1000000
$ sui client call --package <REWARD_PKG_ID> --module reward_actions --function add_weight --args <REWARD_CAP_ID> <REWARD_COST_WEIGHTS_REG_ID> "user-followed" 1000000
$ sui client call --package <REWARD_PKG_ID> --module reward_actions --function add_weight --args <REWARD_CAP_ID> <REWARD_COST_WEIGHTS_REG_ID> "user-friends" 1000000
$ sui client call --package <REWARD_PKG_ID> --module reward_actions --function add_weight --args <REWARD_CAP_ID> <REWARD_COST_WEIGHTS_REG_ID> "user-text-posts" 1000000
```
