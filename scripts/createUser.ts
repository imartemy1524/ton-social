
import { toNano } from '@ton/core';
import { Master } from '../wrappers/Master';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const master = provider.open(await Master.fromInit());
    const { next_item_index: oldIndex } = await master.getGetCollectionData();
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

    const user = await master.getUser(oldIndex);

    await provider.waitForDeploy(user, 100);
    console.log(`User deployed at ${user.toString()}`);

    // run methods on `master`
}
