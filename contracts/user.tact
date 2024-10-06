import "./abstract/excessable.tact";
import "./abstract/blockable.tact";
import "./abstract/masterable.tact";
import "./user/post-communicator.tact";
import "./post.tact";
import "./user/comment-communicator.tact";
import "./user/like-adder-communicator.tact";
import "./user/iuser.tact";
import "./subscription.tact";
import "./subscriptions/index.tact";
import "./DNS/dns-user.tact";
import "./DNS/dns-item.tact";
import "./DNS/nickname-item-findable.tact";
import "./nft/DNS/dns-nft-item.tact";
import "./user/avatar-changer.tact";
import "./nicknames-collection-item.tact";
//system messages
message InitUserInternal{
    owner: Address;
    excessTo: Address;
    achievementAddress: Address;
    profitAddress: Address;
    nicknameCollection: Address;
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
    subscriptionsData: UserSubscriptionsData;
    nickname: String?;
    avatar: String?;
}




const NullAddress: Address = address("UQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJKZ");


contract User with Excessable, BlockableByMaster, PostCommunicator, CommentCommunicator, LikeAdderCommunicator, NftItem, SubscriptionCommunicator, DnsUser, AvatarChanger{
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
    profitAddress: Address;
    //user owner address
    owner: Address;
    //user id
    userId: Int as uint64;
    subscriptionsData: UserSubscriptionsData= UserSubscriptionsData{ fromMeCount: 0, toMeCount: 0, levels: emptyMap()};
    blockedDNS: Bool = false;
    nicknameCollection: Address? = null;

    init(master: Address, userId: Int){
        self.master = master;
        self.userId = userId;
        self.owner = NullAddress;
        self.achievementMinterAddress = NullAddress;
        self.profitAddress = NullAddress;
    }
    receive(m: InitUserInternal){
        self.requireMaster();
        self.owner = m.owner;
        self.nicknameCollection = m.nicknameCollection;
        self.registerDate = now();
        self.achievementMinterAddress = m.achievementAddress;
        self.profitAddress = m.profitAddress;

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
            receivedAchievements: self.receivedAchievements,
            subscriptionsData: self.subscriptionsData,
            nickname: self.nickname!=null?self.nickname:"",
            avatar: self.avatar != null ? self.avatar: ""
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
            commentsCount: self.commentsCount
        }.toCell()
    }
    override fun getMasterAddress(): Address{
        return self.master;
    }

}