module satay_product::vault_strategy {

    use aptos_framework::coin;

    use satay_product::strategy::{Self, MockStrategy};

    use satay_coins::vault_coin::VaultCoin;

    use satay::base_strategy;
    use satay::satay;
    use satay_coins::strategy_coin::StrategyCoin;

    // vault manager functions

    /// initializes strategy on vault_id
    /// @param vault_manager - the transaction signer; must be the vault manager of vault_id
    /// @param vault_id - the vault to initialize strategy on
    /// @param debt_ratio - the initial debt ratio of the strategy
    public entry fun initialize<BaseCoin>(
        vault_manager: &signer,
        debt_ratio: u64
    ) {
        base_strategy::approve_strategy<BaseCoin, MockStrategy>(
            vault_manager,
            debt_ratio,
            strategy::get_strategy_witness()
        );
    }

    /// sets the debt ratio of the strategy
    /// @param vault_manager - the transaction signer; must be the vault manager of vault_id
    /// @param vault_id - the vault to set the debt ratio on
    /// @param debt_ratio - the new debt ratio of the strategy
    public entry fun update_debt_ratio<BaseCoin>(vault_manager: &signer, debt_ratio: u64) {
        base_strategy::update_debt_ratio<BaseCoin, MockStrategy>(
            vault_manager,
            debt_ratio,
            strategy::get_strategy_witness()
        );
    }

    /// sets the debt ratio of the strategy to 0
    /// @param vault_manager - the transaction signer; must be the vault manager of vault_id
    /// @param vault_id - the vault to set the debt ratio on
    public entry fun revoke<BaseCoin>(vault_manager: &signer) {
        update_debt_ratio<BaseCoin>(vault_manager, 0);
    }

    // keeper functions

    /// Harvests the strategy, recognizing any profits or losses and adjusting the strategy's position.
    /// @param keeper - the transaction signer; must be the keeper of vault_id
    /// @param vault_id - the vault to harvest
    public entry fun harvest<BaseCoin>(keeper: &signer) {

        let product_coin_balance = satay::get_vault_balance<BaseCoin, StrategyCoin<BaseCoin, MockStrategy>>();
        let base_coin_balance = strategy::calc_base_coin_amount<BaseCoin>(product_coin_balance);

        let (
            to_apply,
            harvest_lock
        ) = base_strategy::open_vault_for_harvest<BaseCoin, MockStrategy>(
            keeper,
            base_coin_balance,
            strategy::get_strategy_witness()
        );

        let product_coins = strategy::apply<BaseCoin>(to_apply);

        let debt_payment_amount = base_strategy::get_harvest_debt_payment(&harvest_lock);
        let profit_amount = base_strategy::get_harvest_profit(&harvest_lock);

        let to_liquidate_amount = strategy::calc_product_coin_amount<BaseCoin>(debt_payment_amount + profit_amount);
        let to_liquidate = base_strategy::withdraw_strategy_coin<BaseCoin, MockStrategy>(
            &harvest_lock,
            to_liquidate_amount
        );

        let base_coins = strategy::liquidate<BaseCoin>(to_liquidate);
        let debt_payment = coin::extract(&mut base_coins, debt_payment_amount);
        let profit = coin::extract_all(&mut base_coins);
        coin::destroy_zero(base_coins);

        base_strategy::close_vault_for_harvest<BaseCoin, MockStrategy>(
            harvest_lock,
            debt_payment,
            profit,
            product_coins,
        );
    }

    // user functions

    /// liquidate strategy position if vault does not have enough liqidity for amount of VaultCoin<BaseCoin>
    /// @param user - the transaction signer; must hold amount of VaultCoin<BaseCoin>
    /// @param vault_id - the vault to liquidate
    /// @param amount - the amount of VaultCoin<BaseCoin> to liquidate
    public entry fun withdraw_for_user<BaseCoin>(user: &signer, amount: u64) {
        let vault_coins = coin::withdraw<VaultCoin<BaseCoin>>(user, amount);
        let user_withdraw_lock = base_strategy::open_vault_for_user_withdraw<BaseCoin, MockStrategy>(
            user,
            vault_coins,
            strategy::get_strategy_witness()
        );

        let amount_needed = base_strategy::get_user_withdraw_amount_needed(&user_withdraw_lock);
        let product_coin_amount = strategy::calc_product_coin_amount<BaseCoin>(amount_needed);
        let product_coins = base_strategy::withdraw_strategy_coin_for_liquidation<BaseCoin, MockStrategy>(
            &user_withdraw_lock,
            product_coin_amount,
        );
        let base_coins = strategy::liquidate<BaseCoin>(product_coins);

        base_strategy::close_vault_for_user_withdraw<BaseCoin, MockStrategy>(user_withdraw_lock, base_coins);
    }
}