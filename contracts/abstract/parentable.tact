

trait Parentable{
    parent: Address;
    //user id which created the original object (post)
    parentObjectUserOwnerId: Int;
    inline fun requireParentSender(){
        require(sender() == self.parent, "Only object parent can send messages to it");
    }
}