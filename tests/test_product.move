#[test_only]
module satay_product::test_product {

    use aptos_framework::aptos_coin::AptosCoin;

    use satay_product::product;
    use aptos_framework::stake;
    use aptos_framework::account;
    use std::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin;

    const DEPOSIT_AMOUNT: u64 = 100000;

    const ERR_INITIALIZE: u64 = 1;

    struct TestProduct has drop {}

    fun setup_tests(
        aptos_framework: &signer,
        satay_product: &signer,
        user: &signer,
    ) {
        stake::initialize_for_test(aptos_framework);
        product::initialize<TestProduct, AptosCoin>(satay_product);

        let user_addr = signer::address_of(user);
        account::create_account_for_test(user_addr);
        coin::register<AptosCoin>(user);
        aptos_coin::mint(aptos_framework, user_addr, DEPOSIT_AMOUNT);
    }

    #[test(
        aptos_framework = @aptos_framework,
        deployer = @satay_product,
        user = @0x100,
    )]
    fun test_initialize(
        aptos_framework: &signer,
        deployer: &signer,
        user: &signer,
    ) {
        setup_tests(aptos_framework, deployer, user);
        let product_addr = product::product_account_address<TestProduct, AptosCoin>();
        assert!(coin::is_account_registered<AptosCoin>(product_addr), ERR_INITIALIZE);
    }

    #[test(
        aptos_framework = @aptos_framework,
        deployer = @satay_product,
        user = @0x100
    )]
    fun test_deposit(
        aptos_framework: &signer,
        deployer: &signer,
        user: &signer
    ) {
        setup_tests(aptos_framework, deployer, user);
        product::deposit<TestProduct, AptosCoin>(user, DEPOSIT_AMOUNT);
    }

    #[test(
        aptos_framework = @aptos_framework,
        deployer = @satay_product,
        user = @0x100
    )]
    fun test_withdraw(
        aptos_framework: &signer,
        deployer: &signer,
        user: &signer
    ) {
        setup_tests(aptos_framework, deployer, user);
        product::deposit<TestProduct, AptosCoin>(user, DEPOSIT_AMOUNT);
        product::withdraw<TestProduct, AptosCoin>(user, DEPOSIT_AMOUNT);
    }

    #[test(
        aptos_framework = @aptos_framework,
        deployer = @satay_product,
        user = @0x100
    )]
    fun test_tend(
        aptos_framework: &signer,
        deployer: &signer,
        user: &signer
    ) {
        setup_tests(aptos_framework, deployer, user);
        product::deposit<TestProduct, AptosCoin>(user, DEPOSIT_AMOUNT);
        product::tend<TestProduct, AptosCoin>(deployer);
    }


}
