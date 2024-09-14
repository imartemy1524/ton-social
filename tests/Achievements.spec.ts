import { SandboxContract } from '@ton/sandbox';
import '@ton/test-utils';
import { Achivement, AchivementMaster } from '../wrappers/Achievement';
import { SocialMedia, deployMaster, createPost, decodeNftDataOnchain, DefaultAvatar } from './_helpers';

describe('Achievement', () => {
    let data: SocialMedia;
    let achievementContract: SandboxContract<AchivementMaster>;
    beforeEach(async () => {
        data = await deployMaster();
        //achievement contract deployed with (actually after, but who cares) master.
        achievementContract = data.blockchain.openContract(
            AchivementMaster.fromAddress(await data.master.getAchievement()),
        );
    });
    it('should create achievement after post', async () => {
        const { next_item_index } = await achievementContract.getGetCollectionData();
        expect(next_item_index).toBe(0n);
        let oldData = await data.userAccounts[0]!.getData();

        await createPost(
            {
                account: data.userAccounts[0]!,
                wallet: data.userWallets[0]!,
                blockchain: data.blockchain,
            },
            { text: 'Hello, world 3!' },
        );
        const { next_item_index: newIndex } = await achievementContract.getGetCollectionData();

        let newData = await data.userAccounts[0]!.getData();
        expect(newData.receivedAchievements).toBe(oldData.receivedAchievements + 1n);
        expect(newIndex).toBe(1n);

        const achievement = data.blockchain.openContract(
            Achivement.fromAddress(await achievementContract.getGetNftAddressByIndex(newIndex)),
        );
        expect(await achievement.getGetNftData().then((e) => e.owner_address)).toEqualAddress(
            data.userAccounts[0].address,
        );

        //shouldn't create after second time

        const {} = await createPost(
            {
                account: data.userAccounts[0]!,
                wallet: data.userWallets[0]!,
                blockchain: data.blockchain,
            },
            { text: 'Hello world 4!' },
        );
        let newData2 = await data.userAccounts[0]!.getData();

        const {} = await createPost(
            {
                account: data.userAccounts[0]!,
                wallet: data.userWallets[0]!,
                blockchain: data.blockchain,
            },
            { text: 'Hello world 5!' },
        );
        expect(newData2.receivedAchievements).toBe(newData.receivedAchievements);
    });
    it('should achievement data be valid', async () => {
        await createPost(
            {
                account: data.userAccounts[0]!,
                wallet: data.userWallets[0]!,
                blockchain: data.blockchain,
            },
            { text: 'Hello world 4!' },
        );
        const nft = data.blockchain.openContract(
            Achivement.fromAddress(await achievementContract.getGetNftAddressByIndex(1n)),
        );
        const { individual_content, index } = await nft.getGetNftData();
        const realContent = await achievementContract.getGetNftContent(index, individual_content);
        const onchainDataNFT = decodeNftDataOnchain(realContent);

        expect(Object.keys(onchainDataNFT).length).toBeGreaterThan(0);
        expect(onchainDataNFT.name).toBeTruthy();
        expect(onchainDataNFT.description).toBeTruthy();
        expect(onchainDataNFT.image_data).toBeTruthy();
        expect(onchainDataNFT.attributes?.some((e) => e.trait_type === 'Activity type')).toBeTruthy();
        expect(onchainDataNFT.attributes?.some((e) => e.trait_type === 'Amount')).toBeTruthy();

        let SVG = onchainDataNFT.image_data!.toString('utf-8');
        console.log('SVG onchain image: ', SVG);
    });
    it('should create every 000', async () => {
        let old: bigint = 0n;
        for (let i = 1; i < 102; i += 1) {
            await createPost(
                {
                    account: data.userAccounts[0]!,
                    wallet: data.userWallets[0]!,
                    blockchain: data.blockchain,
                },
                { text: 'Hello, world!' },
            );
            const { next_item_index: newIndex } = await achievementContract.getGetCollectionData();
            const newData = await data.userAccounts[0]!.getData();
            if (i === 1 || i === 10 || i === 100 || i === 1000) {
                expect(newData.receivedAchievements).toBeGreaterThan(old);
            } else {
                expect(newData.receivedAchievements).toBe(old);
            }

            old = newData.receivedAchievements;
        }
    });
});
