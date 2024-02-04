// #[test_only]
// module bank::bank_test {
//     use std::string::{Self,String};
//     use std::vector;
//     use std::debug;

//     use sui::transfer;
//     use sui::object::{Self,UID,ID};
//     use sui::url::{Self,Url};
//     use sui::coin::{Self, Coin, mint_for_testing, CoinMetadata};
//     use sui::sui::SUI;
//     use sui::object_table::{Self,ObjectTable};
//     use sui::event;
//     use sui::tx_context::{Self,TxContext};
//     use sui::vec_set::{Self, VecSet};
//     use sui::table::{Self, Table};
//     use sui::balance:: {Self, Balance};
//     use sui::bag::{Self,Bag};
//     use sui::dynamic_field::{Self};

//     use sui::test_scenario::{Self as ts, next_tx, Scenario};
//     use sui::test_utils::{assert_eq};

//     use bank::bank::{Self, return_init, Bank, OwnerCap};
//     use bank::helpers::{Self, helper_deposit, init_test_helper};


//     #[test]

//     public fun users_deposit() {
//         let owner: address = @0xA;
//         let test_address1: address = @0xB;
//         let test_address2: address = @0xC;
//         let test_address3: address = @0xD;
//         let test_address4: address = @0xE;

//         let scenario_test = init_test_helper();
//         let scenario = &mut scenario_test;

//         // let test_address1 deposit 1000 SUI
//         next_tx(scenario, test_address1);
//         {
//             let bank_share = ts::take_shared<Bank>(scenario);
//             let deposit_sui = mint_for_testing<SUI>(1000, ts::ctx(scenario));
            
//             bank::deposit(&mut bank_share, deposit_sui, ts::ctx(scenario));
    
//             ts::return_shared(bank_share);

//         };

//         // let test_address2 deposit 2000 SUI
//         next_tx(scenario, test_address2);
//         {
//             let bank_share = ts::take_shared<Bank>(scenario);
//             let deposit_sui = mint_for_testing<SUI>(2000, ts::ctx(scenario));

//             bank::deposit(&mut bank_share, deposit_sui, ts::ctx(scenario));

//             ts::return_shared(bank_share);
//         };

//         // let test_address3 deposit 3000 SUI
//         next_tx(scenario, test_address3);
//         {
//             let bank_share = ts::take_shared<Bank>(scenario);
//             let deposit_sui = mint_for_testing<SUI>(3000, ts::ctx(scenario));

//             bank::deposit(&mut bank_share, deposit_sui, ts::ctx(scenario));

//             ts::return_shared(bank_share);
//         };

//         // now lets check theirs balance. Fee is %5.
//         next_tx(scenario, test_address1);
//         {
//             let bank_share = ts::take_shared<Bank>(scenario);

//             let result = bank::balance(&bank_share, test_address1);
//             // fee is 50 so result must be equal to 950
//             assert_eq(result, 950);

//             ts::return_shared(bank_share);
//         };

//         next_tx(scenario, test_address2);
//         {
//             let bank_share = ts::take_shared<Bank>(scenario);

//             let result = bank::balance(&bank_share, test_address2);
//             // fee is 50 so result must be equal to 1900
//             assert_eq(result, 1900);

//             ts::return_shared(bank_share);
//         };

//         next_tx(scenario, test_address3);
//         {
//             let bank_share = ts::take_shared<Bank>(scenario);

//             let result = bank::balance(&bank_share, test_address3);
//             // fee is 50 so result must be equal to 2850
//             assert_eq(result, 2850);

//             ts::return_shared(bank_share);
//         };

//         // lets check admin balance now 
//         next_tx(scenario, owner);
//         {
//             let bank_share = ts::take_shared<Bank>(scenario);

//             let result = bank::balance_admin(&bank_share);
//             // fee is 50 + 100 + 150 = 300
//             assert_eq(result, 300);

//             ts::return_shared(bank_share);
//         };

//         ts::end(scenario_test);
//     }

//    #[test]
//     public fun withdraw() {
//         let owner: address = @0xA;
//         let test_address1: address = @0xB;
//         let test_address2: address = @0xC;
//         let test_address3: address = @0xD;
//         let test_address4: address = @0xE;

//         let scenario_test = init_test_helper();
//         let scenario = &mut scenario_test;

