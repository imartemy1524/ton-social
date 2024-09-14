import { SandboxContract } from '@ton/sandbox';
import { Address, toNano } from '@ton/core';
import '@ton/test-utils';
import { Achivement, AchivementMaster } from '../wrappers/Achievement';
import { UserLike } from '../wrappers/UserLike';
import { Comment } from '../build/Master/tact_Comment';
import { SocialMedia, deployMaster, createPost } from './_helpers';

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
    it('should create achievement after post ', async () => {
        const { next_item_index } = await achievementContract.getGetCollectionData();
        expect(next_item_index).toBe(0n);
        let oldData = await data.userAccounts[0]!.getData();

        await createPost(
            {
                account: data.userAccounts[0]!,
                wallet: data.userWallets[0]!,
                blockchain: data.blockchain,
            },
            { text: 'Hello, world!' },
        );
        const { next_item_index: newIndex } = await achievementContract.getGetCollectionData();
        let newData = await data.userAccounts[0]!.getData();
        expect(
            newData,
        ).not.toBe(oldData);
        expect(newIndex).toBe(1n);

        //shouldn't create after second time

        const {} = await createPost(
            {
                account: data.userAccounts[0]!,
                wallet: data.userWallets[0]!,
                blockchain: data.blockchain,
            },
            { text: 'Hello world!' },
        );
        expect(newIndex).toBe(1n);
        const {} = await createPost(
            {
                account: data.userAccounts[0]!,
                wallet: data.userWallets[0]!,
                blockchain: data.blockchain,
            },
            { text: 'Hello world!' },
        );
        expect(newIndex).toBe(1n);


    });
    // it('old', async ()=>{
        // const user1 = data.userAccounts[1];
        // const {receivedAchievements: old} = await user1.getData();
        // await user1.send(data.userWallets[0].getSender(), {value: toNano("1")}, "inc" );
        // const {receivedAchievements: newIT} = await user1.getData();
        // expect(old).not.toBe(newIT);
    // })
});
