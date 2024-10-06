import { Address, beginCell, Contract, ContractProvider, toNano } from '@ton/core';
import { User } from '../wrappers/User';
import { CollectionAddress, MasterAddress } from './___config';
import { NicknamesCollection } from '../wrappers/NicknamesCollection';
import { NetworkProvider } from '@ton/blueprint';
import { NicknamesCollectionItem } from '../wrappers/NicknamesCollectionItem';
import { nicknameSmartcontract } from '../tests/_helpers';
import { Blockchain, SandboxContract } from '@ton/sandbox';

const WantDomain = 'first-user';

export async function run(provider: NetworkProvider) {
    const collection = provider.open(NicknamesCollection.fromAddress(CollectionAddress!));
    const user = provider.open(await User.fromInit(MasterAddress!, 1n));
    const nicknameContract = await nicknameSmartcontract(
        {
            blockchain: {
                openContract<T extends Contract>(contract: T): SandboxContract<T> {
                    return provider.open(contract) as unknown as SandboxContract<T>;
                },
            } as Blockchain,
            nicknamesMaster: collection,
        },
        WantDomain,
    );
    if (!(await provider.isContractDeployed(nicknameContract.address))) {
        await collection.send(
            provider.sender(),
            {
                value: toNano('0.1'),
                bounce: true,
            },
            WantDomain,
        );
        await provider.waitForDeploy(nicknameContract.address, 100);
    }
    let resolved = false;
    let owner: Address;
    do {
        const { auction, owner: ownerOld } = await nicknameContract.getData();
        resolved = auction?.endDate > BigInt(Math.round(+new Date() / 1000)) || auction?.endDate === 0n;
        if (auction?.endDate !== 0n) {
            console.log(
                'Waiting for auction to end: ',
                Math.round(Number(auction!.endDate) - +new Date() / 1000),
                ' seconds left',
            );
            await new Promise((r) => setTimeout(r, 10000));
        }
        owner = ownerOld!;
    } while (!resolved);
    if (!owner.equals(user.address)) {
        await nicknameContract.send(
            provider.sender(),
            {
                value: toNano('0.1'),
            },
            {
                $$type: 'Transfer',
                response_destination: provider.sender().address!,
                query_id: 0n,
                custom_payload: beginCell().endCell(),
                forward_amount: 1n,
                forward_payload: beginCell().storeStringTail('aboba abiba abuba').endCell().asSlice(),
                new_owner: user.address,
            },
        );
        await new Promise((r) => setTimeout(r, 25_000));
    }
    await user.send(
        provider.sender(),
        { value: toNano('0.15') },
        {
            $$type: 'ExternalValidateNickname',
            nickname: WantDomain,
        },
    );
    console.log('Nickname', WantDomain, 'linked to ', user.address.toString());
}
