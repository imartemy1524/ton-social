import "./types.tact";

message RecieveAchivement{
    achivementId: Int as uint8;
    userId: Int as uint64;
}


trait AchivementsMinter with UserPerformable {
    master: Address;
    lastSbtId: Int;
    override inline fun getMasterAddress(): Address{
        return self.master;
    }

    receive(achivement: RecieveAchivement){
        self.requireSenderIsUser(achivement.userId);
        require(context().value >= ton("0.1"), "Not enough value to mint achivement");
        self.lastSbtId += 1;
        self.mint(achivement.userId, achivement.achivementId);
    }

    abstract inline fun mint(userId: Int, achivementId: Int);
}