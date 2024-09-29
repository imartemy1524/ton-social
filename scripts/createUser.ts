
import { toNano } from '@ton/core';
import { Master } from '../wrappers/Master';
import { NetworkProvider } from '@ton/blueprint';
import { MasterAddress } from './___config';

export async function run(provider: NetworkProvider) {
    // const master = provider.open(await Master.fromInit());
    const master = provider.open(Master.fromAddress(MasterAddress));
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

    const user = await master.getUser(oldIndex+1n);
    console.log(`Deploying user ${oldIndex+1n} at ${user.toString()}`);

    await provider.waitForDeploy(user, 100);
    console.log(`User deployed at ${user.toString()}`);

    // run methods on `master`
}
