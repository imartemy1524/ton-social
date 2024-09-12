import "@stdlib/ownable";
import "./user.tact";
import "./nft/user-nfts.tact";
import "./achievement-master.tact";
message ChangeRegisterAmount{
    amount: Int as coins;
}
message(0x12345678) Register{}
struct StringData{
    data: String;
}
contract Master with OwnableTransferable, MasterUserBans, NftCollection{
    override const CollectionName: String = "Test";//"NetoTon users";
    override const CollectionDescription: String = "Users on NetoTon blockchain, each represented by a unique NFT";
    //TODO
    override const LogoURL: String = "https://i.imgur.com/P8tmkRB.png"; //readFile("./static/collection.jpg", "binary");
    override const MartketplaceURL: String = "getgems.io";
    override const storageReserve: Int = ton("0.1");
    //TODO
//    override const DefaultUserAvatar: String = "https://i.imgur.com/AVgzcgn.png";
    //10%
    royaltyNumberator: Int as uint16 = 10_00;
    owner: Address;
    registerAmount: Int as coins;
    lastUserId: Int as uint64;
    init(){
        self.owner = sender();
        self.registerAmount = ton("1");
        self.lastUserId = 0;
    }
    receive(deploy: Deploy) {
        let state = initOf ProfitCalculator(myAddress());
        self.forward(contractAddress(state), DeployProfitCalculator{
            initData: self.getAchievementData(),
            body: MintAchievementMessage{excessTo: sender()}.toCell()
        }.toCell(), false, state);
    }
    inline fun getAchievementData(): StateInit{
        return initOf AchivementMaster(myAddress());
    }

    override inline fun getDefaultAvatar(): String{
        return readFile("./static/avatar.jpg", "binary");
    }
    receive(m: ChangeRegisterAmount){
        self.requireOwner();
        self.registerAmount = m.amount;
    }

    receive(m: Register){
        require(context().value >= self.registerAmount, "Not enough value");
        self.lastUserId += 1;
        let user = initOf User(myAddress(), self.lastUserId);
        self.forward(
            contractAddress(user),
            InitUserInternal{
                owner: sender(),
                // we take the excess as comission
                excessTo: self.owner
            }.toCell(),
            true,
            user
        );
    }
    get fun user(userId: Int): Address{
        return contractAddress(initOf User(myAddress(), userId));
    }
    get fun usersCount(): Int{
        return self.lastUserId;
    }
    get fun achievement(): Address{
        return contractAddress(self.getAchievementData());
    }
    //TODO: set to profit address
    override inline fun getRoyaltyAddress(): Address{
        return self.owner;
    }

}