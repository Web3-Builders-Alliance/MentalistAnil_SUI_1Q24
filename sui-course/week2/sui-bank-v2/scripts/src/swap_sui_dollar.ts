import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, keyPair, getId, MergeCoin } from './helpers.js';
import { CoinBalance, PaginatedObjectsResponse, SuiObjectResponse } from '@mysten/sui.js/client';
import {SUI_CLOCK_OBJECT_ID} from '@mysten/sui.js/utils';
import data from '../deployed_objects.json';

// This PTB creates an account if the user doesn't have one and deposit the required amount into the bank

let keypair = keyPair();
const packageId = data.packageId;
const bank = data.bank.Bank;
const capwrapper = data.sui_dollar.Capwrapper;
const oracle_aggregator = data.aggregator_testnet.aggregator;
const OracleShareAggregators = data.oracle_aggregator_share.aggregators_local;
const Constant = data.bank.Constant;
const ownercap = data.bank.OwnerCap;
const sender = "0xa30ec094bfd69fec2b264d45a4bc7cd546f331b0e4575b1fa95112c14281f439";
const cointype = data.sui_dollar.SUID_cointype;
const account = data.Bank_Accounts.owner_account;


const txb = new TransactionBlock

// add aggregator to whitelist
 txb.moveCall({
    target: `${packageId}::oracle::add_to_whitelist`,
    arguments: [
        txb.object(ownercap),
        txb.object(oracle_aggregator),
        txb.object(OracleShareAggregators),
    ],
    });

// get the Price hot potato
const [price] = txb.moveCall({
    target: `${packageId}::oracle::new`,
    arguments: [
        txb.object(oracle_aggregator),
        txb.object(OracleShareAggregators),
        txb.object(SUI_CLOCK_OBJECT_ID)
    ],
    });
   
console.log("user swap sui_dollar...")

const repay_amount = await MergeCoin(txb, "147", client, sender);
    
const [withdrawSUI] = txb.moveCall({
    target: `${packageId}::amm::swap_sui_dollar`,
    arguments: [
        txb.object(bank),
        txb.object(capwrapper),
        price,
        repay_amount 
    ]
});

txb.transferObjects([withdrawSUI], keypair.getPublicKey().toSuiAddress());

const {objectChanges}= await client.signAndExecuteTransactionBlock({
    signer: keypair,
    transactionBlock: txb,
    options: {
    showBalanceChanges: true,
    showEffects: true,
    showEvents: true,
    showInput: false,
    showObjectChanges: true,
    showRawInput: false
},
   
})

if (!objectChanges) {
    console.log("Error: object  Changes was undefined")
    process.exit(1)
}

console.log(objectChanges);




