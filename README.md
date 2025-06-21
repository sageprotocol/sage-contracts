# Sagacious

### Install dependencies

[Install Sui](https://docs.sui.io/guides/developer/getting-started/sui-install)

### Build contract

```sh
$ cd contracts/<directory>
$ sui move build
```

### Test contract

```sh
$ cd contracts/<directory>
$ sui move test
```

### Publish contract

```sh
$ cd contracts/<directory>
$ sui client publish --gas-budget 100000000 --verify-deps
```

### Update contract

```sh
$ cd contracts/<directory>
$ sui client upgrade --upgrade-capability <UPGRADE_CAP> --gas-budget 100000000 --verify-deps
```