//         helper_deposit(scenario, 1000, 2000, 3000);
        
//         // lets check test_address1 withdraw is equal to 950 
//         next_tx(scenario, test_address1);
//         {
//             let bank_share = ts::take_shared<Bank>(scenario);

//             let withdraw_amount = bank::withdraw(&mut bank_share, ts::ctx(scenario));

//             transfer::public_transfer(withdraw_amount,  test_address1);

//             ts::return_shared(bank_share);
//         };

//         // lets check test_address2 withdraw is equal to 1900 
//         next_tx(scenario, test_address2);
//         {
//             let bank_share = ts::take_shared<Bank>(scenario);

//             let withdraw_amount = bank::withdraw(&mut bank_share, ts::ctx(scenario));

//             transfer::public_transfer(withdraw_amount,  test_address2);

//             ts::return_shared(bank_share);
//         };

//         // lets check test_address1 withdraw is equal to 2850
//         next_tx(scenario, test_address3);
//         {
//             let bank_share = ts::take_shared<Bank>(scenario);

//             let withdraw_amount = bank::withdraw(&mut bank_share, ts::ctx(scenario));

//             transfer::public_transfer(withdraw_amount,  test_address3);

//             ts::return_shared(bank_share);
//         };

//         //lets check test_address1 balance 
//         next_tx(scenario, test_address1);
//         {
//           let current_balance = ts::take_from_sender<Coin<SUI>>(scenario);  
//           assert_eq(coin::value(&current_balance), 950);   

//           ts::return_to_sender(scenario, current_balance);
//         };

//         //lets check test_address2 balance 
//         next_tx(scenario, test_address2);
//         {
//           let current_balance = ts::take_from_sender<Coin<SUI>>(scenario);  
//           assert_eq(coin::value(&current_balance), 1900);   

//           ts::return_to_sender(scenario, current_balance);
//         };

//         //lets check test_address3 balance 
//         next_tx(scenario, test_address3);
//         {
//           let current_balance = ts::take_from_sender<Coin<SUI>>(scenario);  
//           assert_eq(coin::value(&current_balance), 2850);   

//           ts::return_to_sender(scenario, current_balance);
//         };
//            ts::end(scenario_test);
//     }

//     #[test]

//         public fun claim() {
//         let owner: address = @0xA;
//         let test_address1: address = @0xB;
//         let test_address2: address = @0xC;
//         let test_address3: address = @0xD;
//         let test_address4: address = @0xE;

//         let scenario_test = init_test_helper();
//         let scenario = &mut scenario_test;

//         helper_deposit(scenario, 1000, 2000, 3000);

//         //admin withdraw his balance 
//         next_tx(scenario, owner);
//         {
//             let admin_cap = ts::take_from_sender<OwnerCap>(scenario);
//             let bank_share = ts::take_shared<Bank>(scenario);

//             bank::claim(&admin_cap, &mut bank_share, ts::ctx(scenario));

//             ts::return_to_sender(scenario, admin_cap);
//             ts::return_shared(bank_share);
//         };
//         // lets check admin balance now.
//         next_tx(scenario, owner);
//         {
//             let admin_balance = ts::take_from_sender<Coin<SUI>>(scenario);

//             assert_eq(coin::value(&admin_balance), 300);

//             ts::return_to_sender(scenario, admin_balance);
//         };

//          ts::end(scenario_test);

//         }

//     #[test]
//     #[expected_failure(abort_code = 0000000000000000000000000000000000000000000000000000000000000002::test_scenario::EEmptyInventory)]
//     // test_address1 going to call claim function. So we are expecting error.
//      public fun user1_claim() {
//         let owner: address = @0xA;
//         let test_address1: address = @0xB;

//         let scenario_test = init_test_helper();
//         let scenario = &mut scenario_test;

      
//         helper_deposit(scenario, 1000, 2000, 3000);

//         //admin withdraw his balance 
//         next_tx(scenario, test_address1);
//         {
//             let admin_cap = ts::take_from_sender<OwnerCap>(scenario);
//             let bank_share = ts::take_shared<Bank>(scenario);  

//             bank::claim(&admin_cap, &mut bank_share, ts::ctx(scenario));  

//             ts::return_to_sender(scenario, admin_cap);
//             ts::return_shared(bank_share);
//         };

//           ts::end(scenario_test);

//      }

// }