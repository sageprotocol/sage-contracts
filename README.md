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

### Deploy contract

- SWAP WALLET TO SAGE ADMIN

```sh
$ cd contracts/<directory>
$ sui client publish --gas-budget 100000000
```
