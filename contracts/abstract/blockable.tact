message BlockByMasterInternal{
    value: Bool;
}
message BanUserById{
    userId: Int as uint64;
    value: Bool;
}
message BlockSuccess{
    userId: Int as uint64;
    value: Bool;
}
trait BlockableByMaster with Blockable, Masterable{
    blocked: Bool;
    master: Address;
    receive(m: BlockByMasterInternal){
        self.requireMaster();
        self.blocked = m.value;
        send(SendParameters{
            to: self.master,
            value: 0,
            mode: SendRemainingValue,
            body: BlockSuccess{userId: self.getUserId(), value: m.value}.toCell()
        })
    }
    inline abstract fun getUserId(): Int;

}
trait Blockable with Excessable{
    blocked: Bool;
    inline fun requireNotBlocked(){
        require(!self.blocked, "Object blocked!");
    }
}


trait MasterUserBans with Ownable, UserPerformable{
    owner: Address;

    receive(m: BanUserById){
        self.requireOwner();
        require(context().value >= ton("0.1"), "Value must be >= 0.1");
        let user = contractAddress(initOf User(myAddress(), m.userId));
        send(SendParameters{
            value: 0,
            mode: SendRemainingValue,
            to: user,
            body: BlockByMasterInternal{
                value: m.value
            }.toCell(),
        });
    }
    receive(m: BlockSuccess){
        self.requireSenderIsUser(m.userId);
        send(SendParameters{
            value: 0,
            mode: SendRemainingValue,
            to: self.owner,
            body: beginString().concat("User ").concat(m.userId.toString()).concat(m.value?" blocked": "unblocked").toString().asComment()
        });
    }


}
