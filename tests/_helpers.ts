import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import User from '../wrappers/User';
import Master from '../wrappers/Master';
import { toNano } from '@ton/core';

interface SocialMedia {
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
    for(const userWallet of userWallets) {
        await master.send(userWallet.getSender(), { value: toNano('0.2') }, { $$type: 'Register',  });
    }


    return { blockchain, userWallets, userAccounts, master, masterOwner, superMaster: master };
}