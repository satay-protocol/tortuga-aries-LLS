module satay_product::strategy {

    use aptos_framework::coin;

    use satay_product::product::{Self, ProductCoin};

    use satay_vault_coin::vault_coin::VaultCoin;

    use satay::base_strategy;
    use satay::vault;

    /// used as StrategyType in vault operations
    /// part of witness pattern implementation
    struct StrategyWitness has drop {}

    // vault manager functions

    /// initializes strategy on vault_id
    /// @param vault_manager - the transaction signer; must be the vault manager of vault_id
    /// @param vault_id - the vault to initialize strategy on
    /// @param debt_ratio - the initial debt ratio of the strategy
    public entry fun initialize<BaseCoin>(
        vault_manager: &signer,
        vault_id: u64,
        debt_ratio: u64
    ) {
        base_strategy::initialize<StrategyWitness, ProductCoin<BaseCoin>>(
            vault_manager,
            debt_ratio,
            vault_id,
            StrategyWitness {}
        );
    }

    /// sets the debt ratio of the strategy
    /// @param vault_manager - the transaction signer; must be the vault manager of vault_id
    /// @param vault_id - the vault to set the debt ratio on
    /// @param debt_ratio - the new debt ratio of the strategy
    public entry fun update_debt_ratio(
        vault_manager: &signer,
        vault_id: u64,
        debt_ratio: u64
    ) {
        base_strategy::update_debt_ratio<StrategyWitness>(
            vault_manager,
            debt_ratio,
            vault_id,
            StrategyWitness {}
        );
    }

    /// sets the debt ratio of the strategy to 0
    /// @param vault_manager - the transaction signer; must be the vault manager of vault_id
    /// @param vault_id - the vault to set the debt ratio on
    public entry fun revoke(
        vault_manager: &signer,
        vault_id: u64
    ) {
        update_debt_ratio(vault_manager, vault_id, 0);
    }

    // keeper functions

    /// Harvests the strategy, recognizing any profits or losses and adjusting the strategy's position.
    /// @param keeper - the transaction signer; must be the keeper of vault_id
    /// @param vault_id - the vault to harvest
    public entry fun harvest<BaseCoin>(
        keeper: &signer,
        vault_id: u64
    ) {
        let (
            keeper_cap,
            vault_cap_lock
        ) = base_strategy::open_vault_for_harvest<StrategyWitness, BaseCoin>(
            keeper,
            vault_id,
            StrategyWitness {}
        );

        let product_coin_balance = vault::harvest_balance<StrategyWitness, ProductCoin<BaseCoin>>(&keeper_cap);
        let base_coin_balance = product::calc_base_coin_amount<BaseCoin>(product_coin_balance);

        let (
            to_apply,
            harvest_lock
        ) = base_strategy::process_harvest<StrategyWitness, BaseCoin, ProductCoin<BaseCoin>>(
            &keeper_cap,
            base_coin_balance,
            vault_cap_lock
        );

        let product_coins = product::apply<BaseCoin>(to_apply);

        let debt_payment_amount = base_strategy::get_harvest_debt_payment(&harvest_lock);
        let profit_amount = base_strategy::get_harvest_profit(&harvest_lock);

        let to_liquidate_amount = product::calc_product_coin_amount<BaseCoin>(debt_payment_amount + profit_amount);
        let to_liquidate = base_strategy::withdraw_strategy_coin<StrategyWitness, ProductCoin<BaseCoin>>(
            &keeper_cap,
            to_liquidate_amount
        );

        let base_coins = product::liquidate<BaseCoin>(to_liquidate);
        let debt_payment = coin::extract(&mut base_coins, debt_payment_amount);
        let profit = coin::extract_all(&mut base_coins);
        coin::destroy_zero(base_coins);

        base_strategy::close_vault_for_harvest<StrategyWitness, BaseCoin, ProductCoin<BaseCoin>>(
            keeper_cap,
            harvest_lock,
            debt_payment,
            profit,
            product_coins,
        );
    }

    /// reinvest accrued rewards
    /// @param keeper - the transaction signer; must be the keeper of vault_id
    /// @param vault_id - the vault to reinvest rewards on
    public entry fun tend<BaseCoin>(
        keeper: &signer,
        vault_id: u64
    ) {
        let (
            keeper_cap,
            tend_lock
        ) = base_strategy::open_vault_for_tend<StrategyWitness, BaseCoin>(
            keeper,
            vault_id,
            StrategyWitness {}
        );
        product::tend<BaseCoin>(keeper);
        base_strategy::close_vault_for_tend<StrategyWitness, ProductCoin<BaseCoin>>(
            keeper_cap,
            tend_lock,
            coin::zero()
        )
    }

    // user functions

    /// liquidate strategy position if vault does not have enough liqidity for amount of VaultCoin<BaseCoin>
    /// @param user - the transaction signer; must hold amount of VaultCoin<BaseCoin>
    /// @param vault_id - the vault to liquidate
    /// @param amount - the amount of VaultCoin<BaseCoin> to liquidate
    public entry fun withdraw_for_user<BaseCoin>(
        user: &signer,
        vault_id: u64,
        amount: u64
    ) {
        let vault_coins = coin::withdraw<VaultCoin<BaseCoin>>(user, amount);
        let (
            user_cap,
            user_withdraw_lock
        ) = base_strategy::open_vault_for_user_withdraw<StrategyWitness, BaseCoin, ProductCoin<BaseCoin>>(
            user,
            vault_id,
            vault_coins,
            StrategyWitness {}
        );

        let amount_needed = base_strategy::get_user_withdraw_amount_needed(&user_withdraw_lock);
        let product_coin_amount = product::calc_product_coin_amount<BaseCoin>(amount_needed);
        let product_coins = base_strategy::withdraw_strategy_coin_for_liquidation<StrategyWitness, ProductCoin<BaseCoin>, BaseCoin>(
            &user_cap,
            product_coin_amount,
            &user_withdraw_lock
        );
        let base_coins = product::liquidate<BaseCoin>(product_coins);

        base_strategy::close_vault_for_user_withdraw<StrategyWitness, BaseCoin>(
            user_cap,
            user_withdraw_lock,
            base_coins
        );
    }
}
