#[test_only]
module sui_bank::test_bank {
    use sui::transfer;
    use sui::coin::{Self, Coin, mint_for_testing, CoinMetadata};
    use sui::sui::SUI;
    use sui::tx_context::{Self,TxContext};
    use sui::test_scenario::{Self as ts, next_tx, Scenario};
    use sui::test_utils::{assert_eq};

    use sui_bank::bank::{
    Self, init_for_testing, Bank, 
    OwnerCap, Account, Constant
    };

    use sui_bank::helpers::{Self, init_test_helper, helper_deposit, helper_borrow};

    use sui_bank::sui_dollar::{Self, SUI_DOLLAR, CapWrapper, return_init_sui_dollar};

    use sui_bank::lending::{Self};

    use sui_bank::oracle::{Price, new_for_testing};

    use sui_bank::amm::{swap_sui, swap_sui_dollar};

     const ADMIN: address = @0xA;
     const TEST_ADDRESS1: address = @0xB;
     const TEST_ADDRESS2: address = @0xC;
     const TEST_ADDRESS3: address = @0xD;
     const TEST_ADDRESS4: address = @0xE;

    #[test]
    public fun test_deposit() {

        let scenario = init_test_helper();
        let scenario_mut = &mut scenario;

        next_tx(scenario_mut, TEST_ADDRESS1);
        {   
            // set bank share object
            let bank_share = ts::take_shared<Bank>(scenario_mut);
            // create an account for user 
            let account = bank::new_account(ts::ctx(scenario_mut));
            // mint sui for deposit function
            let deposit_sui = mint_for_testing<SUI>(1000, ts::ctx(scenario_mut));

            bank::deposit(&mut bank_share,&mut account, deposit_sui, ts::ctx(scenario_mut));

            // return bank balance 
            let bank_balance = bank::return_bank_balance(&bank_share);
            // return admin balance 
            let admin_balance = bank::return_admin_balance(&bank_share);
            // return account deposit
            let account_deposit = bank::return_account_balance(&account);
            // check bank and admin balance 
            assert_eq(bank_balance, 950);
            assert_eq(admin_balance, 50);
            assert_eq(account_deposit, 950);

            // return share object 
            ts::return_shared(bank_share);
            //transfer the account to the test_address1
            transfer::public_transfer(account, TEST_ADDRESS1);
        };

        next_tx(scenario_mut, TEST_ADDRESS2);
        {   
            // set bank share object
            let bank_share = ts::take_shared<Bank>(scenario_mut);
            // create an account for user 
            let account = bank::new_account(ts::ctx(scenario_mut));
            // mint sui for deposit function
            let deposit_sui = mint_for_testing<SUI>(2000, ts::ctx(scenario_mut));

            bank::deposit(&mut bank_share,&mut account, deposit_sui, ts::ctx(scenario_mut));

            // return bank balance 
            let bank_balance = bank::return_bank_balance(&bank_share);
            // return admin balance 
            let admin_balance = bank::return_admin_balance(&bank_share);
            // return account deposit
            let account_deposit = bank::return_account_balance(&account);
            // check bank and admin balance 
            assert_eq(bank_balance, 2850);
            assert_eq(admin_balance, 150);
            assert_eq(account_deposit, 1900);

            // return share object 
            ts::return_shared(bank_share);
            //transfer the account to the test_address1
            transfer::public_transfer(account, TEST_ADDRESS1);
        };

         next_tx(scenario_mut, TEST_ADDRESS3);
        {   
            // set bank share object
            let bank_share = ts::take_shared<Bank>(scenario_mut);
            // create an account for user 
            let account = bank::new_account(ts::ctx(scenario_mut));
            // mint sui for deposit function
            let deposit_sui = mint_for_testing<SUI>(3000, ts::ctx(scenario_mut));

            bank::deposit(&mut bank_share,&mut account, deposit_sui, ts::ctx(scenario_mut));

            // return bank balance 
            let bank_balance = bank::return_bank_balance(&bank_share);
            // return admin balance 
            let admin_balance = bank::return_admin_balance(&bank_share);
            // return account deposit
            let account_deposit = bank::return_account_balance(&account);
            // check bank and admin balance 
            assert_eq(bank_balance, 5700);
            assert_eq(admin_balance, 300);
            assert_eq(account_deposit, 2850);

            // return share object 
            ts::return_shared(bank_share);
            //transfer the account to the test_address1
            transfer::public_transfer(account, TEST_ADDRESS1);
        };
         ts::end(scenario);
    }

