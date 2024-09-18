import { printTransactionFees, SandboxContract } from '@ton/sandbox';
import '@ton/test-utils';
import { SocialMedia, deployMaster } from './_helpers';
import { beginCell, Dictionary, DictionaryValue, fromNano, Sender, toNano } from '@ton/core';
import { loadIndividualContentSBT, SubscriptionData, User } from '../wrappers/User';
import { storeSubscriptionSetLevels, Subscription } from '../build/Master/tact_Subscription';
import { loadSubscriptionData, storeSubscriptionData } from '../build/Master/tact_Achivement';

async function setLevels(account: SandboxContract<User>, sender: Sender, levels: Map<number, SubscriptionData>) {
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

async function createSubscription(data: SocialMedia){
    const {
        userAccounts: [, , , , , subscribeFRomAccount, , , subscribeToAccount],
        userWallets: [, , , , , subscribeFRomWallet, , , subscribeToWallet],
        blockchain,
        master,
    } = data;

    const { userId: fromUserId, subscriptionsData: fromUserOldSubs } = await subscribeFRomAccount.getData();
    const { userId: toUserId, subscriptionsData: toUserOldSubs } = await subscribeToAccount.getData();
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

    const subscriptionContract = blockchain.openContract(
        await Subscription.fromInit(master.address, fromUserId, toUserId),
    );
    const loadedSubData = await subscriptionContract
        .getGetNftData()
        .then((e) => loadIndividualContentSBT(e.individual_content.beginParse()));
    const { level, paymentAmount, paymentPeriod } = loadedSubData!.data!;

    expect(level).toBe(0n);
    expect(paymentAmount).toBe(levels.get(0)!.paymentAmount);
    expect(paymentPeriod).toBe(levels.get(0)!.paymentPeriod);
    expect(loadedSubData.expiredAt).toEqual(BigInt(blockchain.now!) + (paymentPeriod));
    const fromUserData = await subscribeFRomAccount.getData();
    const toUserData = await subscribeToAccount.getData();
    expect(toUserData.subscriptionsData.toMeCount).toBe(toUserOldSubs.toMeCount+ 1n);
    expect(fromUserData.subscriptionsData.fromMeCount).toBe(fromUserOldSubs.fromMeCount + 1n);
    return {
        subscriptionContract,
        levels,
        level,
        paymentAmount,
        paymentPeriod
    };
}

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
        const subscription = await createSubscription(data);
    });
    //TODO: add more tests
});

function genLevels() {
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
