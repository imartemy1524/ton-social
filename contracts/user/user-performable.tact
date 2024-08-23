// Other users can perform actions on behalf of this object
trait UserPerformable with Masterable{
    master: Address;
    inline fun requireSenderIsUser(userId: Int){
        require(sender() == self.userContractAddress(userId), "Not a user");
    }
    inline fun userContractAddress(userId: Int): Address{
        return contractAddress(initOf User(self.master, userId));
    }

}