    #[test]
    public fun test_withdraw() {
        let scenario = init_test_helper();
        let scenario_mut = &mut scenario;
        // 3 Account is going to deposit 1000 2000 3000 SUI 
        helper_deposit(scenario_mut, 1000, 2000, 3000);

        next_tx(scenario_mut, TEST_ADDRESS1);
        {   
            // set bank share object 
            let bank_share = ts::take_shared<Bank>(scenario_mut);
            // take account object from sender 
            let account = ts::take_from_sender<Account>(scenario_mut);
            // set withdraw amount 
            let withdraw_amount = 500;
            // call withdraw function 
            let withdraw_sui =  bank::withdraw(&mut bank_share, &mut account, withdraw_amount, ts::ctx(scenario_mut));
            // set account.deposit 
            let account_deposit = bank::return_account_balance(&account);
            // check account deposit is equal to 450
            assert_eq(account_deposit, 450);

            ts::return_to_sender(scenario_mut, account);
            transfer::public_transfer(withdraw_sui, TEST_ADDRESS1);
            ts::return_shared(bank_share);
        };

        next_tx(scenario_mut, TEST_ADDRESS2);
        {   
            // set bank share object 
            let bank_share = ts::take_shared<Bank>(scenario_mut);
            // take account object from sender 
            let account = ts::take_from_sender<Account>(scenario_mut);
            // set withdraw amount 
            let withdraw_amount = 1000;
            // call withdraw function 
            let withdraw_sui =  bank::withdraw(&mut bank_share, &mut account, withdraw_amount, ts::ctx(scenario_mut));
            // set account.deposit 
            let account_deposit = bank::return_account_balance(&account);
            // check account deposit is equal to 900
            assert_eq(account_deposit, 900);

            ts::return_to_sender(scenario_mut, account);
            transfer::public_transfer(withdraw_sui, TEST_ADDRESS1);
            ts::return_shared(bank_share);
        };
      ts::end(scenario);
    }

    // We have 2 assert in withdraw function. At the moment we dont have any loan so we can try only ENotEnoughBalance. We will try EPayYourLoan later 
    #[test]
    #[expected_failure(abort_code = bank::ENotEnoughBalance)]

    public fun test_withdraw_ENotEnoughBalance() {

        let scenario = init_test_helper();
        let scenario_mut = &mut scenario;
        // 3 Account is going to deposit 1000 2000 3000 SUI 
        helper_deposit(scenario_mut, 1000, 2000, 3000);

        next_tx(scenario_mut, TEST_ADDRESS1);
        {
            // set bank share object 
            let bank_share = ts::take_shared<Bank>(scenario_mut);
            // take account object from sender 
            let account = ts::take_from_sender<Account>(scenario_mut);
            // set withdraw amount as 2000. We are expecting failure. 
            let withdraw_amount = 2000;
            // call withdraw function 
            let withdraw_sui =  bank::withdraw(&mut bank_share, &mut account, withdraw_amount, ts::ctx(scenario_mut));
            // set account.deposit 
            let account_deposit = bank::return_account_balance(&account);
            // check account deposit is equal to 900
            assert_eq(account_deposit, 900);

            ts::return_to_sender(scenario_mut, account);
            transfer::public_transfer(withdraw_sui, TEST_ADDRESS1);
            ts::return_shared(bank_share);
        };
        ts::end(scenario);
    }

     #[test]

