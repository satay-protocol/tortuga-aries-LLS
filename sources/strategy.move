module satay_product::strategy {

    use std::signer;

    use std::option;

    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::aptos_coin::AptosCoin;

    use satay_coins::strategy_coin::StrategyCoin;

    use satay::math;
    use satay::satay;
    use satay::strategy_config;

    friend satay_product::vault_strategy;

    struct MockStrategy has drop {}

    // governance functions

    /// initialize StrategyCapability<BaseCoin, MockStrategy> and StrategyCoin<BaseCoin, MockStrategy>
    /// * governance: &signer - must have the governance role on satay::global_config
    public entry fun initialize<BaseCoin>(governance: &signer) {
        satay::new_strategy<BaseCoin, MockStrategy>(governance, MockStrategy {});
    }

    // strategy manager functions

    /// claim rewards, convert to BaseCoin, and deposit back into the strategy
    /// * strategy_manager: &signer - must have the strategy manager role account on satay::strategy_config
    public entry fun tend<BaseCoin>(strategy_manager: &signer) {
        strategy_config::assert_strategy_manager<BaseCoin, MockStrategy>(
            strategy_manager,
            get_strategy_account_address<BaseCoin>(),
        );
        // this logic will vary by strategy
        let base_coin_balance = coin::balance<BaseCoin>(signer::address_of(strategy_manager));
        let base_coins = coin::withdraw<BaseCoin>(strategy_manager, base_coin_balance / 5);
        satay::strategy_deposit<BaseCoin, MockStrategy, BaseCoin>(base_coins, MockStrategy {});
    }

    // user functions

    /// deposit BaseCoin into the strategy for user, mint StrategyCoin<BaseCoin, MockStrategy> in return
    /// * user: &signer - must hold amount of BaseCoin
    /// * amount: u64 - the amount of BaseCoin to deposit
    public entry fun deposit<BaseCoin>(user: &signer, amount: u64) {
        let base_coins = coin::withdraw<BaseCoin>(user, amount);
        let strategy_coins = apply(base_coins);
        if(!coin::is_account_registered<StrategyCoin<BaseCoin, MockStrategy>>(signer::address_of(user))) {
            coin::register<StrategyCoin<BaseCoin, MockStrategy>>(user);
        };
        coin::deposit(signer::address_of(user), strategy_coins);
    }

    /// burn StrategyCoin<BaseCoin, MockStrategy> for user, withdraw BaseCoin from the strategy in return
    /// * user: &signer - must hold amount of StrategyCoin<BaseCoin, MockStrategy>
    /// * amount: u64 - the amount of StrategyCoin<BaseCoin, MockStrategy> to burn
    public entry fun withdraw<BaseCoin>(user: &signer, amount: u64) {
        let strategy_coins = coin::withdraw<StrategyCoin<AptosCoin, MockStrategy>>(user, amount);
        let aptos_coins = liquidate(strategy_coins);
        coin::deposit(signer::address_of(user), aptos_coins);
    }

    /// convert BaseCoin into StrategyCoin<BaseCoin, MockStrategy>
    /// * base_coins: Coin<BaseCoin> - the BaseCoin to convert
    public fun apply<BaseCoin>(base_coins: Coin<BaseCoin>): Coin<StrategyCoin<BaseCoin, MockStrategy>> {
        let base_coin_value = coin::value(&base_coins);
        satay::strategy_deposit<BaseCoin, MockStrategy, BaseCoin>(base_coins, MockStrategy {});
        satay::strategy_mint<BaseCoin, MockStrategy>(base_coin_value, MockStrategy {})
    }

    /// convert StrategyCoin<BaseCoin, MockStrategy> into BaseCoin
    /// * strategy_coins: Coin<StrategyCoin<BaseCoin, MockStrategy>> - the StrategyCoin to convert
    public fun liquidate<BaseCoin>(strategy_coins: Coin<StrategyCoin<BaseCoin, MockStrategy>>): Coin<BaseCoin> {
        let strategy_coin_value = coin::value(&strategy_coins);
        satay::strategy_burn(strategy_coins, MockStrategy {});
        satay::strategy_withdraw<BaseCoin, MockStrategy, BaseCoin>(strategy_coin_value, MockStrategy {})
    }

    // calculations

    /// calculate the amount of product coins that can be minted for a given amount of base coins
    /// * product_coin_amount: u64 - the amount of ProductCoin<BaseCoin> to be converted
    public fun calc_base_coin_amount<BaseCoin>(strategy_coin_amount: u64): u64 {
        let base_coin_balance = satay::get_strategy_balance<BaseCoin, MockStrategy, BaseCoin>();
        let strategy_coin_supply_option = coin::supply<StrategyCoin<BaseCoin, MockStrategy>>();
        let strategy_coin_supply = option::get_with_default(&strategy_coin_supply_option, 0);
        if(strategy_coin_supply == 0) {
            return base_coin_balance
        };
        math::calculate_proportion_of_u64_with_u128_denominator(
            base_coin_balance,
            strategy_coin_amount,
            strategy_coin_supply,
        )
    }

    /// calculate the amount of base coins that can be liquidated for a given amount of product coins
    /// * base_coin_amount: u64 - the amount of BaseCoin to be converted
    public fun calc_product_coin_amount<BaseCoin>(base_coin_amount: u64): u64 {
        let base_coin_balance = satay::get_strategy_balance<BaseCoin, MockStrategy, BaseCoin>();
        let strategy_coin_supply_option = coin::supply<StrategyCoin<BaseCoin, MockStrategy>>();
        if(base_coin_balance == 0) {
            return base_coin_amount
        };
        math::mul_u128_u64_div_u64_result_u64(
            option::get_with_default(&strategy_coin_supply_option, 0),
            base_coin_amount,
            base_coin_balance,
        )
    }

    // getters

    /// gets the address of the product account for BaseCoin
    public fun get_strategy_account_address<BaseCoin>(): address
    {
        satay::get_strategy_address<BaseCoin, MockStrategy>()
    }

    /// gets the witness for the MockStrategy
    public(friend) fun get_strategy_witness(): MockStrategy {
        MockStrategy {}
    }
}
