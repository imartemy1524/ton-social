import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { toNano } from '@ton/core';
import { Master } from '../wrappers/Master';
import '@ton/test-utils';

describe('Master', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let master: SandboxContract<Master>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        master = blockchain.openContract(await Master.fromInit());

        deployer = await blockchain.treasury('deployer');

        const deployResult = await master.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            }
        );

        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: master.address,
            deploy: true,
            success: true,
        });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and master are ready to use
    });
});
