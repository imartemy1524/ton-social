
import { toNano } from '@ton/core';
import { Master } from '../wrappers/Master';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const master = provider.open(await Master.fromInit());
    await master.send(
        provider.sender(),
        {
            value: toNano('1'),
        },
        {
            $$type: 'Register',
        }
    );
    console.log(`Master deployed at ${master.address.toString()}`);

    await provider.waitForDeploy(master.address);
    const lastUserId = await master.getUsersCount();
    const userAddress = await master.getUser(lastUserId);

    console.log(`User deployed at ${userAddress.toString()}`);

    // run methods on `master`
}
