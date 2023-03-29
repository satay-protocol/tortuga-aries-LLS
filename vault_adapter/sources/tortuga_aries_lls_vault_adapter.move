module satay_tortuga_aries_lls::tortuga_aries_lls_vault_adapter {

    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::account::{Self, SignerCapability};

    use satay::base_strategy;
    use satay::satay;

    use aries::controller;
    use std::signer;

    /// when the strategy account is not initialized by the satay_tortuga_aries_lls account
    const ERR_NOT_DEPLOYER: u64 = 1;

    /// strategy witness
    struct TortugaAriesLLS has drop {}

    struct VaultStrategyAccount has key {
        signer_cap: SignerCapability
    }

    // governance functions

    public entry fun initialize_strategy_account(deployer: &signer) {
        assert!(signer::address_of(deployer) == @satay_tortuga_aries_lls, ERR_NOT_DEPLOYER);
        let (vault_account, signer_cap) = account::create_resource_account(
            deployer,
            b"tortuga_aries_lls_vault_account",
        );
        controller::register_user(&vault_account, b"Leveraged Liquid Staking");
        move_to(deployer, VaultStrategyAccount { signer_cap })
    }

    public entry fun initialize_strategy(governance: &signer) {
       satay::new_strategy<AptosCoin, TortugaAriesLLS>(governance, TortugaAriesLLS {});
    }

    // vault manager functions

    /// approves the strategy on Vault<BaseCoin>
    /// * vault_manager: &signer - must have the vault manager role for Vault<BaseCoin>
    /// * debt_ratio: u64 - in BPS
    public entry fun approve(vault_manager: &signer, debt_ratio: u64) {
        base_strategy::approve_strategy<AptosCoin, TortugaAriesLLS>(
            vault_manager,
            debt_ratio,
            TortugaAriesLLS {}
        );
    }

    /// updates the debt ratio of the strategy on Vault<BaseCoin>
    /// * vault_manager: &signer - must have the vault manager role for Vault<BaseCoin>
    /// * debt_ratio: u64 - in BPS
    public entry fun update_debt_ratio(vault_manager: &signer, debt_ratio: u64) {
        base_strategy::update_debt_ratio<AptosCoin, TortugaAriesLLS>(
            vault_manager,
            debt_ratio,
            TortugaAriesLLS {}
        );
    }

    /// sets the debt ratio of the strategy to 0
    /// * vault_manager: &signer - must have the vault manager role for Vault<BaseCoin>
    public entry fun revoke(vault_manager: &signer) {
        update_debt_ratio(vault_manager, 0);
    }

    // keeper functions

    /// harvests the strategy, recognizing any profits or losses and adjusting the strategy's position
    /// * keeper: &signer - must be the keeper for the strategy on Vault<BaseCoin>
    public entry fun harvest(_keeper: &signer) {

        // let product_coin_balance = satay::get_vault_balance<AptosCoin, StrategyCoin<AptosCoin, TortugaAriesLLS>>();
        // let base_coin_balance = tortuga_aries_lls::calc_base_coin_amount(product_coin_balance);
        //
        // let (
        //     to_apply,
        //     harvest_lock
        // ) = base_strategy::open_vault_for_harvest<AptosCoin, TortugaAriesLLS>(
        //     keeper,
        //     base_coin_balance,
        //     tortuga_aries_lls::get_strategy_witness()
        // );
        //
        // let product_coins = tortuga_aries_lls::apply(to_apply);
        //
        // let debt_payment_amount = base_strategy::get_harvest_debt_payment(&harvest_lock);
        // let profit_amount = base_strategy::get_harvest_profit(&harvest_lock);
        //
        // let to_liquidate_amount = tortuga_aries_lls::calc_product_coin_amount(debt_payment_amount + profit_amount);
        // let to_liquidate = base_strategy::withdraw_strategy_coin<AptosCoin, TortugaAriesLLS>(
        //     &harvest_lock,
        //     to_liquidate_amount
        // );
        //
        // let base_coins = tortuga_aries_lls::liquidate(to_liquidate);
        // let debt_payment = coin::extract(&mut base_coins, debt_payment_amount);
        // let profit = coin::extract_all(&mut base_coins);
        // coin::destroy_zero(base_coins);
        //
        // base_strategy::close_vault_for_harvest<AptosCoin, TortugaAriesLLS>(
        //     harvest_lock,
        //     debt_payment,
        //     profit,
        //     product_coins,
        // );
    }

    // user functions

    /// liquidate strategy position if vault does not have enough BaseCoin for amount of VaultCoin<BaseCoin>
    /// * user: &signer - must hold amount of VaultCoin<BaseCoin>
    /// * amount: u64 - the amount of VaultCoin<BaseCoin> to liquidate
    public entry fun withdraw_for_user(_user: &signer, _amount: u64) {
        // let vault_coins = coin::withdraw<VaultCoin<AptosCoin>>(user, amount);
        // let user_withdraw_lock = base_strategy::open_vault_for_user_withdraw<AptosCoin, TortugaAriesLLS>(
        //     user,
        //     vault_coins,
        //     TortugaAriesLLS {}
        // );
        //
        // let amount_needed = base_strategy::get_user_withdraw_amount_needed(&user_withdraw_lock);
        // let product_coin_amount = tortuga_aries_lls::calc_product_coin_amount(amount_needed);
        // let product_coins = base_strategy::withdraw_strategy_coin_for_liquidation<AptosCoin, TortugaAriesLLS>(
        //     &user_withdraw_lock,
        //     product_coin_amount,
        // );
        // let base_coins = tortuga_aries_lls::liquidate(product_coins);
        //
        // base_strategy::close_vault_for_user_withdraw<AptosCoin, TortugaAriesLLS>(user_withdraw_lock, base_coins);
    }
}