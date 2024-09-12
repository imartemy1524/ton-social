message InitAchievement{
    ownerUserId: Int as uint64;
    type: Int as uint8;
}
contract Achivement with AbstractAchivementSbt{
    master: Address;
    index: Int as uint64;
    type: Int as uint8 = 0;
    ownerUserId: Int as uint64 = 0;

    init(masterAddress: Address, index: Int){
        self.master = masterAddress;
        self.index = index;
    }

    receive(msg: InitAchievement){
        self.requireCollectionSender();
        require(self.ownerUserId == 0, "Already initiated");
        self.ownerUserId = msg.ownerUserId;
        self.type = msg.type;
    }



    inline fun requireCollectionSender(){
        require(sender() == self.collectionAddress(), "Only collection can send this message");
    }

    override fun collectionAddress(): Address{
        let init: StateInit = initOf AchivementMaster(self.master);
        return contractAddress(init);
    }

}