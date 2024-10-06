import { toNano } from '@ton/core';
import { Master } from '../wrappers/Master';
import { NetworkProvider } from '@ton/blueprint';
import { NicknamesCollection } from '../wrappers/NicknamesCollection';

export async function run(provider: NetworkProvider) {
    const collection = provider.open(await NicknamesCollection.fromInit(provider.sender().address!, 12347n));

    const master = provider.open(await Master.fromInit(provider.sender().address!, collection.address!, 0n));
    console.log(`Collection deployed at ${collection.address}`);
    console.log(`Master deployed at ${master.address}`);

    let startUserId: bigint = 0n;
    if (await provider.isContractDeployed(collection.address)) {
        const { masters, size } = await collection.getMasters();
        if (masters.values().some((e) => e.address.equals(master.address))) startUserId = -1n;
        else {
            const master1 = provider.open(Master.fromAddress(masters.get(size - 1n)!.address));
            startUserId = (await master1.getLastUserId()) + 1n;
        }
    }
    if (startUserId !== -1n) {
        await collection.send(
            provider.sender(),
            {
                value: toNano('0.5'),
            },
            {
                $$type: 'ExternalAdd',
                master: {
                    address: master.address,
                    startUserId,
                    $$type: 'OneMaster',
                },
            },
        );
    }

    await new Promise(r=>setTimeout(r, 10000));
    await master.send(
        provider.sender(),
        {
            value: toNano('0.55'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        },
    );

    await provider.waitForDeploy(master.address, 100);
    // run methods on `master`
    // await import('./createUser').then((e) => e.run(provider));
}
