import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, keyPair, getId, find_one_by_type } from './helpers.js';
import { CoinBalance, PaginatedObjectsResponse, SuiObjectResponse } from '@mysten/sui.js/client';
import {SUI_CLOCK_OBJECT_ID} from '@mysten/sui.js/utils';
import data from '../deployed_objects.json';
import path from 'path';
import fs from 'fs';

// This PTB creates an account if the user doesn't have one and deposit the required amount into the bank

let keypair = keyPair();
export const package_id = data.packageId;
const bank = data.bank.Bank;
const capwrapper = data.sui_dollar.Capwrapper;
const oracle_aggregator = data.aggregator_testnet.aggregator;
const OracleShareAggregators = data.oracle_aggregator_share.aggregators_local;
const Constant = data.bank.Constant;
const ownercap = data.bank.OwnerCap;


	const getAccountForAddress = async (addr: string): Promise<string | undefined> => {
		let hasNextPage = true;
		let nextCursor = null;
		let account = undefined;
		
		while (hasNextPage) {
			const objects: PaginatedObjectsResponse = await client.getOwnedObjects({
			owner: addr,
			cursor: nextCursor,
			options: { showType: true },
			});

			account = objects.data?.find((obj: SuiObjectResponse) => obj.data?.type === `${package_id}::bank::Account`);
			hasNextPage = objects.hasNextPage;
			nextCursor = objects.nextCursor;

			if (account !== undefined) break;
		}

		return account?.data?.objectId;
	};

	const getSuiDollarBalance = async (): Promise<CoinBalance> => {
		return await client.getBalance({
			owner: keypair.getPublicKey().toSuiAddress(),
			coinType: `${package_id}::sui_dollar::SUI_DOLLAR`,
		});
	}

		const accountId = await getAccountForAddress(keypair.getPublicKey().toSuiAddress());

		const tx = new TransactionBlock();

		let account = undefined;
        if (accountId) {
            account = tx.object(accountId);
        }
		// get the coin to deposit
		const [coin] = tx.splitCoins(tx.gas, [tx.pure(1000)]);
      
		// if the user has no account, we create one
		if (accountId === undefined) {
			[account] = tx.moveCall({
				target: `${package_id}::bank::new_account`,
				arguments: [],
			});
		}
		// deposit SUI to bank object
		tx.moveCall({
			target: `${package_id}::bank::deposit`,
			arguments: [
				tx.object(bank),
				account,
				coin,
			],
		});
		// add aggregator to whitelist
		tx.moveCall({
			target: `${package_id}::oracle::add_to_whitelist`,
			arguments: [
				tx.object(ownercap),
				tx.object(oracle_aggregator),
				tx.object(OracleShareAggregators),
			],
		});
	
		// get the Price hot potato
		const [price] = tx.moveCall({
			target: `${package_id}::oracle::new`,
			arguments: [
				tx.object(oracle_aggregator),
				tx.object(OracleShareAggregators),
				tx.object(SUI_CLOCK_OBJECT_ID)
			],
		});

		console.log(price)
		
		const [sui_dollar] = tx.moveCall({
			target: `${package_id}::lending::borrow`,
			arguments: [
				account,
				tx.object(capwrapper),
				tx.object(Constant),
				price,
				tx.pure(500),
			],
		});
	
		tx.transferObjects([sui_dollar], keypair.getPublicKey().toSuiAddress());

		// if the user has no account we transfer it
		if (accountId === undefined) {
			tx.transferObjects([account], keypair.getPublicKey().toSuiAddress());
		}
		
    const { objectChanges } = await client.signAndExecuteTransactionBlock({
			signer: keypair,
			transactionBlock: tx,
			options: {
				showBalanceChanges: true,
				showEffects: true,
				showEvents: true,
				showInput: false,
				showObjectChanges: true,
				showRawInput: false
			},
			requestType: "WaitForLocalExecution"
		});

	if (!objectChanges) {
			console.log("Error: object  Changes was undefined")
			process.exit(1)
		}

	console.log(objectChanges)

	// Get Account object id 
	const filePath = path.join(__dirname, '../deployed_objects.json');
    const deployed_address = JSON.parse(fs.readFileSync(filePath, 'utf8'));

	const account1 = `${deployed_address.packageId}::bank::Account`

	const bank_id = find_one_by_type(objectChanges, account1)
	if (!bank_id) {
	    console.log("Error: Could not find Account ")
	    process.exit(1)
	}

	deployed_address.Bank_Accounts.owner_account =  bank_id;

	// // get price id 
	// const price1 = `${deployed_address.packageId}::oracle::Price`

	// const price1_id = find_one_by_type(objectChanges, price1)
	// if (!price1_id ) {
	//     console.log("Error: Could not find price object_id ")
	//     process.exit(1)
	// }

	// deployed_address.Price_Object.price_id = price1_id ;

	fs.writeFile(filePath, JSON.stringify(deployed_address, null, 2), 'utf8', (err) => {
		if (err) {
			console.error('false', err);
			return;
		}
		console.log('true');
	});




