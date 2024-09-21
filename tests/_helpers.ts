import {
    Blockchain,
    BlockchainTransaction,
    SandboxContract,
    TreasuryContract,
} from '@ton/sandbox';
import { loadIndividualContentSBT, SubscriptionData, User } from '../wrappers/User';
import { loadSubscriptionData, Master, storeSubscriptionData } from '../wrappers/Master';
import {NicknamesCollection} from "../wrappers/NicknamesCollection";
import { UserPost } from '../wrappers/UserPost';
import {Subscription} from "../wrappers/Subscription"
import { ProfitCalculator } from '../wrappers/ProfitCalculator';
import {
    beginCell,
    BitBuilder,
    BitReader,
    Builder,
    Cell,
    Dictionary,
    DictionaryValue,
    fromNano,
    Sender,
    Slice,
    toNano,
} from '@ton/core';
import { sha256_sync } from '@ton/crypto';
import { readFileSync } from 'fs';
export interface SocialMedia {
    blockchain: Blockchain;
    userWallets: SandboxContract<TreasuryContract>[];
    userAccounts: SandboxContract<User>[];
    superMaster: SandboxContract<Master>;
    masterOwner: SandboxContract<TreasuryContract>;
    master: SandboxContract<Master>;
    profitContract: SandboxContract<ProfitCalculator>;
    nicknamesMaster: SandboxContract<NicknamesCollection>;
}

export const DefaultAvatar = readFileSync(__dirname + '/../contracts/static/avatar.jpg');

export async function deployMaster(): Promise<SocialMedia> {
    const blockchain = await Blockchain.create();
    blockchain.now = 1000;
    const userWallets = await blockchain.createWallets(11);
    const [masterOwner] = await blockchain.createWallets(1);
    const nicknamesMaster = blockchain.openContract(await NicknamesCollection.fromInit(
        masterOwner.address,
        123n
    ));
    await nicknamesMaster.send(
        masterOwner.getSender(),
        {
            value: toNano('0.3')
        },
        {
            $$type: 'Deploy',
            queryId: 0n
        },
    )
    const master = blockchain.openContract(await Master.fromInit());
    const { transactions } = await master.send(
        masterOwner.getSender(),
        { value: toNano('0.6') },
        {
            $$type: 'Deploy',
            queryId: 0n,
        },
    );
    expect(transactions).not.toHaveTransaction({
        exitCode: e=>e !== 0,
    });

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

    const profitContract = blockchain.openContract(await ProfitCalculator.fromInit(master.address));
    return { blockchain, userWallets, userAccounts, master, masterOwner, superMaster: master, profitContract, nicknamesMaster };
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
};

interface NftData {
    name?: string;
    description?: string;
    image?: string;
    image_data?: Buffer;
    marketplace?: string;

