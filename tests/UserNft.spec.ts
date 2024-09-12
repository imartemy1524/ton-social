import '@ton/test-utils';
import { SocialMedia, deployMaster, decodeNftDataOnchain, DefaultAvatar } from './_helpers';
import { randomAddress } from '@ton/test-utils';
import { beginCell, Builder, Cell, Dictionary, DictionaryKey, Slice, toNano } from '@ton/core';
import { sha256_sync } from '@ton/crypto';
import { readFile, writeFile } from 'node:fs/promises';
import { createWriteStream, write } from 'node:fs';

describe('UserNft', () => {
    let data: SocialMedia;

    beforeEach(async () => {
        data = await deployMaster();
    });
    it('should call getters', async () => {
        const {
            userAccounts: [user],
            master,
        } = data;
        const { index, collection_address, owner_address, is_initialized } = await user.getGetNftData();
        const { master: masterAddress, owner, userId } = await user.getData();
        expect(index).toBe(userId);
        expect(collection_address).toEqualAddress(masterAddress);
        expect(owner_address).toEqualAddress(owner);
        expect(is_initialized).toBe(true);
        const address = await master.getGetNftAddressByIndex(index);
        expect(address).toEqualAddress(user.address);
    });
    // test, that verifies NFT unchain data
    it('should collection onchain data be valid', async () => {
        const {
            userAccounts: [user],
            master,
        } = data;
        const { collection_content } = await master.getGetCollectionData();

        const onchainDataCollection = decodeNftDataOnchain(collection_content);
        expect(Object.keys(onchainDataCollection).length).toBeGreaterThan(0);
        expect(onchainDataCollection.name).toBeTruthy();
        expect(onchainDataCollection.description).toBeTruthy();
        expect(onchainDataCollection.image_data || onchainDataCollection.image).toBeTruthy();
        const dataImage = await readFile(__dirname + '/../contracts/static/collection.jpg');
        // expect(onchainDataCollection.image_data?.equals(dataImage)).toBeTruthy();
    });
    it('should nft onchain data be valid', async () => {
        const {
            userAccounts: [, , user],
            master,
        } = data;
        const { individual_content, index } = await user.getGetNftData();
        const realContent = await master.getGetNftContent(index, individual_content);
        const onchainDataNFT = decodeNftDataOnchain(realContent);
        // console.log("NFT Content: ",realContent.toBoc().toString('hex'))
        expect(Object.keys(onchainDataNFT).length).toBeGreaterThan(0);
        expect(onchainDataNFT.name).toBeTruthy();
        expect(onchainDataNFT.description).toBeTruthy();
        expect(onchainDataNFT.image || onchainDataNFT.image_data).toBeTruthy();
        expect(onchainDataNFT.attributes?.some((e) => e.trait_type === 'Posts count')).toBeTruthy();
        expect(onchainDataNFT.attributes?.some((e) => e.trait_type === 'Register date')).toBeTruthy();
        expect(onchainDataNFT.image_data?.equals(DefaultAvatar)).toBeTruthy();
    });

    it('should transfer', async () => {
        const nft = data.userAccounts[0]!;
        const { owner_address } = await nft.getGetNftData();
        let newOwner = randomAddress();
        let { transactions } = await nft.send(
            data.userWallets[0].getSender(),
            {
                value: toNano('0.1'),
            },
            {
                $$type: 'Transfer',
                new_owner: newOwner,
                query_id: 0n,
                response_destination: randomAddress(),
                forward_amount: toNano('0.05'),
                custom_payload: beginCell().storeBit(1).endCell(),
                forward_payload: beginCell().endCell().asSlice(),
            },
        );
        //notification should be sent (OwnershipAssigned)
        expect(transactions).toHaveTransaction({
            from: nft.address,
            to: newOwner,
            op: 0x05138d91,
        });

        let { is_initialized, owner_address: newOwnerAfterTransfer } = await nft.getGetNftData();
        if (!is_initialized) {
            throw new Error();
        }

        //ownership should be transfered
        expect(newOwner).toEqualAddress(newOwnerAfterTransfer);
    });
});
