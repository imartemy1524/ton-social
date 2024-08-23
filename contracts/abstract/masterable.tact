

trait Masterable{
    master: Address;


    inline fun requireMaster(){
        require(sender() == self.master, "Not a master");
    }

}