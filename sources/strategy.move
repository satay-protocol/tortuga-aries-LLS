module satay_tortuga_aries_lls::strategy {

    use std::signer;

    use std::option;

    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;

    use satay_coins::strategy_coin::StrategyCoin;

    use satay::math;
    use satay::satay;

    use aries_blocks::borrow_lend;

    use tortuga_governance::staked_aptos_coin::StakedAptosCoin;

    friend satay_tortuga_aries_lls::vault_strategy;

    struct TortugaAriesLLS has drop {}

    const STRATEGY_ACCOUNT_NAME: vector<u8> = b"LLS Strategy";

    // governance functions

    /// initialize StrategyCapability<BaseCoin, MockStrategy> and StrategyCoin<BaseCoin, MockStrategy>
    /// * governance: &signer - must have the governance role on satay::global_config
    public entry fun initialize(governance: &signer) {
        satay::new_strategy<AptosCoin, TortugaAriesLLS>(governance, TortugaAriesLLS {});
    }

    // user functions

    /// deposit BaseCoin into the strategy for user, mint StrategyCoin<BaseCoin, MockStrategy> in return
    /// * user: &signer - must hold amount of BaseCoin
    /// * amount: u64 - the amount of BaseCoin to deposit
    public entry fun deposit<Y, Z, E2, E3>(
        user: &signer,
        amount: u64,
        num_steps: u8,
        first_dex_type: u8,
        first_pool_type: u64,
        first_is_x_to_y: bool,
        second_dex_type: u8,
        second_pool_type: u64,
        second_is_x_to_y: bool,
        third_dex_type: u8,
        third_pool_type: u64,
        third_is_x_to_y: bool
    ) {
        let user_addr = signer::address_of(user);
        let deposit_amount_before = borrow_lend::get_deposit_amount<StakedAptosCoin>(
            user_addr,
            STRATEGY_ACCOUNT_NAME
        );
        borrow_lend::deposit<AptosCoin>(
            user,
            STRATEGY_ACCOUNT_NAME,
            amount
        );

        let borrow_amount: u64 = 0;
        borrow_lend::leveraged_swap<AptosCoin, Y, Z, StakedAptosCoin, u8, E2, E3>(
            user,
            STRATEGY_ACCOUNT_NAME,
            true,
            borrow_amount,
            0,
            num_steps,
            first_dex_type,
            first_pool_type,
            first_is_x_to_y,
            second_dex_type,
            second_pool_type,
            second_is_x_to_y,
            third_dex_type,
            third_pool_type,
            third_is_x_to_y,
        );
        let deposit_amount_after = borrow_lend::get_deposit_amount<StakedAptosCoin>(
            user_addr,
            STRATEGY_ACCOUNT_NAME
        );

        let strategy_coins = satay::strategy_mint<AptosCoin, TortugaAriesLLS>(
            deposit_amount_after - deposit_amount_before,
            TortugaAriesLLS {}
        );
        if(!coin::is_account_registered<StrategyCoin<AptosCoin, TortugaAriesLLS>>(signer::address_of(user))) {
            coin::register<StrategyCoin<AptosCoin, TortugaAriesLLS>>(user);
        };
        coin::deposit(signer::address_of(user), strategy_coins);
    }

    /// burn StrategyCoin<BaseCoin, MockStrategy> for user, withdraw BaseCoin from the strategy in return
    /// * user: &signer - must hold amount of StrategyCoin<BaseCoin, MockStrategy>
    /// * amount: u64 - the amount of StrategyCoin<BaseCoin, MockStrategy> to burn
    public entry fun withdraw<Y, Z, E2, E3>(
        user: &signer,
        amount: u64,
        num_steps: u8,
        first_dex_type: u8,
        first_pool_type: u64,
        first_is_x_to_y: bool,
        second_dex_type: u8,
        second_pool_type: u64,
        second_is_x_to_y: bool,
        third_dex_type: u8,
        third_pool_type: u64,
        third_is_x_to_y: bool
    ) {
        let aptos_amount_before = borrow_lend::get_deposit_amount<AptosCoin>(
            signer::address_of(user),
            STRATEGY_ACCOUNT_NAME
        );
        borrow_lend::leveraged_swap<StakedAptosCoin, Y, Z, AptosCoin, u8, E2, E3>(
            user,
            STRATEGY_ACCOUNT_NAME,
            true,
            amount,
            0,
            num_steps,
            first_dex_type,
            first_pool_type,
            first_is_x_to_y,
            second_dex_type,
            second_pool_type,
            second_is_x_to_y,
            third_dex_type,
            third_pool_type,
            third_is_x_to_y,
        );
        let aptos_amount_after = borrow_lend::get_deposit_amount<AptosCoin>(
            signer::address_of(user),
            STRATEGY_ACCOUNT_NAME
        );
        borrow_lend::withdraw<AptosCoin>(user, STRATEGY_ACCOUNT_NAME, aptos_amount_after - aptos_amount_before);
        satay::strategy_burn<AptosCoin, TortugaAriesLLS>(
            coin::withdraw<StrategyCoin<AptosCoin, TortugaAriesLLS>>(user, amount),
            TortugaAriesLLS {}
        );
    }

    // /// convert BaseCoin into StrategyCoin<BaseCoin, MockStrategy>
    // /// * base_coins: Coin<BaseCoin> - the BaseCoin to convert
    // public fun apply<Y, Z, E2, E3>(
    //     sender: &signer,
    //     num_steps: u8,
    //     first_dex_type: u8,
    //     first_pool_type: u64,
    //     first_is_x_to_y: bool, // first trade uses normal order
    //     second_dex_type: u8,
    //     second_pool_type: u64,
    //     second_is_x_to_y: bool, // second trade uses normal order
    //     third_dex_type: u8,
    //     third_pool_type: u64,
    //     third_is_x_to_y: bool, // second trade uses normal order
    //     aptos_coins: Coin<AptosCoin>
    // ): Coin<StrategyCoin<AptosCoin, TortugaAriesLLS>> {
    //     let deposit_amount_before = borrow_lend::get_deposit_amount<StakedAptosCoin>(
    //         signer::address_of(sender),
    //         STRATEGY_ACCOUNT_NAME
    //     );
    //     let tapt = stake_unstake::stake<Y, Z, E2, E3>(
    //         sender,
    //         num_steps,
    //         first_dex_type,
    //         first_pool_type,
    //         first_is_x_to_y,
    //         second_dex_type,
    //         second_pool_type,
    //         second_is_x_to_y,
    //         third_dex_type,
    //         third_pool_type,
    //         third_is_x_to_y,
    //         aptos_coins
    //     );
    //     coin::deposit(signer::address_of(sender), tapt);
    //     let tapt_value = coin::value(&tapt);
    //     borrow_lend::deposit<StakedAptosCoin>(
    //         sender,
    //         STRATEGY_ACCOUNT_NAME,
    //         tapt_value
    //     );
    //
    //     let borrow_amount: u64 = 0;
    //
    //     borrow_lend::leveraged_swap<AptosCoin, Y, Z, StakedAptosCoin, u8, E2, E3>(
    //         sender,
    //         STRATEGY_ACCOUNT_NAME,
    //         true,
    //         borrow_amount,
    //         0,
    //         num_steps,
    //         first_dex_type,
    //         first_pool_type,
    //         first_is_x_to_y,
    //         second_dex_type,
    //         second_pool_type,
    //         second_is_x_to_y,
    //         third_dex_type,
    //         third_pool_type,
    //         third_is_x_to_y,
    //     );
    //
    //     let deposit_amount_after = borrow_lend::get_deposit_amount<StakedAptosCoin>(
    //         signer::address_of(sender),
    //         STRATEGY_ACCOUNT_NAME
    //     );
    //
    //     satay::strategy_mint<AptosCoin, TortugaAriesLLS>(
    //         deposit_amount_after - deposit_amount_before,
    //         TortugaAriesLLS {}
    //     )
    // }
    //
    // /// convert StrategyCoin<BaseCoin, MockStrategy> into BaseCoin
    // /// * strategy_coins: Coin<StrategyCoin<BaseCoin, MockStrategy>> - the StrategyCoin to convert
    // public fun liquidate<Y, Z, E2, E3>(
    //     sender: &signer,
    //     num_steps: u8,
    //     first_dex_type: u8,
    //     first_pool_type: u64,
    //     first_is_x_to_y: bool, // first trade uses normal order
    //     second_dex_type: u8,
    //     second_pool_type: u64,
    //     second_is_x_to_y: bool, // second trade uses normal order
    //     third_dex_type: u8,
    //     third_pool_type: u64,
    //     third_is_x_to_y: bool, // second trade uses normal order
    //     strategy_coins: Coin<StrategyCoin<AptosCoin, TortugaAriesLLS>>
    // ): Coin<AptosCoin> {
    //     let strategy_coin_value = coin::value(&strategy_coins);
    //     let aptos_amount_before = borrow_lend::get_deposit_amount<AptosCoin>(
    //         signer::address_of(sender),
    //         STRATEGY_ACCOUNT_NAME
    //     );
    //     borrow_lend::leveraged_swap<StakedAptosCoin, Y, Z, AptosCoin, u8, E2, E3>(
    //         sender,
    //         STRATEGY_ACCOUNT_NAME,
    //         true,
    //         strategy_coin_value,
    //         0,
    //         num_steps,
    //         first_dex_type,
    //         first_pool_type,
    //         first_is_x_to_y,
    //         second_dex_type,
    //         second_pool_type,
    //         second_is_x_to_y,
    //         third_dex_type,
    //         third_pool_type,
    //         third_is_x_to_y,
    //     );
    //     let aptos_amount_after = borrow_lend::get_deposit_amount<AptosCoin>(
    //         signer::address_of(sender),
    //         STRATEGY_ACCOUNT_NAME
    //     );
    //     borrow_lend::withdraw<AptosCoin>(sender, STRATEGY_ACCOUNT_NAME, aptos_amount_after - aptos_amount_before);
    //     satay::strategy_burn<AptosCoin, TortugaAriesLLS>(strategy_coins, TortugaAriesLLS {});
    // }

    // calculations

    /// calculate the amount of product coins that can be minted for a given amount of base coins
    /// * product_coin_amount: u64 - the amount of ProductCoin<BaseCoin> to be converted
    public fun calc_base_coin_amount(strategy_coin_amount: u64): u64 {
        let base_coin_balance = satay::get_strategy_balance<AptosCoin, TortugaAriesLLS, AptosCoin>();
        let strategy_coin_supply_option = coin::supply<StrategyCoin<AptosCoin, TortugaAriesLLS>>();
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
    public fun calc_product_coin_amount(base_coin_amount: u64): u64 {
        let base_coin_balance = satay::get_strategy_balance<AptosCoin, TortugaAriesLLS, AptosCoin>();
        let strategy_coin_supply_option = coin::supply<StrategyCoin<AptosCoin, TortugaAriesLLS>>();
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
    public fun get_strategy_account_address(): address
    {
        satay::get_strategy_address<AptosCoin, TortugaAriesLLS>()
    }

    /// gets the witness for the MockStrategy
    public(friend) fun get_strategy_witness(): TortugaAriesLLS {
        TortugaAriesLLS {}
    }
}
