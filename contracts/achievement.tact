message MinAchievementInternal{
//    ownerUserId: Int as uint64;
    type: Int as uint8;
    excessTo: Address;
    owner: Address;
}
contract Achivement with AbstractAchivementSbt{
    master: Address;
    index: Int as uint64;
    type: Int as uint8 = 0;
    owner: Address? = null;
    _collectionAddress: Address;
    override const storageReserve: Int = ton("0.01");

    init(masterAddress: Address, collectionAddress: Address, index: Int){
        self.master = masterAddress;
        self.index = index;
        self._collectionAddress = collectionAddress;
        self.owner = null;
    }

    receive(msg: MinAchievementInternal){
        self.requireCollectionSender();
        require(self.owner == null, "Already initiated");
        self.owner = msg.owner;
        self.type = msg.type;
        self.forward(msg.excessTo, "New achievement recieved!".asComment(), false, null);
    }



    inline fun requireCollectionSender(){
        require(sender() == self.collectionAddress(), "Only collection can send this message");
    }

    override fun collectionAddress(): Address{
        return self._collectionAddress;
    }

}