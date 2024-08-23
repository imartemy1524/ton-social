import { Blockchain, printTransactionFees, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { toNano } from '@ton/core';
import { UserPost } from '../wrappers/Post';
import '@ton/test-utils';
import { UserLike } from '../build/Post/tact_UserLike';

describe('Post', () => {
    let blockchain: Blockchain;
    let post: SandboxContract<UserPost>;
    let postOwner: SandboxContract<TreasuryContract>,
        users: SandboxContract<TreasuryContract>[];

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        [postOwner] = await blockchain.createWallets(1);
        users = await blockchain.createWallets(10);

        post = blockchain.openContract(await UserPost.fromInit(postOwner.address, 1n));


        await post.send(
            postOwner.getSender(),
            {
                value: toNano('0.05')
            },
            {
                $$type: 'Deploy',
                queryId: 0n
            }
        );
        await post.send(postOwner.getSender(), { value: toNano('0.05') }, {
            $$type: 'SetPostDataMessage',
            text: 'Hello, World!'
        });

        expect(await post.getData().then(e => e.text)).toBe('Hello, World!');
    });

    it('should like', async () => {
        for (let i = 0; i < 10; i++) {
           await post.send(users[i].getSender(), { value: toNano('0.1') }, {
                $$type: 'ExternalAddLikeOrDislike',
                like: {
                    $$type: 'LikeValue',
                    isLike: i % 3 === 0
                }
            });
        }
        //expect the post to have 4 likes and 6 dislikes
        let { likesCount, dislikesCount } = await post.getData();
        expect(likesCount).toBe(4n);
        expect(dislikesCount).toBe(6n);

        //now delete all likes and 3 dislikes

        for (let i = 0; i < 10; i++) {
            if ([0, 3, 6, 9, 1, 2, 4].includes(i)) {
                const {transactions} = await post.send(users[i].getSender(), { value: toNano('0.1') }, {
                    $$type: 'ExternalRemoveLikeOrDislike'
                });
            }
        }

        //expect the post to have 0 like and 3 dislikes
        ({ likesCount, dislikesCount } = await post.getData());
        expect(likesCount).toBe(0n);
        expect(dislikesCount).toBe(3n);

        const likeContract = blockchain.openContract(UserLike.fromAddress(await post.getLikeAt(users[7].address)));
        const data = await likeContract.getValue();

        expect(data!.likeValue!.isLike).toBe(false);

        const likeContractNotExists = blockchain.openContract(UserLike.fromAddress(await post.getLikeAt(users[3].address)));
        let catched: boolean = false;
        try{
            await likeContractNotExists.getValue();
        }catch(e){
            catched = true;
        }
        expect(catched).toBe(true);
    });
    it('should set text', async () => {
        const text = `
     Значимость этих проблем настолько очевидна, что начало повседневной работы по формированию позиции в значительной степени обуславливает создание соответствующий условий активизации. С другой стороны укрепление и развитие структуры обеспечивает широкому кругу (специалистов) участие в формировании дальнейших направлений развития. Равным образом новая модель организационной деятельности влечет за собой процесс внедрения и модернизации дальнейших направлений развития. Равным образом дальнейшее развитие различных форм деятельности играет важную роль в формировании соответствующий условий активизации.

Не следует, однако забывать, что консультация с широким активом позволяет выполнять важные задания по разработке форм развития. Повседневная практика показывает, что новая модель организационной деятельности требуют от нас анализа модели развития. Таким образом реализация намеченных плановых заданий играет важную роль в формировании систем массового участия.

Разнообразный и богатый опыт укрепление и развитие структуры требуют определения и уточнения направлений прогрессивного развития. С другой стороны консультация с широким активом играет важную роль в формировании систем массового участия.

Разнообразный и богатый опыт рамки и место обучения кадров требуют определения и уточнения системы обучения кадров, соответствует насущным потребностям. Товарищи! сложившаяся структура организации влечет за собой процесс внедрения и модернизации модели развития. Равным образом сложившаяся структура организации обеспечивает широкому кругу (специалистов) участие в формировании форм развития. Не следует, однако забывать, что начало повседневной работы по формированию позиции обеспечивает широкому кругу (специалистов) участие в формировании соответствующий условий активизации. Товарищи! постоянный количественный рост и сфера нашей активности позволяет выполнять важные задания по разработке соответствующий условий активизации.

Повседневная практика показывает, что начало повседневной работы по формированию позиции в значительной степени обуславливает создание модели развития. Значимость этих проблем настолько очевидна, что начало повседневной работы по формированию позиции представляет собой интересный эксперимент проверки новых предложений. С другой стороны новая модель организационной деятельности требуют от нас анализа позиций, занимаемых участниками в отношении поставленных задач. Повседневная практика показывает, что дальнейшее развитие различных форм деятельности позволяет выполнять важные задания по разработке дальнейших направлений развития. Повседневная практика показывает, что начало повседневной работы по формированию позиции влечет за собой процесс внедрения и модернизации системы обучения кадров, соответствует насущным потребностям. Разнообразный и богатый опыт постоянный количественный рост и сфера нашей активности играет важную роль в формировании позиций, занимаемых участниками в отношении поставленных задач.

Равным образом укрепление и развитие структуры требуют определения и уточнения систем массового участия. Таким образом рамки и место обучения кадров обеспечивает широкому кругу (специалистов) участие в формировании форм развития. Значимость этих проблем настолько очевидна, что укрепление и развитие структуры играет важную роль в формировании системы обучения кадров, соответствует насущным потребностям. Не следует, однако забывать, что консультация с широким активом обеспечивает широкому кругу (специалистов) участие в формировании существенных финансовых и административных условий. Таким образом постоянный количественный рост и сфера нашей активности требуют определения и уточнения новых предложений. Задача организации, в особенности же консультация с широким активом позволяет выполнять важные задания по разработке существенных финансовых и административных условий.

Разнообразный и богатый опыт начало повседневной работы по формированию позиции играет важную роль в формировании форм развития. Товарищи! сложившаяся структура организации способствует подготовки и реализации позиций, занимаемых участниками в отношении поставленных задач.

Таким образом постоянный количественный рост и сфера нашей активности позволяет оценить значение существенных финансовых и административных условий. Значимость этих проблем настолько очевидна, что постоянное информационно-пропагандистское обеспечение нашей деятельности играет важную роль в формировании дальнейших направлений развития. С другой стороны начало повседневной работы по формированию позиции позволяет оценить значение форм развития. Повседневная практика показывает, что новая модель организационной деятельности играет важную роль в формировании направлений прогрессивного развития.

Значимость этих проблем настолько очевидна, что реализация намеченных плановых заданий позволяет оценить значение существенных финансовых и административных условий. Повседневная практика показывает, что укрепление и развитие структуры обеспечивает широкому кругу (специалистов) участие в формировании модели развития. Товарищи! укрепление и развитие структуры способствует подготовки и реализации позиций, занимаемых участниками в отношении поставленных задач. Разнообразный и богатый опыт консультация с широким активом требуют от нас анализа направлений прогрессивного развития. Идейные соображения высшего порядка, а также сложившаяся структура организации влечет за собой процесс внедрения и модернизации новых предложений.

`;
        const { transactions } = await post.send(postOwner.getSender(), { value: toNano('0.05') }, {
            $$type: 'SetPostDataMessage',
            text
        });

        expect(await post.getData().then(e => e.text)).toBe(text);
    });
    it('should multilike', async ()=>{
        const manyUsers = await blockchain.createWallets(100);
        const [,,,,,,{transactions}] = await Promise.all(manyUsers.map(async (user, i) => {
            return post.send(user.getSender(), { value: toNano('0.1') }, {
                $$type: 'ExternalAddLikeOrDislike',
                like: {
                    $$type: 'LikeValue',
                    isLike: i % 3 === 0
                }
            });
        }));
        expect(await post.getData().then(e => e.likesCount)).toBe(BigInt(Math.ceil(manyUsers.length / 3)));
    })
});
