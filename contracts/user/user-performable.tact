// Other users can perform actions on behalf of this object
trait UserPerformable{
    inline fun requireSenderIsUser(userId: Int){
        require(sender() == self.userContractAddress(userId), "Not a user");
    }
    inline fun userContractAddress(userId: Int): Address{
        return contractAddress(initOf User(self.getMasterAddress(), userId));
    }
    //TODO: need to be ABSTRACT, but multiple inheritance is not supported yet (WTAF?)
    inline virtual fun getMasterAddress(): Address{
        return myAddress();
    }

}