    public fun test_borrow() {
        let scenario = init_test_helper();
        let scenario_mut = &mut scenario;
        // 3 Account is going to deposit 1000 2000 3000 SUI 
        helper_deposit(scenario_mut, 1000, 2000, 3000);

        next_tx(scenario_mut, TEST_ADDRESS1);
        {
            // take account object from sender 
            let account = ts::take_from_sender<Account>(scenario_mut);
            // take CapWrapper share object 
            let capwrapper_shared = ts::take_shared<CapWrapper>(scenario_mut);
            // set a borrow amount 
            let borrow_amount:u64 = 400;
            // set a constant object
            let constant = ts::take_shared<Constant>(scenario_mut);
            // set a fake price from oracle module 
            let price = new_for_testing(1000, 900, 1000);
            // call borrow function 
            let stabil_coin =  lending::borrow(
                &mut account, &mut capwrapper_shared, &constant, price,  borrow_amount, ts::ctx(scenario_mut));
            // call helper function for set account dept
            let account_dept = bank::return_user_debt(&account);
            // Address1 deposited 1000 sui admin fee was 50. User1 has 950 sui. 
            assert_eq(account_dept, 400);

            transfer::public_transfer(stabil_coin, TEST_ADDRESS1);
            ts::return_to_sender(scenario_mut, account);
            ts::return_shared(capwrapper_shared);
            ts::return_shared(constant);
        };
        // check does user has 380 SUI_DOLLAR
        next_tx(scenario_mut, TEST_ADDRESS1);
        {   
            // take all SUI_DOLLAR From sender 
            let sui_dollar = ts::take_from_sender<Coin<SUI_DOLLAR>>(scenario_mut);
            assert_eq(coin::value(&sui_dollar), 400);

            ts::return_to_sender(scenario_mut, sui_dollar);
        };

        ts::end(scenario);
    }

     #[test]
     #[expected_failure(abort_code = lending::EBorrowAmountIsTooHigh)]

     public fun test_borrow_EBorrowAmountIsTooHigh() {
        let scenario = init_test_helper();
        let scenario_mut = &mut scenario;
        // 3 Account is going to deposit 1000 2000 3000 SUI 
        helper_deposit(scenario_mut, 1000, 2000, 3000);

        next_tx(scenario_mut, TEST_ADDRESS1);
        {
            // take account object from sender 
            let account = ts::take_from_sender<Account>(scenario_mut);
            // take CapWrapper share object 
            let capwrapper_shared = ts::take_shared<CapWrapper>(scenario_mut);
            // set a borrow amount > 380 because we are expecting error. 
            let borrow_amount = 500;
            // set a fake price from oracle module 
            let price = new_for_testing(1000, 900, 1000);
            // set a constant object
            let constant = ts::take_shared<Constant>(scenario_mut);
            // call borrow function 
            let stabil_coin =  lending::borrow(&mut account, &mut capwrapper_shared, &constant, price,  borrow_amount, ts::ctx(scenario_mut));
         
            transfer::public_transfer(stabil_coin, TEST_ADDRESS1);
            ts::return_to_sender(scenario_mut, account);
            ts::return_shared(capwrapper_shared);
            ts::return_shared(constant);
        };
        ts::end(scenario);
     }

       // we are going to check withdraw function first assert EPayYourLoan
     #[test]
     #[expected_failure(abort_code = bank::EPayYourLoan)]

     public fun test_withdraw_EPayYourLoan() {

        let scenario = init_test_helper();
        let scenario_mut = &mut scenario;
        // 3 Account is going to deposit 1000 2000 3000 SUI 
        helper_deposit(scenario_mut, 1000, 2000, 3000);
        // Test_address1 has debt now. 
        helper_borrow(scenario_mut);

        next_tx(scenario_mut, TEST_ADDRESS1);
        {
             // set bank share object 
            let bank_share = ts::take_shared<Bank>(scenario_mut);
            // take account object from sender 
            let account = ts::take_from_sender<Account>(scenario_mut);
            // set withdraw amount as 2000. We are expecting failure. 
            let withdraw_amount = 1;
            // call withdraw function 
            let withdraw_sui =  bank::withdraw(&mut bank_share, &mut account, withdraw_amount, ts::ctx(scenario_mut));

            ts::return_to_sender(scenario_mut, account);
            transfer::public_transfer(withdraw_sui, TEST_ADDRESS1);
            ts::return_shared(bank_share);
        };
      ts::end(scenario);

     }

