module satay_product::product {

    use std::signer;
    use std::string;

    use aptos_framework::coin::{Self, MintCapability, BurnCapability, Coin};
    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::aptos_coin::AptosCoin;

    const ERR_NOT_DEPLOYER: u64 = 1;
    const ERR_NOT_MANAGER: u64 = 2;

    /// replace this with the decimals for the coin you are issuing
    const DECIMALS: u8 = 8;
    /// replace this with the name of the coin you are issuing
    const NAME: vector<u8> = b"Product Coin";
    /// replace this with the symbol of the coin you are issuing
    const SYMBOL: vector<u8> = b"PC";

    /// replace this with the unique product coin name
    struct ProductCoin<phantom BaseCoin> {}

    struct ProductAccount<phantom BaseCoin> has key {
        signer_cap: SignerCapability,
        manager_address: address,
        mint_cap: MintCapability<ProductCoin<BaseCoin>>,
        burn_cap: BurnCapability<ProductCoin<BaseCoin>>,
    }

    // init

    /// initialize the product account
    /// @param deployer - the transaction signer; must be the module deployer
    public entry fun initialize<BaseCoin>(deployer: &signer) {
        // assert that the deployer is calling initialize
        assert_deployer(deployer);

        let (
            burn_cap,
            freeze_cap,
            mint_cap
        ) = coin::initialize<ProductCoin<BaseCoin>>(
            deployer,
            string::utf8(NAME),
            string::utf8(SYMBOL),
            DECIMALS,
            true,
        );
        coin::destroy_freeze_cap(freeze_cap);

        let (
            product_signer,
            signer_cap
        ) = account::create_resource_account(deployer, b"boilerplate product");

        // products may accept different base coins, in which case you would need to replace AptosCoin
        coin::register<AptosCoin>(&product_signer);

        let product_account = ProductAccount {
            signer_cap,
            manager_address: signer::address_of(deployer),
            mint_cap,
            burn_cap,
        };

        move_to(deployer, product_account);
    }

    // scripts

    /// mint product coins
    /// @param user - the transaction signer; must hold amount of BaseCoin
    /// @param amount - the amount of BaseCoin to be converted to ProductCoin
    public entry fun deposit<BaseCoin>(user: &signer, amount: u64)
    acquires ProductAccount {
        let base_coins = coin::withdraw<BaseCoin>(user, amount);
        let product_coins = apply(base_coins);
        coin::deposit<ProductCoin<BaseCoin>>(signer::address_of(user), product_coins);
    }

    /// burn product coins
    /// @param user - the transaction signer; must hold amount of ProductCoin
    /// @param amount - the amount of ProductCoin to be converted to BaseCoin
    public entry fun withdraw<BaseCoin>(user: &signer, amount: u64)
    acquires ProductAccount {
        let product_coins = coin::withdraw<ProductCoin<BaseCoin>>(user, amount);
        let base_coins = liquidate(product_coins);
        coin::deposit<BaseCoin>(signer::address_of(user), base_coins);
    }

    /// claim rewards and reinvest
    /// @param user - the transaction signer; must hold > 0 ProductCoin
    public entry fun claim<BaseCoin>(user: &signer) {
        let product_coins = tend<BaseCoin>(user);
        coin::deposit<ProductCoin<BaseCoin>>(signer::address_of(user), product_coins);
    }

    // operations

    /// convert base coins to product coins
    /// @param base_coins - the base coins to convert
    public fun apply<BaseCoin>(base_coins: Coin<BaseCoin>): Coin<ProductCoin<BaseCoin>>
    acquires ProductAccount {
        let product_account = borrow_global<ProductAccount<BaseCoin>>(@satay_product);
        let base_coin_amount = coin::value(&base_coins);
        coin::deposit(account::get_signer_capability_address(&product_account.signer_cap), base_coins);
        coin::mint(base_coin_amount, &product_account.mint_cap)
    }

    /// convert product coins to base coins
    /// @param product_coins - the product coins to convert
    public fun liquidate<BaseCoin>(product_coins: Coin<ProductCoin<BaseCoin>>): Coin<BaseCoin>
    acquires ProductAccount {
        let product_account = borrow_global<ProductAccount<BaseCoin>>(@satay_product);
        let product_signer = account::create_signer_with_capability(&product_account.signer_cap);
        let product_coin_amount = coin::value(&product_coins);
        coin::burn(product_coins, &product_account.burn_cap);
        coin::withdraw<BaseCoin>(&product_signer, product_coin_amount)
    }

    /// collect rewards and convert to product coins
    /// @param user - must hold some amount of ProductCoin<BaseCoin>
    public fun tend<BaseCoin>(
        _user: &signer,
    ): Coin<ProductCoin<BaseCoin>> {
        coin::zero()
    }

    // admin

    /// set the manager address
    /// @param manager - the transaction signer; must be the current manager
    /// @param new_manager - the new manager address
    public entry fun set_manager<BaseCoin>(
        manager: &signer,
        new_manager: address
    ) acquires ProductAccount {
        assert_manager<BaseCoin>(manager);
        borrow_global_mut<ProductAccount<BaseCoin>>(signer::address_of(manager)).manager_address = new_manager;
    }

    // calculations

    /// calculate the amount of product coins that can be minted for a given amount of base coins
    /// @param base_coins - the amount of base coins to be converted
    public fun calc_base_coin_amount(
        product_coin_amount: u64
    ): u64 {

        product_coin_amount
    }

    /// calculate the amount of base coins that can be liquidated for a given amount of product coins
    /// @param product_coins - the amount of product coins to be converted
    public fun calc_product_coin_amount(
        base_coin_amount: u64
    ): u64 {
        base_coin_amount
    }

    // access control

    /// asserts that the transaction signer is the deployer of the module
    /// @param deployer - must be the deployer of the package
    fun assert_deployer(deployer: &signer) {
        assert!(signer::address_of(deployer) == @satay_product, ERR_NOT_DEPLOYER);
    }

    /// asserts that the transaction signer is the manager of the product
    /// @param manager - must be the manager of the product
    fun assert_manager<BaseCoin>(manager: &signer) acquires ProductAccount {
        let product_account = borrow_global<ProductAccount<BaseCoin>>(@satay_product);
        assert!(signer::address_of(manager) == product_account.manager_address, ERR_NOT_MANAGER);
    }
}
