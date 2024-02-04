#[test_only]
module sui_bank::helpers {
 
    use sui::transfer;
    use sui::object::{Self,UID,ID};
    use sui::coin::{Self, Coin, CoinMetadata, mint_for_testing};
    use sui::sui::SUI;
    use sui::tx_context::{Self,TxContext};
    use sui::balance:: {Self, Balance};

    use sui::test_scenario::{Self as ts, next_tx, Scenario};
    use sui::test_utils::{assert_eq};

    use sui_bank::bank::{Self, Bank, Account, Constant, new_account, init_for_testing,  return_user_debt};
    use sui_bank::sui_dollar::{Self, SUI_DOLLAR, CapWrapper, return_init_sui_dollar};

    use sui_bank::lending:: {borrow, repay}; 

    use sui_bank::oracle:: {Price, new_for_testing};

     const ADMIN: address = @0xA;
     const TEST_ADDRESS1: address = @0xB;
     const TEST_ADDRESS2: address = @0xC;
     const TEST_ADDRESS3: address = @0xD;
     const TEST_ADDRESS4: address = @0xE;


    public fun helper_deposit(scenario: &mut Scenario, amount1:u64, amount2:u64, amount3:u64) {

        // let test_address2 deposit amount1 SUI
       next_tx(scenario, TEST_ADDRESS1);
        {
        let bank_share = ts::take_shared<Bank>(scenario);
        let deposit_sui = mint_for_testing<SUI>(amount1, ts::ctx(scenario));
        let account = new_account(ts::ctx(scenario));
        
        bank::deposit(&mut bank_share, &mut account,  deposit_sui, ts::ctx(scenario));

        ts::return_shared(bank_share);
        transfer::public_transfer(account, TEST_ADDRESS1);

        };

        // let test_address2 deposit amount2 SUI
        next_tx(scenario, TEST_ADDRESS2);
        {
        let bank_share = ts::take_shared<Bank>(scenario);
        let deposit_sui = mint_for_testing<SUI>(amount2, ts::ctx(scenario));
        let account = new_account(ts::ctx(scenario));
        
        bank::deposit(&mut bank_share, &mut account,  deposit_sui, ts::ctx(scenario));

        ts::return_shared(bank_share);
        transfer::public_transfer(account, TEST_ADDRESS2);
        };

        // let test_address3 deposit amount3 SUI
        next_tx(scenario, TEST_ADDRESS3);
        {
        let bank_share = ts::take_shared<Bank>(scenario);
        let deposit_sui = mint_for_testing<SUI>(amount3, ts::ctx(scenario));
           let account = new_account(ts::ctx(scenario));
        
       bank::deposit(&mut bank_share, &mut account,  deposit_sui, ts::ctx(scenario));

        ts::return_shared(bank_share);
        transfer::public_transfer(account, TEST_ADDRESS3);
        };

    }

    public fun helper_borrow(scenario_mut: &mut Scenario) {
        next_tx(scenario_mut, TEST_ADDRESS1);
        {
            // take account object from sender 
            let account = ts::take_from_sender<Account>(scenario_mut);
            // take CapWrapper share object 
            let capwrapper_shared = ts::take_shared<CapWrapper>(scenario_mut);
            // set a borrow amount 
            let borrow_amount = 380;
            // call borrow function 
            let constant = ts::take_shared<Constant>(scenario_mut);
            // set a fake price from oracle module 
            let price = new_for_testing(1000, 900, 1000);
            // call borrow function 
            let stabil_coin =  borrow(
                &mut account, &mut capwrapper_shared, &constant, price,  borrow_amount, ts::ctx(scenario_mut));
            // call helper function for set account dept
            let account_dept = return_user_debt(&account);
            // Address1 deposited 1000 sui admin fee was 950. so 950 x (40 / 100) = 380
            assert_eq(account_dept, 380);

            transfer::public_transfer(stabil_coin, TEST_ADDRESS1);
            ts::return_to_sender(scenario_mut, account);
            ts::return_shared(capwrapper_shared);
            ts::return_shared(constant);
        };
    }

    public fun init_test_helper() : ts::Scenario{

       let owner: address = @0xA;
       let scenario_val = ts::begin(owner);
       let scenario = &mut scenario_val;
 
       {
           init_for_testing(ts::ctx(scenario));
       };

       {
          return_init_sui_dollar(ts::ctx(scenario));
       };
       scenario_val
}

}