     #[test]
     public fun test_repay() {

        let scenario = init_test_helper();
        let scenario_mut = &mut scenario;
        // 3 Account is going to deposit 1000 2000 3000 SUI 
        helper_deposit(scenario_mut, 1000, 2000, 3000);
        // Test_address1 has 380 debt now. 
        helper_borrow(scenario_mut);

        next_tx(scenario_mut, TEST_ADDRESS1);
        {
        // take account object from sender 
        let account = ts::take_from_sender<Account>(scenario_mut);
        // take share object 
        let capwrapper_shared = ts::take_shared<CapWrapper>(scenario_mut);
        // set 380 SUI_DOLLAR For repay debt.
        let stabil_coin = mint_for_testing<SUI_DOLLAR>(380, ts::ctx(scenario_mut));

        lending::repay(&mut account, &mut capwrapper_shared, stabil_coin );
        // set account debt 
        let account_debt = bank::return_user_debt(&account);
        // account debt must be 0 now .
        assert_eq(account_debt, 0);

        ts::return_to_sender(scenario_mut, account);
        ts::return_shared(capwrapper_shared);
        };

       ts::end(scenario);
     }

    #[test]
     public fun test_destroy_empty_account() {
        let scenario = init_test_helper();
        let scenario_mut = &mut scenario;
        // 3 Account is going to deposit 1000 2000 3000 SUI 
        helper_deposit(scenario_mut, 1000, 2000, 3000);

        // test address1 has 950. Lets withdraw all of them. 
        next_tx(scenario_mut, TEST_ADDRESS1);
        {   
            // set bank share object 
            let bank_share = ts::take_shared<Bank>(scenario_mut);
            // take account object from sender 
            let account = ts::take_from_sender<Account>(scenario_mut);
            // set withdraw amount 
            let withdraw_amount = 950;
            // call withdraw function 
            let withdraw_sui =  bank::withdraw(&mut bank_share, &mut account, withdraw_amount, ts::ctx(scenario_mut));
            // set account.deposit 
            let account_deposit = bank::return_account_balance(&account);
            // check account deposit is equal to 450
            assert_eq(account_deposit, 0);

            ts::return_to_sender(scenario_mut, account);
            transfer::public_transfer(withdraw_sui, TEST_ADDRESS1);
            ts::return_shared(bank_share);
        };
        next_tx(scenario_mut, TEST_ADDRESS1);
        {
            // test address1 debt is 0 now so we can delete it. 
            let account = ts::take_from_sender<Account>(scenario_mut);
            bank::destroy_empty_account(account);
        };
        ts::end(scenario);
     }

     // we are expecting an failure. EAccountMustBeEmpty
     #[test]
     #[expected_failure(abort_code = bank::EAccountMustBeEmpty)]
     public fun test_destroy_empty_account_AccountMustBeEmpty() {

        let scenario = init_test_helper();
        let scenario_mut = &mut scenario;
        // 3 Account is going to deposit 1000 2000 3000 SUI 
        helper_deposit(scenario_mut, 1000, 2000, 3000);

        next_tx(scenario_mut, TEST_ADDRESS1);
        {
            // test address1 debt is not equal to 0
            let account = ts::take_from_sender<Account>(scenario_mut);
            bank::destroy_empty_account(account);
        };
        ts::end(scenario);
     }