    attributes?: IDataAttribute[];
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
        ['image', 'name', 'description', 'image', 'marketplace', 'image_data', 'attributes'].map((key) => [
            sha256(key),
            key,
        ]),
    );

    const realGoodObject: NftData = {};
    for (const [keyHash, valueBuffer] of ansMapped) {
        const realKey: string = keys.get(keyHash)!;
        if (!realKey) {
            console.warn('key not found', keyHash);
        }
        let value: Buffer | string = valueBuffer.content;
        if (realKey === 'attributes') {
            let v = value!.toString('utf-8');
            value = JSON.parse(v);
        } else if (realKey != 'image_data') {
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

export async function createPost(
    {
        account,
        wallet,
        blockchain,
    }: {
        account: SandboxContract<User>;
        wallet: SandboxContract<TreasuryContract>;
        blockchain: Blockchain;
    },
    { text: textInitial }: { text: string },
) {
    const { postsCount: prevPostsCount } = await account.getData();
    const { transactions } = await account.send(
        wallet.getSender(),
        { value: toNano('0.35') },
        {
            $$type: 'UserCreatePost',
            text: textInitial,
        },
    );
    // printTransactionFees(transactions);
    expect(transactions).toHaveTransaction({
        from: wallet.address,
        to: account.address,
        success: true,
    });
    const { postsCount } = await account.getData();
    expect(postsCount).toBe(prevPostsCount + 1n);
    const post = blockchain.openContract(UserPost.fromAddress(await account.getPost(postsCount)));
    const { likes, text, ownerUserId } = await post.getData();
    expect(text).toBe(textInitial);
    expect(likes.size).toBe(0);
    expect(ownerUserId).toBe(await account.getData().then((e) => e.userId));
    return post;
}

export async function setLevels(account: SandboxContract<User>, sender: Sender, levels: Map<number, SubscriptionData>) {
    const dict = Dictionary.empty<number, SubscriptionData>();
    for (const [key, value] of levels) {
        dict.set(key, value);
    }
    await account.send(
        sender,
        {
            value: toNano('0.1'),
        },
        {
            $$type: 'SubscriptionSetLevels',
            levels: dict,
        },
    );
    const {
        subscriptionsData: { levels: levelsNew },
    } = await account.getData();
    const CellA = beginCell().storeDict(dict, Dictionary.Keys.Uint(8), dictValueParserSubscriptionData()).endCell();
    const CellB = beginCell()
        .storeDict(levelsNew, Dictionary.Keys.Uint(8), dictValueParserSubscriptionData())
        .endCell();
    expect(CellA.toString()).toBe(CellB.toString());

    function dictValueParserSubscriptionData(): DictionaryValue<SubscriptionData> {
        return {
            serialize: (src, builder) => {
                builder.storeRef(beginCell().store(storeSubscriptionData(src)).endCell());
            },
            parse: (src) => {
                return loadSubscriptionData(src.loadRef().beginParse());
            },
        };
    }
}

export async function createSubscription(data: SocialMedia, fromUserIndex: number, toUserIndex: number) {
    const { blockchain, master } = data;
    const [subscribeFRomAccount, subscribeFRomWallet] = [
        data.userAccounts[fromUserIndex],
        data.userWallets[fromUserIndex],
    ];
    const [subscribeToAccount, subscribeToWallet] = [data.userAccounts[toUserIndex], data.userWallets[toUserIndex]];

    const { userId: fromUserId, subscriptionsData: fromUserOldSubs } = await subscribeFRomAccount.getData();
    const { userId: toUserId, subscriptionsData: toUserOldSubs } = await subscribeToAccount.getData();
    const subscriptionContract = blockchain.openContract(
        await Subscription.fromInit(master.address, fromUserId, toUserId),
    );

    const levels = genLevels();
    await setLevels(subscribeToAccount, subscribeToWallet.getSender(), levels);

    const oldUserToBalance = await blockchain.getContract(subscribeToAccount.address).then((e) => e.balance);
    const { transactions } = await subscribeFRomAccount.send(
        subscribeFRomWallet.getSender(),
        { value: toNano('0.35') + levels.get(0)!.paymentAmount },
        {
            $$type: 'ExternalSubscribeToUser',
            subscribeToUserId: toUserId,
            level: 0n,
        },
    );
    const newUserToBalance = await blockchain.getContract(subscribeToAccount.address).then((e) => e.balance);
    expect(+fromNano(newUserToBalance - oldUserToBalance)).toBeCloseTo(
        +fromNano((levels.get(0)!.paymentAmount * 99n) / 100n),
    );

    const loadedSubData = await subscriptionContract
        .getGetNftData()
        .then((e) => loadIndividualContentSBT(e.individual_content.beginParse()));
    const { level, paymentAmount, paymentPeriod } = loadedSubData!.data!;

    expect(level).toBe(0n);
    expect(paymentAmount).toBe(levels.get(0)!.paymentAmount);
    expect(paymentPeriod).toBe(levels.get(0)!.paymentPeriod);
    expect(loadedSubData.expiredAt).toEqual(BigInt(blockchain.now!) + paymentPeriod);
    const fromUserData = await subscribeFRomAccount.getData();
    const toUserData = await subscribeToAccount.getData();
    expect(toUserData.subscriptionsData.toMeCount).toBe(toUserOldSubs.toMeCount + 1n);
    expect(fromUserData.subscriptionsData.fromMeCount).toBe(fromUserOldSubs.fromMeCount + 1n);
    return {
        subscriptionContract,
        levels,
        level,
        paymentAmount,
        paymentPeriod,
    };
}

export function genLevels() {
    const levels: Map<number, SubscriptionData> = new Map();
    const limit = Math.random() * 5 + 3;
    for (let j = 0; j < ~~limit; j++) {
        levels.set(j, {
            level: BigInt(j),
            paymentAmount: toNano('45.5') + toNano((~~(Math.random() * 100)).toString()),
            paymentPeriod: 3600n * 24n * BigInt(~~(Math.random() * 10)),
            $$type: 'SubscriptionData',
        });
    }
    return levels;
}
