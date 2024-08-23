message InternalExcessableToUser{message: String;}


trait ExcessableToUser with UserPerformable{
    master: Address;
    inline fun excessToUser(userId: Int, message: String){
        send(SendParameters{
            to: self.userContractAddress(userId),
            value: 0,
            mode: SendRemainingValue,
            body: InternalExcessableToUser{message}.toCell()
        })
    }
}


trait ExcessableByUser with Ownable, Excessable{
    owner: Address;
    receive(m: InternalExcessableToUser){
        self.requireOwner();
        self.excess(self.owner, m.message);
    }
}