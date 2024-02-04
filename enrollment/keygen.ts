import { Ed25519Keypair } from "@mysten/sui.js/keypairs/ed25519";
import { fromB64 } from "@mysten/sui.js/utils";
import { toHEX } from '@mysten/sui.js/utils';

let kp = Ed25519Keypair.generate();
console.log(`You've generated a new Sui wallet: ${kp.toSuiAddress()}

[${fromB64(kp.export().privateKey)}]\n

${toHEX(fromB64(kp.export().privateKey))}\n`);

