# Deployment

## Publishing

The order which the contracts are published is important, and errors will be encountered if the proper order is not taken.

1. Immutable
2. Utils
3. Admin
4. User
5. Channel
6. Post
7. Notification
8. Sage

This is due to dependencies between the packages:

- "Sage" depends on Admin, Immutable, Channel, Notification, Post, and User.
- "Post" depends on Admin, Immutable, Channel, and User.
- "Channel" depends on Admin, Immutable, User, Utils.
- "User" depends on Admin, Immutable, and Utils.

After each dependent contract is published or upgraded it is important to update the "published-at" and relevant address declaration in all files that depend on the package.

For example, once "Post" has been published copy the object id and replace the "published-at" field in the `Move.toml` file for Post, as well as the address for `sage_post` in the `Move.toml` files for both Post and Channel.

**Note: Document all created objects for a contract in its relevant `README.md` file.**

For local development and testing it may be easier to change all addresses in all `Move.toml` files to "0x0". Use commenting to avoid losing a reference to the published packages.

## Initialization

Publishing the packages is not sufficient to initialize the entire project. Once the contracts are deployed the registries must be created for the contracts to function.

```sh
$ sui client call --package <SAGE_PKG_ID> --module actions --function create_registries --args <ADMIN_CAP_ID> <SAGE_CHANNEL_ID> <SAGE_CHANNEL_MEMBERSHIP_ID> <SAGE_CHANNEL_POSTS_ID> <SAGE_INVITE_CONFIG_ID> <SAGE_NOTIFICATION_ID> <SAGE_POST_ID> <SAGE_POST_COMMENTS_ID> <SAGE_POST_LIKES_ID> <SAGE_USER_INVITE_ID> <SAGE_USER_MEMBERSHIP_ID> <SAGE_USER_POST_LIKES_ID> <SAGE_USER_POSTS_ID> <SAGE_USERS_ID>
```
