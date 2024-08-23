import { toNano } from '@ton/core';
import { Master } from '../wrappers/Master';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const master = provider.open(await Master.fromInit());

    await master.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        }
    );

    await provider.waitForDeploy(master.address);

    // run methods on `master`
}
