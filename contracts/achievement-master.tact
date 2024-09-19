import "./achievements/index.tact";
import "./achievement.tact";
message MintAchievementMessage{
    excessTo: Address;
}

contract AchivementMaster with AchivementsMinter, AchievementCollection, Blockable, Masterable{
    override const CollectionName: String = "NetoTon Achievements";
    override const CollectionDescription: String = "Collection of SBT achievements, which automatically minted by the system for NetoTon users";
    override const LogoURL: String = readFile("./achievements/collectionLogo.svg", "utf8");
    override const MartketplaceURL: String = "getgems.io";
    override const storageReserve: Int = ton("0.1");


    master: Address;
    lastSbtId: Int as uint64 = 0;
    blocked: Bool = true;
    init(master: Address){
        self.master = master;
    }

    override inline fun mint(owner: Address, achievementId: Int, excessTo: Address){
        let ach = initOf Achivement(self.master, myAddress(), self.lastSbtId);
        self.forward(contractAddress(ach), MinAchievementInternal{owner, type: achievementId, excessTo}.toCell(), false, ach)
    }

    override inline fun at(id: Int): Address{
        return contractAddress(initOf Achivement(self.master, myAddress(), id));
    }
    receive(m: MintAchievementMessage){
        self.requireMaster();
        require(self.blocked, "Minting is blocked");
        self.blocked = false;
        self.forward(m.excessTo, "achievement ok".asComment(), false, null);
        ///ok...???
    }

}