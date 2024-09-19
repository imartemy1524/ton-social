import { Master } from '../wrappers/Master';
import { toNano } from '@ton/core';
import { NetworkProvider } from '@ton/blueprint';
import { User, UserCreatePost } from "../wrappers/User"

export async function run(provider: NetworkProvider){
    const master = provider.open(await Master.fromInit());
    const user = provider.open(User.fromAddress(await master.getUser(1n)));
    const { postsCount } = await user.getData();

    const achievement = await master.getAchievement();
    console.log(`Achievement deployed at ${achievement.toString()}`);
    await user.send(
        provider.sender(),
        {
            value: toNano('0.35'),
        },
        {
            $$type: 'UserCreatePost',
            text: 'Hello, NetoTon blockchain!'
        }
    );
    const post = await user.getPost(postsCount+1n);
    await provider.waitForDeploy(post, 100);
    console.log(`Post deployed at ${post.toString()}`);


}