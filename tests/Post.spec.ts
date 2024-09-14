import { Address, fromNano, toNano } from '@ton/core';
import '@ton/test-utils';
import { UserLike } from '../wrappers/UserLike';
import { Comment } from '../build/Master/tact_Comment';
import { SocialMedia, deployMaster, createPost } from './_helpers';
type Tree = {value: Address, children: Tree[]};

describe('Post', () => {
    let data: SocialMedia;

    beforeEach(async () => {
        data = await deployMaster();
        // blockchain = await Blockchain.create();
        //
        // [postOwner] = await blockchain.createWallets(1);
        // users = await blockchain.createWallets(10);
        //
        // post = blockchain.openContract(await UserPost.fromInit(postOwner.address, 1n));
        //
        //
        // await post.send(
        //     postOwner.getSender(),
        //     {
        //         value: toNano('0.05')
        //     },
        //     {
        //         $$type: 'Deploy',
        //         queryId: 0n
        //     }
        // );
        // await post.send(postOwner.getSender(), { value: toNano('0.05') }, {
        //     $$type: 'SetPostDataMessage',
        //     text: 'Hello, World!',
        // });
        //
        // expect(await post.getData().then(e => e.text)).toBe('Hello, World!');
    });
    it('should create', async () => {
        await createPost(
            {
                account: data.userAccounts[0]!,
                wallet: data.userWallets[0]!,
                blockchain: data.blockchain,
            },
            { text: 'Hello, world!' },
        );
    });
    it('should create many', async () => {
        for (let i = 0; i < 10; i++) {
            let text = `This is post #${i}!. Please welcome!`;
            await createPost(
                {
                    account: data.userAccounts[0]!,
                    wallet: data.userWallets[0]!,
                    blockchain: data.blockchain,
                },
                { text },
            );
        }
        const { postsCount } = await data.userAccounts[0]!.getData();
        expect(postsCount).toBe(10n);
    });
    it('should like', async () => {
        // const {userId: ownerUserId} = await data.userAccounts[5]!.getData();
        const post = await createPost(
            {
                account: data.userAccounts[5]!,
                wallet: data.userWallets[5]!,
                blockchain: data.blockchain,
            },
            { text: 'Hello, everybody, lets like/dislike this post!' },
        );
        const { postId } = await post.getData();
        // add 10 likes/dislikes (4 likes - 0,3,6,9, 6 dislikes - 1,2,4,5,7,8)
        for (let i = 0; i < 10; i++) {
            const { transactions } = await data.userAccounts[i]!.send(
                data.userWallets[i]!.getSender(),
                { value: toNano('0.3') },
                {
                    $$type: 'UserAddLike',
                    to: post.address,
                    isLike: {
                        $$type: 'LikeValue',
                        char: BigInt(i + 1),
                    },
                },
            );
        }
        //expect the post to have 4 likes and 6 dislikes
        let { likes } = await post.getData();
        expect(likes.size).toBe(10);
        for (let i = 1; i < 11; i++) {
            expect(likes.get(i)).toBe(1n);
        }

        //now delete all likes and 3 dislikes

        for (let i = 0; i < 10; i++) {
            const { transactions } = await data.userAccounts[i]!.send(
                data.userWallets[i]!.getSender(),
                { value: toNano('0.1') },
                {
                    $$type: 'UserAddLike',
                    to: post.address,
                    isLike: {
                        $$type: 'LikeValue',
                        char: BigInt([0, 3, 6, 9, 1, 2, 4].includes(i) ? 0 : 19),
                    },
                },
            );
            expect(transactions).toHaveTransaction({
                from: data.userWallets[i]!.address,
                to: data.userAccounts[i]!.address,
                success: true,
            });
        }

        //expect the post to have 0 like and 3 dislikes
        ({ likes } = await post.getData());
        expect(likes.size).toBe(1);
        expect(likes.get(19)).toBe(3n);

        //now lets check the like contract from 7s user
        const likeContract = data.blockchain.openContract(
            await UserLike.fromInit(
                data.master.address,
                post.address,
                await data.userAccounts[7].getData().then((e) => e.userId),
            ),
        );
        const { likeValue } = await likeContract.getValue();

        expect(likeValue!.char).toBe(19n);

        //now lets check the like contract from 3rd user - the contract should not exist, because the like was deleted
        const likeContractNotExists = data.blockchain.openContract(
            UserLike.fromAddress(await post.getLike(await data.userAccounts[6].getData().then((e) => e.userId))),
        );
        const {
            likeValue: { char },
        } = await likeContractNotExists.getValue();
        expect(char).toBe(0n);
    });
    it('should not double like', async () => {
        const { userId: ownerUserId } = await data.userAccounts[0]!.getData();
        const post = await createPost(
            {
                account: data.userAccounts[0]!,
                wallet: data.userWallets[0]!,
                blockchain: data.blockchain,
            },
            { text: 'Hello, everybody, lets like/dislike this post!' },
        );
        for (let i = 0; i < 10; i++) {
            const { transactions } = await data.userAccounts[i]!.send(
                data.userWallets[0]!.getSender(),
                { value: toNano('0.1') },
                {
                    $$type: 'UserAddLike',
                    to: post.address,
                    isLike: {
                        $$type: 'LikeValue',
                        char: 1n,
                    },
                },
            );
        }
        const { likes } = await post.getData();
        expect(likes.size).toBe(1);
        expect(likes.get(1)).toBe(1n);
        await data.userAccounts[0]!.send(
            data.userWallets[0]!.getSender(),
            { value: toNano('0.1') },
            {
                $$type: 'UserAddLike',
                to: post.address,
                isLike: {
                    $$type: 'LikeValue',
                    char: 0n,
                },
            },
        );
        const { likes: likesAfter } = await post.getData();
        expect(likesAfter.size).toBe(0);

        // await data.userAccounts[5]!.send(
        //     data.userWallets[5]!.getSender(),
        //     { value: toNano('0.1') },
        //     {
        //         $$type: 'UserAddLikePost',
        //         postId,
        //         ownerUserId,
        //         isLike: {
        //             $$type: 'LikeValue',
        //             isLike: true,
        //         }
        //     },
        // );
        // expect(await post.getData().then(e => e.likesCount)).toBe(1n);
        // await data.userAccounts[5]!.send(
        //     data.userWallets[5]!.getSender(),
        //     { value: toNano('0.1') },
        //     {
        //         $$type: 'UserAddLikePost',
        //         postId,
        //         ownerUserId,
        //         isLike: {
        //             $$type: 'LikeValue',
        //             isLike: true,
        //         }
        //     },
        // );
        // expect(await post.getData().then(e => e.likesCount)).toBe(1n);
        // await data.userAccounts[5]!.send(
        //     data.userWallets[5]!.getSender(),
        //     { value: toNano('0.1') },
        //     {
        //         $$type: 'UserAddLikePost',
        //         postId,
        //         ownerUserId,
        //         isLike: {
        //             $$type: 'LikeValue',
        //             isLike: false,
        //         }
        //     },
        // );
        // const { likesCount, dislikesCount } = await post.getData();
        // expect(likesCount).toBe(0n);
        // expect(dislikesCount).toBe(1n);
    });
    it('should edit post', async () => {
        const post = await createPost(
            {
                account: data.userAccounts[0]!,
                wallet: data.userWallets[0]!,
                blockchain: data.blockchain,
            },
            { text: 'Hello, everybody, lets like/dislike this post!' },
        );
        const { postId } = await post.getData();
        await data.userAccounts[0]!.send(
            data.userWallets[0]!.getSender(),
            { value: toNano('0.1') },
            {
                $$type: 'UserUpdateTextPost',
                postId,
                text: 'Hello, everybody, lets like/dislike this post! Edited!',
            },
        );
        const { text } = await post.getData();
        expect(text).toBe('Hello, everybody, lets like/dislike this post! Edited!');
    });

    it('should comment post tree', async () => {
        const post = await createPost(
            {
                account: data.userAccounts[0]!,
                wallet: data.userWallets[0]!,
                blockchain: data.blockchain,
            },
            { text: 'Hello, everybody, lets like/dislike this post!' },
        );
        let root: Tree = {value: post.address, children: []};
        let curr = root;
        for (let i = 0; i < 4; i++) {
            for (let child = 0; child < 1 + Math.ceil(Math.random() * 2); child++) {
                let ownerObject = data.blockchain.openContract(Comment.fromAddress(curr.value));
                let oldChildCount = await ownerObject.getChildren();
                const { transactions } = await data.userAccounts[child]!.send(
                    data.userWallets[child]!.getSender(),
                    { value: toNano('0.1') },
                    {
                        $$type: 'ExternalAddComment',
                        parentAddress: ownerObject.address,
                        text: 'Hello, everybody, lets comment this post!',
                    },
                );
                const newChildCount = await ownerObject.getChildren();
                expect(newChildCount).toBe(oldChildCount + 1n);
                const childComment = await ownerObject.getChildComment(newChildCount);

                expect(transactions).toHaveTransaction({
                    from: ownerObject.address,
                    to: childComment,
                    success: true,
                })
                curr.children.push({ value: childComment, children: [] });
            }
            curr = curr.children[Math.floor(Math.random() * curr.children.length)];
        }
        async function checkIT(address: Address, childrenCountNeed: number){
            const ownerObject = data.blockchain.openContract(Comment.fromAddress(address));
            const childrenCount = await ownerObject.getChildren();
            expect(childrenCount).toBe(BigInt(childrenCountNeed));
        }
        async function iterateOver(el: Tree){
            await checkIT(el.value, el.children.length);
            for (let i = 0; i < el.children.length; i++){
                await iterateOver(el.children[i]);
            }
        }
        await iterateOver(root);

    });
    //     it('should set text', async () => {
    //         const text = `
    //      Значимость этих проблем настолько очевидна, что начало повседневной работы по формированию позиции в значительной степени обуславливает создание соответствующий условий активизации. С другой стороны укрепление и развитие структуры обеспечивает широкому кругу (специалистов) участие в формировании дальнейших направлений развития. Равным образом новая модель организационной деятельности влечет за собой процесс внедрения и модернизации дальнейших направлений развития. Равным образом дальнейшее развитие различных форм деятельности играет важную роль в формировании соответствующий условий активизации.
    //
    // Не следует, однако забывать, что консультация с широким активом позволяет выполнять важные задания по разработке форм развития. Повседневная практика показывает, что новая модель организационной деятельности требуют от нас анализа модели развития. Таким образом реализация намеченных плановых заданий играет важную роль в формировании систем массового участия.
    //
    // Разнообразный и богатый опыт укрепление и развитие структуры требуют определения и уточнения направлений прогрессивного развития. С другой стороны консультация с широким активом играет важную роль в формировании систем массового участия.
    //
    // Разнообразный и богатый опыт рамки и место обучения кадров требуют определения и уточнения системы обучения кадров, соответствует насущным потребностям. Товарищи! сложившаяся структура организации влечет за собой процесс внедрения и модернизации модели развития. Равным образом сложившаяся структура организации обеспечивает широкому кругу (специалистов) участие в формировании форм развития. Не следует, однако забывать, что начало повседневной работы по формированию позиции обеспечивает широкому кругу (специалистов) участие в формировании соответствующий условий активизации. Товарищи! постоянный количественный рост и сфера нашей активности позволяет выполнять важные задания по разработке соответствующий условий активизации.
    //
    // Повседневная практика показывает, что начало повседневной работы по формированию позиции в значительной степени обуславливает создание модели развития. Значимость этих проблем настолько очевидна, что начало повседневной работы по формированию позиции представляет собой интересный эксперимент проверки новых предложений. С другой стороны новая модель организационной деятельности требуют от нас анализа позиций, занимаемых участниками в отношении поставленных задач. Повседневная практика показывает, что дальнейшее развитие различных форм деятельности позволяет выполнять важные задания по разработке дальнейших направлений развития. Повседневная практика показывает, что начало повседневной работы по формированию позиции влечет за собой процесс внедрения и модернизации системы обучения кадров, соответствует насущным потребностям. Разнообразный и богатый опыт постоянный количественный рост и сфера нашей активности играет важную роль в формировании позиций, занимаемых участниками в отношении поставленных задач.
    //
    // Равным образом укрепление и развитие структуры требуют определения и уточнения систем массового участия. Таким образом рамки и место обучения кадров обеспечивает широкому кругу (специалистов) участие в формировании форм развития. Значимость этих проблем настолько очевидна, что укрепление и развитие структуры играет важную роль в формировании системы обучения кадров, соответствует насущным потребностям. Не следует, однако забывать, что консультация с широким активом обеспечивает широкому кругу (специалистов) участие в формировании существенных финансовых и административных условий. Таким образом постоянный количественный рост и сфера нашей активности требуют определения и уточнения новых предложений. Задача организации, в особенности же консультация с широким активом позволяет выполнять важные задания по разработке существенных финансовых и административных условий.
    //
    // Разнообразный и богатый опыт начало повседневной работы по формированию позиции играет важную роль в формировании форм развития. Товарищи! сложившаяся структура организации способствует подготовки и реализации позиций, занимаемых участниками в отношении поставленных задач.
    //
    // Таким образом постоянный количественный рост и сфера нашей активности позволяет оценить значение существенных финансовых и административных условий. Значимость этих проблем настолько очевидна, что постоянное информационно-пропагандистское обеспечение нашей деятельности играет важную роль в формировании дальнейших направлений развития. С другой стороны начало повседневной работы по формированию позиции позволяет оценить значение форм развития. Повседневная практика показывает, что новая модель организационной деятельности играет важную роль в формировании направлений прогрессивного развития.
    //
    // Значимость этих проблем настолько очевидна, что реализация намеченных плановых заданий позволяет оценить значение существенных финансовых и административных условий. Повседневная практика показывает, что укрепление и развитие структуры обеспечивает широкому кругу (специалистов) участие в формировании модели развития. Товарищи! укрепление и развитие структуры способствует подготовки и реализации позиций, занимаемых участниками в отношении поставленных задач. Разнообразный и богатый опыт консультация с широким активом требуют от нас анализа направлений прогрессивного развития. Идейные соображения высшего порядка, а также сложившаяся структура организации влечет за собой процесс внедрения и модернизации новых предложений.
    //
    // `;
    //         const { transactions } = await post.send(
    //             postOwner.getSender(),
    //             { value: toNano('0.05') },
    //             {
    //                 $$type: 'SetPostDataMessage',
    //                 text,
    //             },
    //         );
    //
    //         expect(await post.getData().then((e) => e.text)).toBe(text);
    //     });
    //     it('should multilike', async () => {
    //         const manyUsers = await blockchain.createWallets(100);
    //         const [, , , , , , { transactions }] = await Promise.all(
    //             manyUsers.map(async (user, i) => {
    //                 return post.send(
    //                     user.getSender(),
    //                     { value: toNano('0.1') },
    //                     {
    //                         $$type: 'ExternalAddLikeOrDislike',
    //                         like: {
    //                             $$type: 'LikeValue',
    //                             isLike: i % 3 === 0,
    //                         },
    //                     },
    //                 );
    //             }),
    //         );
    //         expect(await post.getData().then((e) => e.likesCount)).toBe(BigInt(Math.ceil(manyUsers.length / 3)));
    //     });
});
