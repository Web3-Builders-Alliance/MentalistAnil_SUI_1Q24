module sui_bank::bank {
  // === Imports ===

  use sui::sui::SUI;
  use sui::transfer;
  use sui::coin::{Self, Coin};
  use sui::object::{Self, UID};
  use sui::balance::{Self, Balance};
  use sui::tx_context::{Self, TxContext};
  
  // === Friends ===

  friend sui_bank::amm;
  friend sui_bank::lending;

  // === Errors ===

  const ENotEnoughBalance: u64 = 0;
  const EPayYourLoan: u64 = 1;
  const EAccountMustBeEmpty: u64 = 2;

  // === Constants ===

  // const Fee: u128 = 5;

  // === Structs ===

  struct Bank has key {
    id: UID,
    balance: Balance<SUI>,
    admin_balance: Balance<SUI>,
    fee: u128,
  }

  struct Account has key, store {
    id: UID,
    debt: u64,
    balance: u64
  }

  struct Constant has key {
    id: UID,
    ltv: u128
  }

  struct OwnerCap has key{
    id: UID,
  }  

  // === Init ===

  fun init(ctx: &mut TxContext) {
    transfer::share_object(
      Bank {
        id: object::new(ctx),
        balance: balance::zero(),
        admin_balance: balance::zero(),
        fee: 5,
      }
    );

    transfer::transfer(OwnerCap { id: object::new(ctx) }, tx_context::sender(ctx));
    transfer::share_object(Constant {id: object::new(ctx), ltv: 40});
  }  

  // === Public-Mutative Functions ===

  public fun new_account(ctx: &mut TxContext): Account {
    Account {
      id: object::new(ctx),
      debt: 0,
      balance: 0
    }
  }  

  public fun deposit(self: &mut Bank, account: &mut Account, token: Coin<SUI>, ctx: &mut TxContext) {
    let value = coin::value(&token);
    let deposit_value = value - (((value as u128) * self.fee / 100) as u64);
    let admin_fee = value - deposit_value;

    let admin_coin = coin::split(&mut token, admin_fee, ctx);
    balance::join(&mut self.admin_balance, coin::into_balance(admin_coin));
    balance::join(&mut self.balance, coin::into_balance(token));

    account.balance = account.balance + deposit_value;
  }  

  public fun withdraw(self: &mut Bank, account: &mut Account, value: u64, ctx: &mut TxContext): Coin<SUI> {
    assert!(account.debt == 0, EPayYourLoan);
    assert!(account.balance >= value, ENotEnoughBalance);

    account.balance = account.balance - value;

    coin::from_balance(balance::split(&mut self.balance, value), ctx)
  }  

  public fun destroy_empty_account(account: Account) {
    let Account { id, debt: _, balance} = account;
    assert!(balance == 0, EAccountMustBeEmpty);
    object::delete(id);
  }    

  // === Public-View Functions ===

  public fun return_bank_balance(self: &Bank): u64 {
    balance::value(&self.balance)
  }

  public fun return_admin_balance(self: &Bank): u64 {
    balance::value(&self.admin_balance)
  }

  public fun return_user_debt(account: &Account): u64 {
    account.debt
  } 

  public fun return_account_balance(account: &Account): u64 {
    account.balance
  }

  public fun constant_ltv(constant: &Constant) : u128 {
    constant.ltv
  }

  public fun set_admin_fee(_: &OwnerCap, bank: &mut Bank, value: u128) {
    bank.fee = value;
  }

  public fun set_ltv_fee(_: &OwnerCap, constant: &mut Constant, value: u128) {
    constant.ltv = value;
  }

  // calculate admin fee that as much as the money deposited by users
  // public fun admin_fee(account: &Account) : u128 {
  //   let account_balance = account.balance;
  //   let admin_fee: u128 = 5;

  //   if(account_balance > 10000 && account_balance <= 100000) {
  //       admin_fee = 2;
  //   }
  //   else if( account_balance > 100000) {
  //       admin_fee = 1;
  //   };
  //       admin_fee

  // }   

  // === Admin Functions ===

  public fun claim(_: &OwnerCap, self: &mut Bank, ctx: &mut TxContext): Coin<SUI> {
    let value = balance::value(&self.admin_balance);
    coin::take(&mut self.admin_balance, value, ctx)
  }      

  // === Public-Friend Functions ===
  
  public(friend) fun balance_mut(self: &mut Bank): &mut Balance<SUI> {
    &mut self.balance
  }

  public(friend) fun admin_balance_mut(self: &mut Bank): &mut Balance<SUI> {
    &mut self.admin_balance
  }

  public(friend) fun debt_mut(acc: &mut Account): &mut u64 {
    &mut acc.debt
  }  

  public(friend) fun account_balance_mut(acc: &mut Account): &mut u64 {
    &mut acc.balance
  }    

  // === Test Functions ===

  #[test_only]
  public fun init_for_testing(ctx: &mut TxContext) {
    init(ctx);
  }
}