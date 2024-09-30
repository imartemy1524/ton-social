import {
    Address,
    ADNLAddress,
    beginCell,
    BitString,
    Cell,
    contractAddress,
    Dictionary,
    Sender,
    Slice,
    toNano,
    TupleItem
} from '@ton/core';
import { sha256_sync } from '@ton/crypto';
import { Blockchain, BlockchainTransaction, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { compile } from '@ton/blueprint';

export enum Category {
    DNS_CATEGORY_WALLET = 'wallet',
    DNS_CATEGORY_STORAGE = 'storage',
    DNS_CATEGORY_SITE = 'site',
    DNS_CATEGORY_NEXT_RESOLVER = 'next_resolver',
}

type AnsMap = Map<Category, StorageBagId | ADNLAddress | Address | null>;

interface Provider {
    runGetMethod(
        address: Address,
        method: string,
        stack: TupleItem[]
    ): Promise<{
        stack: TupleItem[];
    }>;
}

export class DnsResolver {
    constructor(
        private readonly provider: Provider,
        private readonly rootContract: Address
    ) {
    }

    public getWalletAddress(domain: string): Promise<Address | null> {
        return this.resolve(domain, Category.DNS_CATEGORY_WALLET, this.rootContract);
    }

    public getStorageBagId(domain: string): Promise<StorageBagId | null> {
        return this.resolve(domain, Category.DNS_CATEGORY_STORAGE, this.rootContract);
    }

    public getSiteAddress(domain: string): Promise<ADNLAddress | StorageBagId | null> {
        return this.resolve(domain, Category.DNS_CATEGORY_SITE, this.rootContract);
    }

    /**
     * @private
     * @param domain {string} e.g "sub.alice.ton"
     * @param category  {string | undefined} category of requested DNS record, null for all categories
     * @param rootContract
     * @returns {Promise<Cell | Address | ADNLAddress | StorageBagId | null>}
     */
    private resolve(
        domain: string,
        category: Category.DNS_CATEGORY_WALLET,
        rootContract: Address
    ): Promise<Address | null>;
    private resolve(
        domain: string,
        category: Category.DNS_CATEGORY_STORAGE,
        rootContract: Address
    ): Promise<StorageBagId | null>;
    private resolve(
        domain: string,
        category: Category.DNS_CATEGORY_SITE,
        rootContract: Address
    ): Promise<ADNLAddress | StorageBagId | null>;
    private resolve(domain: string, category: null, rootContract: Address): Promise<AnsMap>;
    private resolve(domain: string, category: Category | null, rootContract: Address) {
        return dnsResolveImpl(this.provider, rootContract, domainToBytes(domain), category, false);
    }

    async getAll(domain: string) {
        const nextRoot = await this.resolve(domain.split('.')[domain.split('.').length - 1], Category.DNS_CATEGORY_WALLET, this.rootContract)!;
        return this.resolve(domain.split('.').slice(0, domain.split('.').length-1).join('.'), null, nextRoot!);
    }
}

/**
 * Verify and convert domain
 * @param domain    {string}
 * @return {Uint8Array}
 */
const domainToBytes = (domain: string): Uint8Array => {
    if (!domain || !domain.length) {
        throw new Error('empty domain');
    }
    if (domain === '.') {
        return new Uint8Array([0]);
    }

    domain = domain.toLowerCase();

    for (let i = 0; i < domain.length; i++) {
        if (domain.charCodeAt(i) <= 32) {
            throw new Error('bytes in range 0..32 are not allowed in domain names');
        }
    }

    for (let i = 0; i < domain.length; i++) {
        const s = domain.substring(i, i + 1);
        for (let c = 127; c <= 159; c++) {
            // another control codes range
            if (s === String.fromCharCode(c)) {
                throw new Error('bytes in range 127..159 are not allowed in domain names');
            }
        }
    }

    const arr = domain.split('.');

    arr.forEach((part) => {
        if (!part.length) {
            throw new Error('domain name cannot have an empty component');
        }
    });

    let rawDomain = arr.reverse().join('\0') + '\0';
    if (Math.random() > 0.5) {
        rawDomain = '\0' + rawDomain;
    }

    return new TextEncoder().encode(rawDomain);
};

/**
 * @private
 * @param cell  {Cell}
 * @param prefix0 {number}
 * @param prefix1 {number}
 * @return {Address|null}
 */
const parseSmartContractAddressImpl = (cell: Slice, prefix0: number, prefix1: number) => {
    if (cell.loadUint(8) !== prefix0 || cell.loadUint(8) !== prefix1)
        throw new Error('Invalid dns record value prefix');
    return cell.loadMaybeAddress();
};

/**
 * @param cell  {Cell}
 * @return {Address|null}
 */
export const parseSmartContractAddressRecord = (cell: Slice) => {
    return parseSmartContractAddressImpl(cell, 0x9f, 0xd3);
};

class StorageBagId {
    constructor(public address: bigint) {
    }
}

/**
 * @param cell  {Cell}
 * @return {Address|null}
 */
export const parseNextResolverRecord = (cell: Slice) => {
    return parseSmartContractAddressImpl(cell, 0xba, 0x93);
};
const parseSiteRecord = (cell: Slice) => {
    if (!cell) return null;
    if (cell.preloadUint(8) === 0xad || cell.preloadUintBig(2) / 0x100n === 0x01n) {
        return parseAdnlAddressRecord(cell);
    } else {
        return parseStorageBagIdRecord(cell);
    }
};
const parseAdnlAddressRecord = (cell: Slice) => {
    if (cell.loadUint(8) !== 0xad || cell.loadUint(8) !== 0x01) throw new Error('Invalid dns record value prefix');
    return new ADNLAddress(cell.loadBuffer(32));
};
const parseStorageBagIdRecord = (cell: Slice) => {
    if (cell.loadUint(8) !== 0x74 || cell.loadUint(8) !== 0x73) throw new Error('Invalid dns record value prefix');
    const bytes = cell.loadUintBig(32 * 8); // skip prefix - first 16 bits
    return new StorageBagId(bytes);
};

function toCategory(s: Category | null): bigint {
    return s ? BigInt('0x' + sha256_sync(s).toString('hex')) : 0n;
}

/**
 * @private
 * @param provider
 * @param dnsAddress   {string} address of dns smart contract
 * @param rawDomainBytes {Uint8Array}
 * @param category  {string | undefined} category of requested DNS record
 * @param oneStep {boolean | undefined} non-recursive
 * @returns {Promise<Cell | Address | ADNLAddress | StorageBagId | null>}
 */
const dnsResolveImpl = async (
    provider: Provider,
    dnsAddress: Address,
    rawDomainBytes: Uint8Array,
    category: Category | null,
    oneStep: boolean
): Promise<Cell | Address | null | ADNLAddress | StorageBagId | AnsMap> => {
    const len = rawDomainBytes.length * 8;

    const domainCell = beginCell();
    domainCell.storeBits(
        new BitString(Buffer.from(rawDomainBytes), 0, rawDomainBytes.byteLength * rawDomainBytes.BYTES_PER_ELEMENT * 8)
    );
    const resultRaw = await provider.runGetMethod(dnsAddress, 'dnsresolve', [
        { type: 'slice', cell: domainCell.endCell() },
        { type: 'int', value: toCategory(category) }
    ]);
    const result = resultRaw.stack;
    if (result.length !== 2) {
        throw new Error('Invalid dnsresolve response');
    }
    if (result[0].type !== 'int') {
        throw new Error('Invalid dnsresolve response');
    }
    const resultLen: bigint = result[0].value;
    let cell = result[1];
    if (cell.type === 'null') return null;
    if (cell.type !== 'cell' && cell.type !== 'slice') {
        throw new Error('Invalid dnsresolve response');
    }
    if (resultLen % 8n !== 0n) {
        throw new Error('domain split not at a component boundary');
    }
    if (resultLen > len) {
        throw new Error('invalid response ' + resultLen + '/' + len);
    } else if (Number(resultLen) === len) {
        if (category === Category.DNS_CATEGORY_NEXT_RESOLVER) {
            return cell ? parseNextResolverRecord(cell.cell.beginParse()) : null;
        } else if (category === Category.DNS_CATEGORY_WALLET) {
            return cell ? parseSmartContractAddressRecord(cell.cell.beginParse()) : null;
        } else if (category === Category.DNS_CATEGORY_SITE) {
            return cell ? parseSiteRecord(cell.cell.beginParse()) : null;
        } else if (category === Category.DNS_CATEGORY_STORAGE) {
            return cell ? parseStorageBagIdRecord(cell.cell.beginParse()) : null;
        } else if (category === null) {
            const ans = cell.cell.beginParse().loadDictDirect(Dictionary.Keys.BigUint(256), Dictionary.Values.Cell());
            const map: AnsMap = new Map();
            if (ans.has(toCategory(Category.DNS_CATEGORY_WALLET)!)) {
                const wallet = ans.get(toCategory(Category.DNS_CATEGORY_WALLET)!);
                map.set(
                    Category.DNS_CATEGORY_WALLET,
                    wallet ? parseSmartContractAddressRecord(wallet.beginParse()) : null
                );
            }
            if (ans.has(toCategory(Category.DNS_CATEGORY_SITE)!)) {
                const site = ans.get(toCategory(Category.DNS_CATEGORY_SITE)!);
                map.set(Category.DNS_CATEGORY_SITE, site ? parseSiteRecord(site.beginParse()) : null);
            }
            if (ans.has(toCategory(Category.DNS_CATEGORY_STORAGE)!)) {
                const storage = ans.get(toCategory(Category.DNS_CATEGORY_STORAGE)!);
                map.set(Category.DNS_CATEGORY_STORAGE, storage ? parseStorageBagIdRecord(storage.beginParse()) : null);
            }
            if (ans.has(toCategory(Category.DNS_CATEGORY_NEXT_RESOLVER)!)) {
                const next = ans.get(toCategory(Category.DNS_CATEGORY_NEXT_RESOLVER)!);
                map.set(Category.DNS_CATEGORY_NEXT_RESOLVER, next ? parseNextResolverRecord(next.beginParse()) : null);
            }
            return map;
        } else {
            throw new Error('invalid category');
        }
    } else {
        let nextAddress: Address|null;
        if (category)
            nextAddress = parseNextResolverRecord(cell.cell.beginParse());
        else {
            const dict = cell.cell
                .beginParse()
                .loadDictDirect(Dictionary.Keys.BigUint(256), Dictionary.Values.Cell());
            nextAddress = parseNextResolverRecord(
                dict.get(toCategory(Category.DNS_CATEGORY_NEXT_RESOLVER))?.beginParse()!
            )!;
        }
        if (!nextAddress) return null;
        if (oneStep) {
            if (category === Category.DNS_CATEGORY_NEXT_RESOLVER) {
                return nextAddress;
            } else {
                return null;
            }
        } else {
            return await dnsResolveImpl(
                provider,
                nextAddress,
                rawDomainBytes.slice(Number(resultLen) / 8),
                category,
                false
            );
        }
    }
};

export class DnsContractsDeployer {
    MasterCode: Cell | null = null;

    constructor() {
    }

    async prepare() {
        this.MasterCode = await compile('DnsResolver');
    }

    async deploy(
        sender: SandboxContract<any>,
        masterAddress: Address
    ): Promise<{
        address: Address;
        transactions: BlockchainTransaction[];
    }> {
        const code = this.MasterCode!;
        const data = beginCell()
            .storeAddress(masterAddress) //address of ".ton" dns resolver
            .storeAddress(null)
            .storeAddress(null)
            .endCell();
        const to = contractAddress(0, {
            code,
            data
        });
        const { transactions } = await sender.send({
            value: toNano('0.5'),
            to,
            bounce: false,
            init: {
                code,
                data
            },
            body: beginCell().storeUint(0x123, 32).storeStringTail('Init!').endCell()
        });
        return { address: to, transactions };
    }
}
