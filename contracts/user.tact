import "./abstract/excessable.tact";
import "./abstract/blockable.tact";
import "./abstract/masterable.tact";
import "./user/post-communicator.tact";
import "./post.tact";
import "./user/comment-communicator.tact";
import "./user/like-adder-communicator.tact";
import "./user/iuser.tact";
import "./subscribtion.tact";
//system messages
message InitUserInternal{
    owner: Address;
    excessTo: Address;
    achievementAddress: Address;
}

// getters
struct UserData{
    master: Address;
    userId: Int as uint64;
    owner: Address;
    blocked: Bool;
    postsCount: Int as uint64;
    likesCount: Int ;
    receivedAchievements: Int;
}




const NullAddress: Address = address("UQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJKZ");


contract User with OwnableTransferable, Excessable, BlockableByMaster, PostCommunicator, CommentCommunicator, LikeAdderCommunicator, IUser, NftItem{
    override const storageReserve: Int = ton("0.03");

    nickname: String? = null;
    avatar: String? = null;
    //variables from traits
    blocked: Bool = false;
    master: Address;
    postsCount: Int as uint64 = 0;
    likesCount: Int as uint64 = 0;
    commentsCount: Int as uint64 = 0;
    registerDate: Int as uint64 = 0;
    receivedAchievements: Int as uint256 = 0x0;
    achievementMinterAddress: Address;
    //user owner address
    owner: Address;
    //user id
    userId: Int as uint64;
    init(master: Address, userId: Int){
        self.master = master;
        self.userId = userId;
        self.owner = NullAddress;
        self.achievementMinterAddress = NullAddress;
    }
    receive(m: InitUserInternal){
        self.requireMaster();
        self.owner = m.owner;
        self.registerDate = now();
        self.achievementMinterAddress = m.achievementAddress;
        self.excess(m.excessTo, beginString().concat(self.userId.toString()).concat(" initialized").toString());
    }

    get fun data(): UserData{
        return UserData {
            master: self.master,
            userId: self.userId,
            owner: self.owner,
            blocked: self.blocked,
            postsCount: self.postsCount,
            likesCount: self.likesCount,
            receivedAchievements: self.receivedAchievements
        };
    }


    override inline fun getUserId(): Int{
        return self.userId;
    }
    override inline fun getIndividualContent(): Cell{
        return IndividualContent{
            avatar: self.avatar,
            nickname: self.nickname != null? self.nickname: null,
            postsCount: self.postsCount,
            registerDate: self.registerDate,
            likesCount: self.likesCount,
        }.toCell()
    }

}