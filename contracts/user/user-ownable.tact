


trait UserOwnable with Masterable{
    master: Address;
    ownerUserId: Int;

    inline fun requireOwner(_sender: Address){
        require(_sender == contractAddress(initOf User(self.master, self.ownerUserId)), "Not a user");
    }
}