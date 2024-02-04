module bank::bank {
    use std::string::{Self,String};
    use std::vector;
    use std::debug;

    use sui::transfer;
    use sui::object::{Self,UID,ID};
    use sui::url::{Self,Url};
    use sui::coin::{Self, Coin, CoinMetadata};
    use sui::sui::SUI;
    use sui::object_table::{Self,ObjectTable};
    use sui::event;
    use sui::tx_context::{Self,TxContext};
    use sui::vec_set::{Self, VecSet};
    use sui::table::{Self, Table};
    use sui::balance:: {Self, Balance};
    use sui::bag::{Self,Bag};
    use sui::dynamic_field::{Self};

    struct Bank has key {
        id: UID,
    }

    struct OwnerCap has key, store {
        id: UID
    }
    
    struct UserBalance has copy, drop, store {
        user: address 
    }
    
    struct AdminBalance has copy, drop, store {}
    
    const FEE: u128 = 5;
    

   fun init(ctx: &mut TxContext) {
      let bank = Bank {
        id:object::new(ctx),
      };
      dynamic_field::add(&mut bank.id, AdminBalance{}, balance::zero<SUI>());

      transfer::share_object(bank);

      transfer::transfer(OwnerCap
    { id: object::new(ctx)}, tx_context::sender(ctx) );

    } 

    public fun deposit(self: &mut Bank, token: Coin<SUI>, ctx: &mut TxContext) {
        let value = coin::value(&token);
        let deposit_value = value - (((value as u128) * FEE / 100) as u64);
        let admin_fee = value - deposit_value;
        let token_balance = coin::into_balance(token);
        let split_admin_fee = balance::split(&mut token_balance, admin_fee );

        check_deposit(self, token_balance, ctx);

        let admin_balance = dynamic_field::borrow_mut<AdminBalance, Balance<SUI>>(&mut self.id, AdminBalance{});
        balance::join(admin_balance, split_admin_fee);

    } 

    public fun withdraw(self: &mut Bank, ctx: &mut TxContext) : Coin<SUI> {
        let sender = tx_context::sender(ctx);

        let withdraw_balance = dynamic_field::remove<UserBalance, Balance<SUI>>(&mut self.id, UserBalance{user: sender});

        let return_coin = coin::from_balance<SUI>( withdraw_balance, ctx);

        return_coin

       // transfer::public_transfer(return_coin, sender);
    }

    public fun claim(_: &OwnerCap, self: &mut Bank, ctx: &mut TxContext) {
        let fee_balance = balance::withdraw_all(
            dynamic_field::borrow_mut<AdminBalance, Balance<SUI>>(
                &mut self.id,
                AdminBalance { },
            ));
       let withdraw_coin =  coin::from_balance(fee_balance, ctx);

       transfer::public_transfer(withdraw_coin, tx_context::sender(ctx));
    }

    public fun balance(self: &Bank, user: address): u64 {
        let user_balance = dynamic_field::borrow<UserBalance, Balance<SUI>>(& self.id, UserBalance{user: user});
        balance::value(user_balance)   
    }

    public fun balance_admin(self: &Bank): u64 {
        let user_balance = dynamic_field::borrow<AdminBalance, Balance<SUI>>(& self.id, AdminBalance{});
        balance::value(user_balance)   
    }

    public fun check_deposit(self: &mut Bank, token: Balance<SUI>, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        if (dynamic_field::exists_(&self.id, UserBalance { user: sender })) {
        
          balance::join(dynamic_field::borrow_mut<UserBalance, Balance<SUI>>(&mut self.id, UserBalance { user: sender }), token);
      
        } else {
            dynamic_field::add(&mut self.id, UserBalance { user: sender }, token);
        };

    }

    #[test_only]

    public fun return_init(ctx: &mut TxContext) {
        init(ctx);
    }
}