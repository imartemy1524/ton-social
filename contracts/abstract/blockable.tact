message(0x40300) BlockByMaster{
    value: Bool;
}


trait Blockable with Masterable{
    master: Address;
    blocked: Bool;

    receive(m: BlockByMaster){
        self.requireMaster();
        self.blocked = m.value;
    }

    inline fun requireNotBlocked(){
        require(!self.blocked, "Object blocked!");
    }
}