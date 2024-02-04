import { getFullnodeUrl, SuiClient } from "@mysten/sui.js/client";
import { Ed25519Keypair } from "@mysten/sui.js/keypairs/ed25519";
import { TransactionBlock } from '@mysten/sui.js/transactions';

import wallet from "./dev-wallet.json"

// Import our dev wallet keypair from the wallet file
const keypair = Ed25519Keypair.fromSecretKey(new Uint8Array(wallet as any));

const to = "0x5fb75c1761c43acfd30b99443d4307101f57391cb1a4b7eb5d795fd91a8aa87a";

const client = new SuiClient({ url: getFullnodeUrl("testnet")});

(async () => {
    try {
        //create Transaction Block.
        const txb = new TransactionBlock();
        //Split coins
        let [coin] = txb.splitCoins(txb.gas, [1000]);
        //Add a transferObject transaction
        txb.transferObjects([coin, txb.gas], to);
        let txid = await client.signAndExecuteTransactionBlock({ signer: keypair, transactionBlock: txb });
        console.log(`Success! Check our your TX here:
        https://suiexplorer.com/txblock/${txid.digest}?network=testnet`);
    } catch(e) {
        console.error(`Oops, something went wrong: ${e}`)
    }
})();

(async () => {
    try {
        //create Transaction Block.
        const txb = new TransactionBlock();
        //Add a transferObject transaction
        txb.transferObjects([txb.gas], to);
        let txid = await client.signAndExecuteTransactionBlock({ signer: keypair, transactionBlock: txb });
        console.log(`Success! Check our your TX here:
        https://suiexplorer.com/txblock/${txid.digest}?network=testnet`);
    } catch(e) {
        console.error(`Oops, something went wrong: ${e}`)
    }
})();



