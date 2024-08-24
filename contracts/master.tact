import "@stdlib/ownable";
import "./user.tact";
import "./nft/nfts.tact";
message ChangeRegisterAmount{
    amount: Int as coins;
}
message(0x12345678) Register{}

contract Master with OwnableTransferable, Deployable, MasterUserBans, NftCollection{
    override const CollectionName: String = "NetoTon users";
    override const CollectionDescription: String = "Users on NetoTon blockchain, each represented by a unique NFT";
    override const LogoURL: String = "https://i.imgur.com/P8tmkRB.png";
    override const MartketplaceURL: String = "getgems.io";
    override const DefaultUserAvatar: String = "https://clck.ru/3Cpgs9";

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
    receive(m: ChangeRegisterAmount){
        self.requireOwner();
        self.registerAmount = m.amount;
    }

    receive(m: Register){
        require(context().value >= self.registerAmount, "Not enough value");
        self.lastUserId += 1;
        let user = initOf User(myAddress(), self.lastUserId);
        send(SendParameters{
        value: 0,
        mode: SendRemainingValue,
        body: InitUserInternal{
        owner: sender(),
        // we take the excess as comission
        excessTo: self.owner
        }.toCell(),
        to: contractAddress(user),
        code: user.code,
        data: user.data
        });
    }
    get fun user(userId: Int): Address{
        return contractAddress(initOf User(myAddress(), userId));
    }
    get fun usersCount(): Int{
        return self.lastUserId;
    }

    //TODO: set to profit address
    override inline fun getRoyaltyAddress(): Address{
        return self.owner;
    }

}