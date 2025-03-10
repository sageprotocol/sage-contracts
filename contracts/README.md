# Deployment

## Publishing

The order which the contracts are published is important, and errors will be encountered if the proper order is not taken.

1. Utils
2. Admin
3. Shared
4. Post
5. User
6. Channel

This is due to dependencies between the packages:

- "Admin" depends on Utils.
- "Shared" depends on Admin and Utils.
- "Post" depends on Admin, Shared, and Utils.
- "User" depends on Admin, Post, Shared, and Utils.
- "Channel" depends on Admin, Post, User, Shared, and Utils.

After each dependent contract is published or upgraded it is important to update the "published-at" and relevant address declaration in all files that depend on the package.

For example, once "Post" has been published copy the object id and replace the "published-at" field in the `Move.toml` file for Post, as well as the address for `sage_post` in the `Move.toml` files for both Post and Channel.

**Note: Document all created objects for a contract in its relevant `README.md` file.**

For local development and testing it may be easier to change all addresses in all `Move.toml` files to "0x0". Use commenting to avoid losing a reference to the published packages.

## Initialization

Create an app object:

- SWAP WALLET TO SAGE ADMIN

```sh
$ sui client call --package <ADMIN_PKG_ID> --module admin_actions --function create_app_as_admin --args <ADMIN_CAP_ID> <APP_REGISTRY_ID> sage
```

Create a royalties object:

```sh
$ sui client call --package <ADMIN_PKG_ID> --module admin_actions --function create_royalties --type-args 0x2::sui::SUI --args <FEE_CAP_ID> <APP_ID> 0 0x083819196bd7923be95bba14ab1f89931dc392a0d41c71a3eb5e2e9ad914acc9 0 0x083819196bd7923be95bba14ab1f89931dc392a0d41c71a3eb5e2e9ad914acc9
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
$ sui client call --package <USER_PKG_ID> --module user_fees --function create --type-args 0x2::sui::SUI --args <FEE_CAP_ID> <APP_ID> 0 0 0 0 0 0 0 0 0 0 0 0
```

- SWAP WALLET TO MATRIXRICK
The next operation will require two zero SUI payments to complete. List out SUI balances:

```sh
$ sui client gas
```

Find a SUI coin balance greater than zero, and run this command twice to get two zero balance SUI coin IDs:

```sh
$ sui client split-coin --coin-id <ZERO_BALANCE_SUI_COIN_ID> --amounts 0 --gas-budget 10000000
```

The very first user needs to be created without an invitation.

- Review the newly created user, go to their soul object, and copy the soul type.

```sh
$ sui client call --package <USER_PKG_ID> --module user_actions --function create --type-args 0x2::sui::SUI --args 0x6 <INVITE_CONFIG_ID> <USER_REG_ID> <USER_INVITE_REG> <USER_FEE_ID> "" "" avatar_hash banner_hash description matrixrick <ZERO_BALANCE_COIN_ID_1> <ZERO_BALANCE_COIN_ID_2>
```

Afterwards set to the default initial growth behavior.

- SWAP WALLET TO SAGE SERVER

```sh
$ sui client call --package <USER_PKG_ID> --module user_invite --function set_invite_config --args <INVITE_CAP_ID> <INVITE_CONFIG_ID> true
```

The first user will create a SageSoul, and this type needs to be set in the authentication config in order to authenticate protected functions.

- SWAP WALLET TO SAGE ADMIN

```sh
$ sui client call --package <ADMIN_PKG_ID> --module authentication --function update_soul --type-args <SOUL_TYPE_ID> --args <ADMIN_CAP_ID> <AUTH_CONFIG_ID>
```
