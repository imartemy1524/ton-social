import '@ton/test-utils';
import { SocialMedia, deployMaster, sha256, createDomainAndClaimOwnership } from './_helpers';
import { Category, DnsContractsDeployer, DnsResolver } from '../wrappers/DnsResolver';
import { printTransactionFees } from '@ton/sandbox';
import { beginCell, toNano } from '@ton/core';

// Unit tests for resolving *.ntt domain names.
// In practice, instead of *.ntt domain names one would have *.neto.ton domain name, but it should resolve the same way
describe('Dns', () => {
    let data: SocialMedia;
    let resolver: DnsResolver;
    let deployer: DnsContractsDeployer;
    beforeAll(async ()=>{
        deployer = new DnsContractsDeployer();
        await deployer.prepare();
    })
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
        const { address, transactions } = await deployer.deploy(data.masterOwner, data.nicknamesMaster.address);
        expect(transactions).toHaveTransaction({
            to: address,
            success: true,
        });
        resolver = new DnsResolver(data.blockchain, address);

        //achievement contract deployed with (actually after, but who cares) master.
    }, 20_000);
    it('should resolve *.id*.ntt domains', async () => {
        console.log("master address", data.master.address.toString())
        for (let i = 0; i < data.userAccounts.length; i++) {
            const ac = data.userAccounts[i];
            const { userId } = await ac.getData();
            const accountAddress = await resolver.getWalletAddress(`id${userId}.ntt`);
            expect(accountAddress).toEqualAddress(ac.address);
            const accountAddress2 = await resolver.getAll(`id${userId}.ntt`);
            expect(accountAddress2.get(Category.DNS_CATEGORY_WALLET)).toEqualAddress(ac.address);
            const ownerAddress = await resolver.getWalletAddress(`owner.id${userId}.ntt`);
            const ownerAddress2 = await resolver.getAll(`owner.id${userId}.ntt`);
            expect(ownerAddress).toEqualAddress(data.userWallets[i].address);
            expect(ownerAddress2.get(Category.DNS_CATEGORY_WALLET)).toEqualAddress(data.userWallets[i].address);
        }
    });
    it('should resolve domain.ntt', async () => {
        const domain = 'domain.ntt';
        const address = await resolver.getWalletAddress(domain);
        expect(address).toEqualAddress(data.nicknamesMaster.address);
    });
    it('should resolve .ntt', async () => {
        const domain = 'ntt';
        const address = await resolver.getWalletAddress(domain);
        expect(address).toEqualAddress(data.master.address);
    });
    it('should resolve alice.ntt', async () => {
        const domain = 'alice.ntt';
        await createDomainAndClaimOwnership(data, data.userAccounts[2], data.userWallets[2].getSender(), 'alice');
        const address = await resolver.getWalletAddress(domain);
        expect(address).toEqualAddress(data.userAccounts[2].address);
    });
    it('should resolve owner.alice.ntt', async () => {
        const domain = 'owner.alice.ntt';
        await createDomainAndClaimOwnership(data, data.userAccounts[2], data.userWallets[2].getSender(), 'alice');
        const address = await resolver.getWalletAddress(domain);
        expect(address).toEqualAddress(await data.userAccounts[2].getOwner());
    });
    it('should resolve master.ntt', async () => {
        const domain = 'master.ntt';
        const address = await resolver.getWalletAddress(domain);
        expect(address).toEqualAddress(data.master.address);
        console.log(data.nicknamesMaster.address.toString(), "nicknames master address");
        console.log(data.master.address.toString(), "master address");
        const address2 = await resolver.getAll(domain);
        expect(address2.get(Category.DNS_CATEGORY_WALLET)).toEqualAddress(data.master.address);
    });
    it('should resolve owner.master.ntt', async () => {
        const domain = 'owner.master.ntt';
        const address = await resolver.getWalletAddress(domain);
        expect(address).toEqualAddress(data.masterOwner.address);
    });
});
