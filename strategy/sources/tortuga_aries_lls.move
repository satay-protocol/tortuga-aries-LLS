module tortuga_aries_lls_strategy::tortuga_aries_lls {

    use aptos_framework::aptos_coin::AptosCoin;

    use satay_blocks::aries_blocks;

    use tortuga_governance::staked_aptos_coin::StakedAptosCoin;


    #[cmd]
    /// deposit BaseCoin into the strategy for user, mint StrategyCoin<BaseCoin, MockStrategy> in return
    /// * user: &signer - must hold amount of BaseCoin
    /// * amount: u64 - the amount of BaseCoin to deposit
    public entry fun deposit<Y, Z, E2, E3>(
        user: &signer,
        profile_name: vector<u8>,
        deposit_amount: u64,
        trade_amount: u64,
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
    }

    #[cmd]
    /// burn StrategyCoin<BaseCoin, MockStrategy> for user, withdraw BaseCoin from the strategy in return
    /// * user: &signer - must hold amount of StrategyCoin<BaseCoin, MockStrategy>
    /// * amount: u64 - the amount of StrategyCoin<BaseCoin, MockStrategy> to burn
    public entry fun withdraw<Y, Z, E2, E3>(
        user: &signer,
        profile_name: vector<u8>,
        withdraw_amount: u64,
        liquidate_amount: u64,
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
        aries_blocks::leveraged_swap<StakedAptosCoin, Y, Z, AptosCoin, u8, E2, E3>(
            user,
            profile_name,
            true,
            liquidate_amount,
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
        aries_blocks::withdraw<AptosCoin>(
            user,
            profile_name,
            withdraw_amount
        );
    }
}
