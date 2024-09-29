import { Address, beginCell, toNano, TupleItem } from '@ton/core';
import { Master } from '../wrappers/Master';
import { NetworkProvider } from '@ton/blueprint';
import { CollectionAddress, MasterAddress } from './___config';
import { NicknamesCollection } from '../wrappers/NicknamesCollection';
import { sha256_sync } from '@ton/crypto';
import { DnsResolver, parseNextResolverRecord, parseSmartContractAddressRecord } from '../wrappers/DnsResolver';
import { User } from '../wrappers/User';
//@ts-ignore
import TonWeb from "tonweb";
export async function run(provider: NetworkProvider) {

    const collection = provider.open(NicknamesCollection.fromAddress(CollectionAddress));
    const resolver = new DnsResolver(
        {
            async runGetMethod(address: Address, method: string, stackIN: TupleItem[]): Promise<{ stack: TupleItem[] }> {
                const { stack } = await provider.provider(address).get(method, stackIN);
                // @ts-ignore
                return { stack: stack.items };
            },
        },
        CollectionAddress,
    );
    const addr = await resolver.getWalletAddress('id1');
    console.log(addr!.toString());
}
