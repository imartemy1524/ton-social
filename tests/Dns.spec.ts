import '@ton/test-utils';
import { SocialMedia, deployMaster, sha256 } from './_helpers';
import { DnsContractsDeployer, DnsResolver } from '../wrappers/DnsResolver';
import { printTransactionFees } from '@ton/sandbox';
import { beginCell, toNano } from '@ton/core';

// Unit tests for resolving *.ntt domain names.
// In practice, instead of *.ntt domain names one would have *.neto.ton domain name, but it should resolve the same way
describe('Dns', () => {
    let data: SocialMedia;
    let resolver: DnsResolver;
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
        const deployer = new DnsContractsDeployer(data.masterOwner);
        const { address, transactions } = await deployer.deploy(data.nicknamesMaster.address);
        printTransactionFees(transactions);
        expect(transactions).toHaveTransaction({
            to: address,
            success: true,
        });
        resolver = new DnsResolver(data.blockchain, address);

        //achievement contract deployed with (actually after, but who cares) master.
    }, 20_000);
    it('should resolve *.id*.ntt domains', async () => {
        for (let i = 0; i < data.userAccounts.length; i++) {
            const ac = data.userAccounts[i];
            const { userId } = await ac.getData();
            const accountAddress = await resolver.getWalletAddress(`id${userId}.ntt`);
            expect(accountAddress).toEqualAddress(ac.address);
            const ownerAddress = await resolver.getWalletAddress(`owner.id${userId}.ntt`);
            expect(ownerAddress).toEqualAddress(data.userWallets[i].address);
        }
    });
    it('should resolve domain.ntt', async ()=>{
        const domain = 'domain.ntt';
        const address = await resolver.getWalletAddress(domain);
        expect(address).toEqualAddress(data.nicknamesMaster.address);
    })
    it('should resolve .ntt', async ()=>{
        const domain = 'ntt';
        const address = await resolver.getWalletAddress(domain);
        expect(address).toEqualAddress(data.master.address);
    })
});
