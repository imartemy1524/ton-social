import { SandboxContract } from '@ton/sandbox';
import '@ton/test-utils';
import { SocialMedia, deployMaster, setLevels, createSubscription, genLevels } from './_helpers';
import { beginCell, Dictionary, DictionaryValue, fromNano, Sender, toNano } from '@ton/core';
import { loadIndividualContentSBT, SubscriptionData, User } from '../wrappers/User';
import { Subscription } from '../build/Master/tact_Subscription';
import { loadSubscriptionData, storeSubscriptionData } from '../build/Master/tact_Achivement';


describe('Subscription', () => {
    let data: SocialMedia;

    beforeEach(async () => {
        data = await deployMaster();
    });
    it('should set levels', async () => {
        const user = data.userAccounts[5];
        const sender = data.userWallets[5].getSender();
        for (let i = 1; i < 10; i++) {
            const levels = genLevels();
            await setLevels(user, sender, levels);
        }
        const levels = genLevels();
        await expect(setLevels(user, data.userWallets[4].getSender(), levels)).rejects.toThrow();
    });

    it('should subscribe', async () => {
        await createSubscription(data, 0, 1);
    });
    it('should subscribe many times', async () => {
        for (let i = 1; i < 11; i++) {
            await createSubscription(data, 0, i);
        }
        const {subscriptionsData, receivedAchievements} = await data.userAccounts[0].getData()

        expect(subscriptionsData.fromMeCount).toBe(10n);
        //user should contain 2 achievements: for 1 and 10 subscriptions
        expect(receivedAchievements & (1n << 0x30n)).not.toBe(0n);
        expect(receivedAchievements & (1n << 0x31n)).not.toBe(0n);
    });
    //TODO: add more tests
});

