module tortuga_aries_lls_strategy::tortuga_aries_lls {

    use aptos_framework::aptos_coin::AptosCoin;

    use satay_blocks::aries_blocks;

    use tortuga_governance::staked_aptos_coin::StakedAptosCoin;
    use std::signer;

    #[cmd]
    /// register `user` on Aries with a `profile_name` as the default account
    public entry fun init_aries_profile(user: &signer, profile_name: vector<u8>) {
        aries_blocks::register_user_with_referrer(user, profile_name, @tortuga_aries_lls_strategy);
    }

    #[cmd]
    /// add subaccount `profile_name` to `user`'s Aries profile
    public entry fun add_aries_subaccount(user: &signer, profile_name: vector<u8>) {
        aries_blocks::add_subaccount(user, profile_name);
    }

    #[cmd]
    /// deposit `deposit_amount` of AptosCoin as collateral for `user`'s `profile_name` account
    /// swap `trade_amount` of AptosCoin using given Hippo route
    public entry fun deposit<Y, Z, E2, E3>(
        user: &signer,
        profile_name: vector<u8>,
        deposit_amount: u64,
        trade_amount: u64,
        minimum_out: u64,
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
        aries_blocks::deposit<AptosCoin>(
            user,
            profile_name,
            deposit_amount
        );
        aries_blocks::leveraged_swap<AptosCoin, Y, Z, StakedAptosCoin, u8, E2, E3>(
            user,
            profile_name,
            true,
            trade_amount,
            minimum_out,
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
    }

    #[cmd]
    /// burn StrategyCoin<BaseCoin, MockStrategy> for user, withdraw BaseCoin from the strategy in return
    /// * user: &signer - must hold amount of StrategyCoin<BaseCoin, MockStrategy>
    /// * amount: u64 - the amount of StrategyCoin<BaseCoin, MockStrategy> to burn
    public entry fun withdraw<Y, Z, E2, E3>(
        user: &signer,
        profile_name: vector<u8>,
        liquidate_amount: u64,
        minimum_out: u64,
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
        let deposited_amount_before = aries_blocks::get_deposit_amount<AptosCoin>(
            signer::address_of(user),
            profile_name
        );
        aries_blocks::leveraged_swap<StakedAptosCoin, Y, Z, AptosCoin, u8, E2, E3>(
            user,
            profile_name,
            true,
            liquidate_amount,
            minimum_out,
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
        if(get_borrowed_amount<AptosCoin>(signer::address_of(user), profile_name) == 0) {
            let deposited_amount_after = aries_blocks::get_deposit_amount<AptosCoin>(
                signer::address_of(user),
                profile_name
            );
            aries_blocks::withdraw<AptosCoin>(
                user,
                profile_name,
                deposited_amount_after - deposited_amount_before
            );
        }
    }

    #[view]
    public fun get_borrowed_amount<CoinType>(user: address, profile_name: vector<u8>) : u64 {
        aries_blocks::get_borrowed_amount_u64<CoinType>(user, profile_name)
    }

    #[view]
    public fun get_deposit_amount<CoinType>(user: address, profile_name: vector<u8>) : u64 {
        aries_blocks::get_deposit_amount<CoinType>(user, profile_name)
    }
}