     #[test]
     public fun test_claim() {
        let scenario = init_test_helper();
        let scenario_mut = &mut scenario;
        // 3 Account is going to deposit 1000 2000 3000 SUI 
        helper_deposit(scenario_mut, 1000, 2000, 3000);

        next_tx(scenario_mut, ADMIN);
        {
            // set bank share object 
            let bank_share = ts::take_shared<Bank>(scenario_mut);
            // set admin_cap 
            let admin_cap = ts::take_from_sender<OwnerCap>(scenario_mut);

            let admin_balance_withdraw = bank::claim(&admin_cap, &mut bank_share, ts::ctx(scenario_mut));
            // transfer SUI TO admin address
            transfer::public_transfer(admin_balance_withdraw, ADMIN);

            ts::return_shared(bank_share);
            ts::return_to_sender(scenario_mut, admin_cap);
        };
        next_tx(scenario_mut, ADMIN);
        {
            let admin_balance = ts::take_from_sender<Coin<SUI>>(scenario_mut);
            // admin wallet balance must be 300 SUI.
            assert_eq(coin::value(&admin_balance), 300);

            ts::return_to_sender(scenario_mut, admin_balance);
        };
         ts::end(scenario);
     }

    #[test]
    public fun test_swap() {
        let scenario = init_test_helper();
        let scenario_mut = &mut scenario;
        // 3 Account is going to deposit 1000 2000 3000 SUI 
        helper_deposit(scenario_mut, 1000, 2000, 3000);
         // lets swap sui to SUI_DOLLAR
        next_tx(scenario_mut, TEST_ADDRESS1);
        { 
            // set bank share object 
            let bank_share = ts::take_shared<Bank>(scenario_mut);
            // take CapWrapper share object 
            let capwrapper_shared = ts::take_shared<CapWrapper>(scenario_mut);
            // set sui amount as 300. 
            let swap_sui_amount = mint_for_testing<SUI>(300, ts::ctx(scenario_mut));
            // set a fake price from oracle module 
            let price = new_for_testing(1000, 1000, 1000);

            let swapped_stabil_coin = swap_sui(
                &mut bank_share,
                &mut capwrapper_shared,
                 price, 
                swap_sui_amount,
                ts::ctx(scenario_mut)
                );

            transfer::public_transfer(swapped_stabil_coin, TEST_ADDRESS1);

             ts::return_shared(bank_share);
             ts::return_shared(capwrapper_shared);
            
        };
        // lets check address1 balance 
        next_tx(scenario_mut, TEST_ADDRESS1);
        {
            // take all SUI_DOLLAR from sender 
            let user_sui_dollar_balance = ts::take_from_sender<Coin<SUI_DOLLAR>>(scenario_mut);
            assert_eq(coin::value(&user_sui_dollar_balance), 300);

            ts::return_to_sender(scenario_mut, user_sui_dollar_balance);
        };
        //lets swap SUI_DOLLAR to SUI 
        next_tx(scenario_mut, TEST_ADDRESS1);
        {
            // set bank share object 
            let bank_share = ts::take_shared<Bank>(scenario_mut);
            // take CapWrapper share object 
            let capwrapper_shared = ts::take_shared<CapWrapper>(scenario_mut);
            // set user sui_dollar amount it is equal to 750 
            let user_sui_dollar_balance = ts::take_from_sender<Coin<SUI_DOLLAR>>(scenario_mut);
            // set a fake price from oracle module 
            let price = new_for_testing(1000, 1000, 1000);

            let swapped_sui = swap_sui_dollar(
                &mut bank_share, 
                &mut capwrapper_shared,
                price,
                user_sui_dollar_balance,
                ts::ctx(scenario_mut)
                );

             transfer::public_transfer(swapped_sui, TEST_ADDRESS1);

             ts::return_shared(bank_share);
             ts::return_shared(capwrapper_shared);
        };
         // lets check address1 balance 
        next_tx(scenario_mut, TEST_ADDRESS1);
        {
            // take all SUI from sender 
            let user_sui_dollar_balance = ts::take_from_sender<Coin<SUI>>(scenario_mut);
            assert_eq(coin::value(&user_sui_dollar_balance), 300);

            ts::return_to_sender(scenario_mut, user_sui_dollar_balance);
        };
        
         ts::end(scenario);
     }















}