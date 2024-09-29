import "@stdlib/ownable";
import "./user.tact";
import "./utils/string.tact";
import "./nft/user-nfts.tact";
import "./achievement-master.tact";
import "./profit/profit-communicator.tact";
import "./nft/DNS/index.tact";
import "./DNS/dns-master.tact";
message ChangeRegisterAmount{
    amount: Int as coins;
}
message(0x12345678) Register{}
struct StringData{
    data: String;
}
message SetRegisterable{registerable: Bool;}
contract Master with OwnableTransferable, MasterUserBans, NftCollection, DnsMaster, Excessable{
    override const CollectionName: String = "Test";//"NetoTon users";
    override fun collectionDescription(): String{
        return beginString()
            .concat("Collection of ")
            .concat((self.lastUserId - self.startUserId).toString())
            .concat(" users on NetoTon blockchain, each represented by a unique NFT")
            .toString();
    }
    //TODO
    override const LogoURL: String = "https://i.imgur.com/P8tmkRB.png"; //readFile("./static/collection.jpg", "binary");
    override const MartketplaceURL: String = "marketplace.netoton.ton";
    override const storageReserve: Int = ton("0.1");
    //TODO
//    override const DefaultUserAvatar: String = "https://i.imgur.com/AVgzcgn.png";
    //10%
    royaltyNumberator: Int as uint16 = 10_00;
    owner: Address;
    registerAmount: Int as coins = ton("1");
    lastUserId: Int as uint64 = 0;
    startUserId: Int as uint64 = 0;
    registerable: Bool = true;
    nicknameCollection: Address;
    init(owner: Address, nicknameCollection: Address, startUserId: Int){
        self.owner = owner;
        self.nicknameCollection = nicknameCollection;
        self.startUserId = startUserId;
        self.lastUserId = startUserId;
    }
    receive(deploy: Deploy) {
        self.requireOwner();
        let state = initOf ProfitCalculator(myAddress());
        send(SendParameters{
            to: contractAddress(state),
            body: DeployProfitCalculator{
                excessTo: self.owner,
            }.toCell(),
            value: ton("0.15"),
            bounce: false,
            code: state.code,
            data: state.data,
            mode: SendIgnoreErrors
        });
        state = initOf AchivementMaster(myAddress());
        send(SendParameters{
            to: contractAddress(state),
            body: MintAchievementMessage{
                excessTo: self.owner,
            }.toCell(),
            value: ton("0.3"),
            bounce: true,
            code: state.code,
            data: state.data,
            mode: SendIgnoreErrors
        });
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
        self.excess(sender(), "ok");
    }
    receive(m: SetRegisterable){
        self.requireOwner();
        self.registerable = m.registerable;
        self.excess(sender(), "ok");
    }

    receive(m: Register){
        require(context().value >= self.registerAmount, "Not enough value");
        require(self.registerable, "Register is disabled");
        self.lastUserId += 1;
        let user = initOf User(myAddress(), self.lastUserId);
        self.forward(
            contractAddress(user),
            InitUserInternal{
                owner: sender(),
                // we take the excess as comission
                excessTo: self.owner,
                achievementAddress: contractAddress(self.getAchievementData()),
                profitAddress: contractAddress(initOf ProfitCalculator(myAddress())),
                nicknameCollection: self.nicknameCollection
            }.toCell(),
            true,
            user
        );
    }
    get fun user(userId: Int): Address{
        return contractAddress(initOf User(myAddress(), userId));
    }
    get fun usersCount(): Int{
        return self.lastUserId - self.startUserId;
    }
    get fun lastUserId(): Int{
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