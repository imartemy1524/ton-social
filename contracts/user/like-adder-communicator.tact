import "../abstract/likeable.tact";
message UserAddLike{
    to: Address;
    isLike: LikeValue;
}


trait LikeAdderCommunicator with Masterable, Ownable{
    master: Address;
    owner: Address;
    virtual const MinLikeFee: Int = ton("0.1");
    //Adds like to (Contract(m.to) instanceof LikeableObject)
    receive(m: UserAddLike){
        self.requireOwner();
        require(context().value >= self.MinLikeFee, "Value must be >= 0.1");
        let to: StateInit = initOf UserLike(self.master, m.to, self.getUserId());
        send(SendParameters{
            value: 0,
            mode: SendRemainingValue,
            to: contractAddress(to),
            body: SetLikeInternal{
                value: m.isLike,
                excessTo: self.owner
            }.toCell(),
            code: to.code,
            data: to.data
        });
    }
    abstract inline fun getUserId(): Int;
}