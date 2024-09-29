import '@ton/test-utils';
import { printTransactionFees, SandboxContract } from '@ton/sandbox';
import { Achivement, AchivementMaster } from '../wrappers/Achievement';
import { SocialMedia, deployMaster, createPost, decodeNftDataOnchain, DefaultAvatar } from './_helpers';
import { toNano } from '@ton/core';
import { XMLParser, XMLValidator } from 'fast-xml-parser';

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
    it('should create every 1 10 100 posts', async () => {
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
    it('should create achievement after like', async () => {
        const post = await createPost(
            {
                account: data.userAccounts[5]!,
                wallet: data.userWallets[5]!,
                blockchain: data.blockchain,
            },
            { text: 'Hello, everybody, lets like/dislike this post!' },
        );
        const { postId } = await post.getData();
        // add 10 likes/dislikes (4 likes - 0,3,6,9, 6 dislikes - 1,2,4,5,7,8)
        for (let i = 0; i < 10; i++) {
            const { receivedAchievements: oldAchievementsCount } = await data.userAccounts[i].getData();
            const { transactions } = await data.userAccounts[i]!.send(
                data.userWallets[i]!.getSender(),
                { value: toNano('0.3') },
                {
                    $$type: 'UserAddLike',
                    to: post.address,
                    isLike: {
                        $$type: 'LikeValue',
                        char: BigInt(i + 1),
                    },
                },
            );
            const { receivedAchievements } = await data.userAccounts[i].getData();
            expect(receivedAchievements).toBeGreaterThan(oldAchievementsCount);
        }
    });

    it('should create achievement after comment', async () => {
        //someone created post
        const post = await createPost(
            {
                account: data.userAccounts[5]!,
                wallet: data.userWallets[5]!,
                blockchain: data.blockchain,
            },
            { text: 'Hello, everybody, lets comment this post!' },
        );
        const { postId } = await post.getData();
        // user 0 adding 100 comments
        for (let i = 1; i <= 101; i++) {
            const { receivedAchievements: oldAchievementsCount } = await data.userAccounts[0].getData();
            await data.userAccounts[0]!.send(
                data.userWallets[0]!.getSender(),
                { value: toNano('0.3') },
                {
                    $$type: 'ExternalAddComment',
                    text: `Hello, world from ${i}!`,
                    parentAddress: post.address,
                },
            );
            const { receivedAchievements } = await data.userAccounts[0].getData();
            if (i === 1 || i == 10 || i == 100) {
                // 1, 10, 100 comments should add attachment
                expect(receivedAchievements).toBeGreaterThan(oldAchievementsCount);
            }
            else{
                expect(receivedAchievements).toBe(oldAchievementsCount);
            }
        }
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
        expect(isSvg(SVG)).toBeTruthy();
        expect(isSvg(SVG + 'bob')).not.toBeTruthy();
    });
});

export default function isSvg(string: string) {
    if (typeof string !== 'string') {
        throw new TypeError(`Expected a \`string\`, got \`${typeof string}\``);
    }

    string = string.trim();

    if (string.length === 0) {
        return false;
    }

    // Has to be `!==` as it can also return an object with error info.
    if (XMLValidator.validate(string) !== true) {
        return false;
    }

    let jsonObject;
    const parser = new XMLParser();

    try {
        jsonObject = parser.parse(string);
    } catch {
        return false;
    }

    if (!jsonObject) {
        return false;
    }

    if (!Object.keys(jsonObject).some((x) => x.toLowerCase() === 'svg')) {
        return false;
    }

    return true;
}
