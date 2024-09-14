import "./types.tact";

message ReceiveAchivement{
    achievementId: Int as uint8;
    userId: Int as uint64;
    excessTo: Address;
}


trait AchivementsMinter with UserPerformable {
    master: Address;
    lastSbtId: Int;
    override inline fun getMasterAddress(): Address{
        return self.master;
    }

    receive(achivement: ReceiveAchivement){
        let addr = self.userContractAddress(achivement.userId);
        require(sender() == addr, "Invalid sender");
        require(context().value >= ton("0.12"), "Not enough value to mint achivement");
        self.lastSbtId += 1;
        self.mint(addr, achivement.achievementId, achivement.excessTo);
    }

    abstract inline fun mint(owner: Address, achievementId: Int, excessTo: Address);
}