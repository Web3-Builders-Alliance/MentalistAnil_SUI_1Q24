// module bank::helpers {
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

//     use bank::bank::{Self, return_init, Bank};


//     public fun helper_deposit(scenario: &mut Scenario, amount1:u64, amount2:u64, amount3:u64) {

//         let owner: address = @0xA;
//         let test_address1: address = @0xB;
//         let test_address2: address = @0xC;
//         let test_address3: address = @0xD;
//         let test_address4: address = @0xE;


//         // let test_address2 deposit amount1 SUI
//        next_tx(scenario, test_address1);
//         {
//         let bank_share = ts::take_shared<Bank>(scenario);
//         let deposit_sui = mint_for_testing<SUI>(amount1, ts::ctx(scenario));
        
//         bank::deposit(&mut bank_share, deposit_sui, ts::ctx(scenario));

//         ts::return_shared(bank_share);

//         };

//         // let test_address2 deposit amount2 SUI
//         next_tx(scenario, test_address2);
//         {
//         let bank_share = ts::take_shared<Bank>(scenario);
//         let deposit_sui = mint_for_testing<SUI>(amount2, ts::ctx(scenario));
        
//         bank::deposit(&mut bank_share, deposit_sui, ts::ctx(scenario));

//         ts::return_shared(bank_share);
//         };

//         // let test_address3 deposit amount3 SUI
//         next_tx(scenario, test_address3);
//         {
//         let bank_share = ts::take_shared<Bank>(scenario);
//         let deposit_sui = mint_for_testing<SUI>(amount3, ts::ctx(scenario));
        
//         bank::deposit(&mut bank_share, deposit_sui, ts::ctx(scenario));

//         ts::return_shared(bank_share);
//         };

//     }

//     public fun init_test_helper() : ts::Scenario{

//        let owner: address = @0xA;
//        let scenario_val = ts::begin(owner);
//        let scenario = &mut scenario_val;
//        {
//            return_init(ts::ctx(scenario));
//        };
//        scenario_val
// }

























// }