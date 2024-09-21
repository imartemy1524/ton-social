import '@ton/test-utils';
import { SocialMedia, deployMaster } from './_helpers';

describe('Achievement', () => {
    let data: SocialMedia;
    beforeEach(async () => {
        data = await deployMaster();
        //achievement contract deployed with (actually after, but who cares) master.
    });
    it('should deploy', async () => {
        expect(1).toBe(1);
    });
});
