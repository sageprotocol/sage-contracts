# Deployment

## Publishing

The order which the contracts are published is important, and errors will be encountered if the proper order is not taken.

1. Utils
2. Admin
3. Notification
4. User
5. Channel
6. Post

This is due to dependencies between the packages:

- "Post" depends on Admin, Channel, and User.
- "Channel" depends on Admin, User, Utils.
- "User" depends on Admin, and Utils.

After each dependent contract is published or upgraded it is important to update the "published-at" and relevant address declaration in all files that depend on the package.

For example, once "Post" has been published copy the object id and replace the "published-at" field in the `Move.toml` file for Post, as well as the address for `sage_post` in the `Move.toml` files for both Post and Channel.

**Note: Document all created objects for a contract in its relevant `README.md` file.**

For local development and testing it may be easier to change all addresses in all `Move.toml` files to "0x0". Use commenting to avoid losing a reference to the published packages.

## Initialization

The very first user needs to be created without an invitation. Afterwards set to the default initial growth behavior.

```sh
$ sui client call --package <USER_PKG_ID> --module actions --function set_invite_config --args <INVITE_CAP_ID> <INVITE_CONFIG_ID> true
```
