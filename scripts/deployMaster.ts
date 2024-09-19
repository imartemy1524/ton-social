import { toNano } from '@ton/core';
import { Master } from '../wrappers/Master';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const master = provider.open(await Master.fromInit());

    console.log(`Master deployed at ${master.address}`);

    await master.send(
        provider.sender(),
        {
            value: toNano('0.55'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        }
    );

    await provider.waitForDeploy(master.address, 100);
    // run methods on `master`
    await import("./createUser").then(e=>e.run(provider));
}
