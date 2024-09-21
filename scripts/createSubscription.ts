


import { Master, SubscriptionData } from '../wrappers/Master';
import { Dictionary, toNano } from '@ton/core';
import { NetworkProvider } from '@ton/blueprint';
import { User, UserCreatePost } from "../wrappers/User"
import { Subscription } from '../build/Master/tact_Subscription';

export async function run(provider: NetworkProvider){
    const master = provider.open(await Master.fromInit());
    const user = provider.open(User.fromAddress(await master.getUser(1n)));
    const userTo = provider.open(User.fromAddress(await master.getUser(2n)));
    const {subscriptionsData} = await userTo.getData();
    if(subscriptionsData.levels.size === 0){
        const d = Dictionary.empty<number, SubscriptionData>();
        d.set(1, {level: 1n, paymentPeriod: 3600n * 24n * 30n, paymentAmount: toNano('0.6'), $$type: 'SubscriptionData'});
        await userTo.send(
            provider.sender(),
            {
                value: toNano('0.1'),
            },
            {
                $$type: 'SubscriptionSetLevels',
                levels: d
            }
        );
        await new Promise(resolve => setTimeout(resolve, 10_000));
    }
    const { subscriptionsData: {fromMeCount} } = await user.getData();

    await user.send(
        provider.sender(),
        {
            value: toNano('0.35') + toNano('0.6'),
        },
        {
            $$type: 'ExternalSubscribeToUser',
            subscribeToUserId: 2n,
            level: 1n
        }
    );
    const subscription = await Subscription.fromInit(master.address, 1n, 2n);
    await provider.waitForDeploy(subscription.address, 100);
    console.log(`Subscription deployed at ${subscription.address}`);


}