import { toNano } from '@ton/core';
import '@ton/test-utils';
import { deployMaster, SocialMedia } from './_helpers';

describe('Master', () => {
    let data: SocialMedia;
    beforeEach(async () => {
        data = await deployMaster();
    });

    it('should ban user', async () => {
        // check user blocking progress
        const { master, userAccounts } = data;
        let { userId: userId0, blocked: blocked0 } = await userAccounts[0].getData();
        let { userId: userId1, blocked: blocked1 } = await userAccounts[1].getData();
        expect(blocked0).toBe(false);
        expect(blocked1).toBe(false);
        //block user0
        await master.send(
            data.masterOwner.getSender(),
            { value: toNano('0.2') },
            {
                $$type: 'BanUserById',
                userId: userId0,
                value: true,
            },
        );
        let { blocked: blockedAfter0 } = await userAccounts[0].getData();
        let { blocked: blockedAfter1 } = await userAccounts[1].getData();
        expect(blockedAfter0).toBe(true);
        expect(blockedAfter1).toBe(false);
        //try to do some actions, it should fail
        const { transactions } = await userAccounts[0].send(
            data.userWallets[0].getSender(),
            { value: toNano('0.2') },
            {
                $$type: 'UserCreatePost',
                text: 'Hello, World!',
            },
        );
        expect(transactions).toHaveTransaction({
            from: data.userWallets[0].address,
            to: userAccounts[0].address,
            success: false
        });

        //unblock user0
        await master.send(
            data.masterOwner.getSender(),
            { value: toNano('0.2') },
            {
                $$type: 'BanUserById',
                userId: userId0,
                value: false,
            },
        );
        let { blocked: blockedAfter0After } = await userAccounts[0].getData();
        let { blocked: blockedAfter1After } = await userAccounts[1].getData();
        expect(blockedAfter0After).toBe(false);
        expect(blockedAfter1After).toBe(false);


        // the check is done inside beforeEach
        // blockchain and master are ready to use
    });
    it('should change owner', async () => {
        const { master, userAccounts } = data;
        const { transactions } = await master.send(
            data.masterOwner.getSender(),
            { value: toNano('0.2') },
            {
                $$type: 'ChangeOwner',
                newOwner: userAccounts[1].address,
                queryId: 0n,
            },
        );
        expect(transactions).toHaveTransaction({
            from: data.masterOwner.address,
            to: master.address,
            success: true
        });
        expect(await master.getOwner()).toEqualAddress(userAccounts[1].address);
    });
});
