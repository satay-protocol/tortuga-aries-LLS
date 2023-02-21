# Base Strategy

This repository contains a boilerplate package to create yield strategies under the Satay Vault Framework. The package is broken into two modules: `strategy.move` and `vault_strategy.move`.

## `strategy.move`

The strategy module is responsible for opening and closing yield positions with third-party protocols.

### Strategy Witness

First, each strategy must define a struct that will be used to initialize the `StrategyCoin` associated with the strategy. The struct must have the `drop` ability as it will also be used in an implementation of the [Move Witness Pattern](https://www.move-patterns.com/witness.html).

```rust
struct MockStrategy has drop {}
```

### Initialize

Each strategy must provide an `initialize` function that calls `satay::new_strategy` to initialize the strategy’s `StrategyCoin`. `satay::new_strategy` asserts that the signer has the `governance` role on the `satay::global_config` module.

This function also creates a `StrategyConfig` object in the `satay::strategy_config` module, which defines the `strategy_manager` role used for strategy operation access control.

```rust
/// initialize StrategyCapability<BaseCoin, MockStrategy> and StrategyCoin<BaseCoin, MockStrategy>
/// * governance: &signer - must have the governance role on satay::global_config
public entry fun initialize<BaseCoin>(governance: &signer) {
    satay::new_strategy<BaseCoin, MockStrategy>(governance, MockStrategy {});
}
```

### Tend

The tend function harvests the yield of the strategy, converts the rewards to the strategy’s `BaseCoin`, and returns the `BaseCoin` profits to the strategy account. The logic for the tend function will differ by strategy. Strategies 

```rust
/// claim rewards, convert to BaseCoin, and deposit back into the strategy
/// * strategy_manager: &signer - must have the strategy manager role account on satay::strategy_config
public entry fun tend<BaseCoin>(strategy_manager: &signer) {
    strategy_config::assert_strategy_manager<BaseCoin, MockStrategy>(
        strategy_manager,
        get_strategy_account_address<BaseCoin>(),
    );
		// unique logic for strategy tend
    ...
}
```

# `vault_strategy.move`
