import { getFullnodeUrl, SuiClient } from "@mysten/sui.js/client";
import { Ed25519Keypair } from "@mysten/sui.js/keypairs/ed25519";
import { bcs} from "@mysten/sui.js/bcs";
import { TransactionBlock } from '@mysten/sui.js/transactions';
import { fromHEX } from "@mysten/bcs";
// import wallet from "/wba-wallet.json"

const enrollment_object_id = "0x5927f2574f0a5e2afa574e24bca462269d31cf29bdd2215d908b90b691ea5747";
const cohort = "0xa85910892fca1bedde91ec6a1379bcf71f4106adbe390ccd67fb696c802d99ab";

const keypair = Ed25519Keypair.fromSecretKey(fromHEX("0x6a159de8562921a7363afa2d31ff43eaaf782d7cb9ef0184facdf8358306c8e9"));

// Create a devnet client
const client = new SuiClient({ url: getFullnodeUrl("testnet") });

const txb = new TransactionBlock();

const github = new Uint8Array(Buffer.from("MentalistTR"));
let serialized_github = txb.pure(bcs.vector(bcs.u8()).serialize(github));

 txb.moveCall({
    target: `${enrollment_object_id}::enrollment::enroll`,
    arguments: [txb.object(cohort), serialized_github],
});

const main = async  () => {
    let txid = await client.signAndExecuteTransactionBlock({ signer: keypair, transactionBlock: txb });
    console.log(`Success! Check our your TX here:
    https://suiexplorer.com/txblock/${txid.digest}?network=testnet`);
}

main();
