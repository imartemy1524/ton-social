import {
    Blockchain,
    BlockchainTransaction,
    printTransactionFees,
    SandboxContract,
    TreasuryContract,
} from '@ton/sandbox';
import { User } from '../wrappers/User';
import { Master } from '../wrappers/Master';
import { toNano } from '@ton/core';

export interface SocialMedia {
    blockchain: Blockchain;
    userWallets: SandboxContract<TreasuryContract>[];
    userAccounts: SandboxContract<User>[];
    superMaster: SandboxContract<Master>;
    masterOwner: SandboxContract<TreasuryContract>;
    master: SandboxContract<Master>;
}

export async function deployMaster(): Promise<SocialMedia> {
    const blockchain = await Blockchain.create();
    const userWallets = await blockchain.createWallets(10);
    const [masterOwner] = await blockchain.createWallets(1);
    const master = blockchain.openContract(await Master.fromInit());
    await master.send(masterOwner.getSender(), { value: toNano('0.2') }, { $$type: 'Deploy', queryId: 0n });

    let userAccounts: SandboxContract<User>[] = [];
    for (const userWallet of userWallets) {
        const { transactions } = await master.send(
            userWallet.getSender(),
            { value: toNano('1') },
            { $$type: 'Register' },
        );
        const userId = await master.getUsersCount();
        const user = blockchain.openContract(User.fromAddress(await master.getUser(userId)));
        //@ts-ignore
        expect(transactions as BlockchainTransaction[]).toHaveTransaction({
            from: master.address,
            to: user.address,
            success: true,
        });
        expect(await user.getOwner().then(e=>e.toString())).toBe(userWallet.address.toString());
        userAccounts.push(user);
    }

    return { blockchain, userWallets, userAccounts, master, masterOwner, superMaster: master };
}

