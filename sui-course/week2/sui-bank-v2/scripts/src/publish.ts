import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, keyPair, parse_amount, find_one_by_type } from './helpers.js';
import path, { dirname } from "path";
import { fileURLToPath } from "url";
import { writeFileSync } from "fs";


const { execSync } = require('child_process');
const keypair =  keyPair();

const path_to_scripts = dirname(fileURLToPath(import.meta.url))

const path_to_contracts = path.join(path_to_scripts, "../../package/sources")

console.log("Building move code...")

const { modules, dependencies } = JSON.parse(execSync(
    `tsui move build --dump-bytecode-as-base64 --path ${path_to_contracts}`,
    { encoding: "utf-8" }
))

console.log("Deploying contracts...");
console.log(`Deploying from ${keypair.toSuiAddress()}`)

const tx = new TransactionBlock();

const [upgradeCap] = tx.publish({
	modules,
	dependencies,
});

tx.transferObjects([upgradeCap], keypair.getPublicKey().toSuiAddress());

const { objectChanges, balanceChanges } = await client.signAndExecuteTransactionBlock({
    signer: keypair, transactionBlock: tx, options: {
        showBalanceChanges: true,
        showEffects: true,
        showEvents: true,
        showInput: false,
        showObjectChanges: true,
        showRawInput: false
    }
})

if (!balanceChanges) {
    console.log("Error: Balance Changes was undefined")
    process.exit(1)
}
if (!objectChanges) {
    console.log("Error: object  Changes was undefined")
    process.exit(1)
}

console.log(objectChanges)
console.log(`Spent ${Math.abs(parse_amount(balanceChanges[0].amount))} on deploy`);

const published_change = objectChanges.find(change => change.type == "published")
if (published_change?.type !== "published") {
    console.log("Error: Did not find correct published change")
    process.exit(1)
}

// get package id and shareobject in json format 

// get package_id
const package_id = published_change.packageId

export const deployed_address: any = {
    packageId: published_change.packageId,

    bank:{
        Bank:"",
        OwnerCap: "",
        Constant:""
    },
    
    sui_dollar:{
        SUID_cointype:`${package_id}::sui_dollar::SUI_DOLLAR`,
        Capwrapper:""
    },
    aggregator_testnet: {
        aggregator: "0x84d2b7e435d6e6a5b137bf6f78f34b2c5515ae61cd8591d5ff6cd121a21aa6b7"
    },
    oracle_aggregator_share: {
        aggregators_local:""
    },
    Bank_Accounts: {
        owner_account : ""
    },
    Price_Object: {
        price_id: ""
    }
}

// Get Bank Share object 
const bank = `${deployed_address.packageId}::bank::Bank`

const bank_id = find_one_by_type(objectChanges, bank)
if (!bank_id) {
    console.log("Error: Could not find Fund_balances object")
    process.exit(1)
}

deployed_address.bank.Bank=  bank_id;

// Get AdminCap
const OwnerCap = `${deployed_address.packageId}::bank::OwnerCap`

const admin_cap_id = find_one_by_type(objectChanges, OwnerCap)
if (!admin_cap_id) {
    console.log("Error: Could not find Admin object ")
    process.exit(1)
}

deployed_address.bank.OwnerCap = admin_cap_id;

// Get CapWrapper
const Capwrapper = `${deployed_address.packageId}::sui_dollar::CapWrapper`

const capwrapper = find_one_by_type(objectChanges, Capwrapper)
if (!capwrapper) {
    console.log("Error: Could not find Admin object ")
    process.exit(1)
}

deployed_address.sui_dollar.Capwrapper = capwrapper;

// Get Local Aggregator share object 
const AggregatorLocal = `${deployed_address.packageId}::oracle::Aggregators`

const aggregators = find_one_by_type(objectChanges, AggregatorLocal)
if (!aggregators) {
    console.log("Error: Could not find Admin object ")
    process.exit(1)
}

deployed_address.oracle_aggregator_share.aggregators_local = aggregators;

// Get Constant  share object 
const Constant = `${deployed_address.packageId}::bank::Constant`

const constant = find_one_by_type(objectChanges, Constant)
if (!constant) {
    console.log("Error: Could not find Admin object ")
    process.exit(1)
}

deployed_address.bank.Constant = constant;

writeFileSync(path.join(path_to_scripts, "../deployed_objects.json"), JSON.stringify(deployed_address, null, 4))
