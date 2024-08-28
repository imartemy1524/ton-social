import {
    Blockchain,
    BlockchainTransaction,
    printTransactionFees,
    SandboxContract,
    TreasuryContract,
} from '@ton/sandbox';
import { User } from '../wrappers/User';
import { Master } from '../wrappers/Master';
import { beginCell, BitBuilder, BitReader, Builder, Cell, Dictionary, Slice, toNano } from '@ton/core';
import { sha256_sync } from '@ton/crypto';
import { readFile } from 'node:fs/promises';
import { readFileSync } from 'fs';

export interface SocialMedia {
    blockchain: Blockchain;
    userWallets: SandboxContract<TreasuryContract>[];
    userAccounts: SandboxContract<User>[];
    superMaster: SandboxContract<Master>;
    masterOwner: SandboxContract<TreasuryContract>;
    master: SandboxContract<Master>;
}
export const DefaultAvatar = readFileSync(__dirname+'/../avatar.jpg');

export async function deployMaster(): Promise<SocialMedia> {
    const blockchain = await Blockchain.create();
    const userWallets = await blockchain.createWallets(10);
    const [masterOwner] = await blockchain.createWallets(1);
    const master = blockchain.openContract(await Master.fromInit());
    await master.send(masterOwner.getSender(), { value: toNano('0.2') }, { $$type: 'Deploy', queryId: 0n });

    let userAccounts: SandboxContract<User>[] = [];
    for (const userWallet of userWallets) {
        const { transactions } = await master.send(
            userWallet.getSender(),
            { value: toNano('1') },
            { $$type: 'Register' },
        );
        // printTransactionFees(transactions);
        const userId = await master.getUsersCount();
        const user = blockchain.openContract(User.fromAddress(await master.getUser(userId)));
        //@ts-ignore
        expect(transactions as BlockchainTransaction[]).toHaveTransaction({
            from: master.address,
            to: user.address,
            success: true,
        });
        expect(await user.getOwner().then((e) => e.toString())).toBe(userWallet.address.toString());
        userAccounts.push(user);
    }

    return { blockchain, userWallets, userAccounts, master, masterOwner, superMaster: master };
}



//parsing onchain data in NFT
//reference: https://stackblitz.com/edit/ton-onchain-nft-parser?file=src%2Fmain.ts
//https://docs.ton.org/develop/dapps/asset-processing/metadata
interface ChunkDictValue {
    content: Buffer;
}
interface NFTDictValue {
    content: Buffer;
}
class NftOnChainDataParserClass {
    flattenSnakeCell(cell: Cell) {
        let c: Cell | null = cell;

        const bitResult = new BitBuilder(100000);
        while (c) {
            const cs = c.beginParse();
            if (cs.remainingBits === 0) {
                break;
            }

            const data = cs.loadBits(cs.remainingBits);
            bitResult.writeBits(data);
            c = c.refs && c.refs[0];
        }

        const endBits = bitResult.build();
        const reader = new BitReader(endBits);

        return reader.loadBuffer(reader.remaining / 8);
    }

    bufferToChunks(buff: Buffer, chunkSize: number) {
        const chunks: Buffer[] = [];
        while (buff.byteLength > 0) {
            chunks.push(buff.slice(0, chunkSize));
            // eslint-disable-next-line no-param-reassign
            buff = buff.slice(chunkSize);
        }
        return chunks;
    }

    makeSnakeCell(data: Buffer): Cell {
        const chunks = this.bufferToChunks(data, 127);

        if (chunks.length === 0) {
            return beginCell().endCell();
        }

        if (chunks.length === 1) {
            return beginCell().storeBuffer(chunks[0]).endCell();
        }

        let curCell = beginCell();

        for (let i = chunks.length - 1; i >= 0; i--) {
            const chunk = chunks[i];

            curCell.storeBuffer(chunk);

            if (i - 1 >= 0) {
                const nextCell = beginCell();
                nextCell.storeRef(curCell);
                curCell = nextCell;
            }
        }

        return curCell.endCell();
    }

    encodeOffChainContent(content: string) {
        let data = Buffer.from(content);
        const offChainPrefix = Buffer.from([1]);
        data = Buffer.concat([offChainPrefix, data]);
        return this.makeSnakeCell(data);
    }

    ChunkDictValueSerializer = {
        serialize(src: ChunkDictValue, builder: Builder) {},
        parse: (src: Slice): ChunkDictValue => {
            const snake = this.flattenSnakeCell(src.loadRef());
            return { content: snake };
        },
    };

    parseChunkDict(cell: Slice): Buffer {
        const dict = cell.loadDict(Dictionary.Keys.Uint(32), this.ChunkDictValueSerializer);

        let buf = Buffer.alloc(0);
        for (const [_, v] of dict) {
            buf = Buffer.concat([buf, v.content]);
        }
        return buf;
    }
}

type IDataAttribute = {
    trait_type: string;
    value: string;
}
interface NftData{
    name?: string;
    description?: string;
    image?: string;
    image_data?: Buffer;
    marketplace?: string;

    attributes?: IDataAttribute[]
}
export function decodeNftDataOnchain(data: Cell): NftData {
    const NftOnChainDataParser = new NftOnChainDataParserClass();
    const NFTDictValueSerializer = {
        serialize(src: NFTDictValue, builder: Builder) {},
        parse(src: Slice): NFTDictValue {
            const ref = src.loadRef().asSlice();

            const start = ref.loadUint(8);
            if (start === 0) {
                const snake = NftOnChainDataParser.flattenSnakeCell(ref.asCell());
                return { content: snake };
            }

            if (start === 1) {
                return { content: NftOnChainDataParser.parseChunkDict(ref) };
            }

            return { content: Buffer.from([]) };
        },
    };
    let slice = data.asSlice();

    slice.loadUint(8);
    const ans = slice.loadDict(Dictionary.Keys.Buffer(32), NFTDictValueSerializer);
    const ansMapped: Map<bigint, NFTDictValue> = new Map(
        Array.from(ans).map(([k, v]) => [BigInt('0x' + k.toString('hex')), v]),
    );
    const keys = new Map<bigint, string>(
        ['image', 'name', 'description', 'image', 'marketplace', 'image_data', 'attributes'].map((key) => [sha256(key), key]),
    );

    const realGoodObject: NftData = {};
    for (const [keyHash, valueBuffer] of ansMapped) {
        const realKey: string = keys.get(keyHash)!;
        if(!realKey){
            console.warn('key not found', keyHash);
        }
        let value: Buffer|string = valueBuffer.content;
        if(realKey === 'attributes'){
            let v = value!.toString('utf-8');
            value = JSON.parse(v);
        }
        else if(realKey != 'image_data'){
            value = value!.toString('utf-8');
        }
        //@ts-ignore
        realGoodObject[realKey! as unknown as 'image'] = value!;
    }
    return realGoodObject;
}

export function sha256(s: string): bigint {
    return BigInt('0x' + sha256_sync(s).toString('hex'));
}
