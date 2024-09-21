import '@ton/test-utils';
import { SocialMedia, deployMaster, sha256, nicknameSmartcontract, createDomainAndClaimOwnership } from './_helpers';
import { Address, beginCell, toNano } from '@ton/core';
import { NicknamesCollectionItem } from '../wrappers/NicknamesCollectionItem';

// Unit tests for resolving *.ntt domain names.
// In practice, instead of *.ntt domain names one would have *.neto.ton domain name, but it should resolve the same way
describe('Nicknames', () => {
    let data: SocialMedia;
    beforeEach(async () => {
        data = await deployMaster();
        await data.nicknamesMaster.send(
            data.masterOwner.getSender(),
            { value: toNano('0.1') },
            {
                $$type: 'ExternalAdd',
                master: {
                    address: data.master.address,
                    startUserId: 0n,
                    $$type: 'OneMaster',
                },
            },
        );
    }, 20_000);
    it('should create NFT nickname', async () => {
        const sender = data.userWallets[5].getSender();
        const { transactions } = await data.nicknamesMaster.send(sender, { value: toNano('10.1') }, 'alice');
        const nicknameContract = await nicknameSmartcontract(data, 'alice');
        {
            const { master, owner, nickname, auction, linked } = await nicknameContract.getData();
            expect(linked).toBe(false);
            expect(master).toEqualAddress(data.nicknamesMaster.address);
            expect(owner).toBe(null);
            expect(nickname).toBe('alice');
            expect(auction!.lastBid!.owner).toEqualAddress(sender.address);
            expect(auction!.lastBid!.amount).toBe(toNano('10'));
            expect(Number(auction!.endDate)).toBe(data.blockchain.now! + 3600);
        }
        data.blockchain.now! += 3601;
        // "claiming" ownership
        {
            await nicknameContract.send(sender, { value: toNano('0.02') }, { $$type: 'EndAuctionMessage' });
            const { owner, auction, linked } = await nicknameContract.getData();
            expect(owner).toEqualAddress(sender.address);
            expect(auction.endDate).toEqual(0n);
            expect(auction.lastBid).toEqual(null);
            expect(linked).toBe(false);
        }
        //
    });
    it('should set nickname after auction', async () => {
        await createDomainAndClaimOwnership(data, data.userAccounts[2], data.userWallets[2]!.getSender(), 'bobina');
    });
    //TODO: add unit tests for auction
});
