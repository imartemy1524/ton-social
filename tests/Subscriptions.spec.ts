import '@ton/test-utils';
import { SocialMedia, deployMaster, setLevels, createSubscription, genLevels, decodeNftDataOnchain } from './_helpers';


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
    
    it('should subscription SBT Item be valid', async () => {
        const userFrom = data.userAccounts[0];
        const userTo = data.userAccounts[1];
        const userFromId = await userFrom.getData().then(e=>e.userId);
        const userToId = await userTo.getData().then(e=>e.userId);
        const {subscriptionContract, } = await createSubscription(data, Number(userFromId), Number(userToId));
        const { individual_content } = await subscriptionContract.getGetNftData();
        const content = await userTo.getGetNftContent(userFromId, individual_content);

        const onchainDataNFT = decodeNftDataOnchain(content);

        expect(Object.keys(onchainDataNFT).length).toBeGreaterThan(0);
        expect(onchainDataNFT.name).toBeTruthy();
        expect(onchainDataNFT.description).toBeTruthy();
        expect(onchainDataNFT.image_data).toBeTruthy();
        expect(onchainDataNFT.attributes?.some((e) => e.trait_type === 'Level')).toBeTruthy();
        expect(onchainDataNFT.attributes?.some((e) => e.trait_type === 'Payment period')).toBeTruthy();
    })
    it('should subscription SBT Collection be valid', async ()=>{
        const userFrom = data.userAccounts[0];
        const { collection_content } = await userFrom.getGetCollectionData();
        const onChainData = decodeNftDataOnchain(collection_content);
        expect(Object.keys(onChainData).length).toBeGreaterThan(0);
        expect(onChainData.name).toBeTruthy();
        expect(onChainData.description).toBeTruthy();
        expect(onChainData.image_data || onChainData.image).toBeTruthy();
    })
    //TODO: add more tests
});

