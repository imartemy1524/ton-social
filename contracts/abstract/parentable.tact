

trait Parentable{
    parent: Address;
    inline fun requireParentSender(){
        require(sender() == self.parent, "Only object parent can send messages to it");
    }
}