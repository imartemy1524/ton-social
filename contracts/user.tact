import "./abstract/excessable.tact";
import "./abstract/blockable.tact";
import "./abstract/masterable.tact";
import "./user/post-communicator.tact";
import "./post.tact";
//system messages
message InitUserInternal{
    owner: Address;
    excessTo: Address;
}

// getters
struct UserData{
    master: Address;
    userId: Int as uint64;
    owner: Address;
    blocked: Bool;
    lastPostId: Int as uint64;
}




const NullAddress: Address = address("UQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJKZ");


contract User with OwnableTransferable, Excessable, Blockable, PostCommunicator{
    //variables from traits
    blocked: Bool;
    master: Address;
    lastPostId: Int as uint64;
    registerDate: Int as uint64;
    //user owner address
    owner: Address;
    //user id
    userId: Int as uint64;
    init(master: Address, userId: Int){
        self.master = master;
        self.userId = userId;
        self.owner = NullAddress;
        self.blocked = false;
        self.lastPostId = 0;
        self.registerDate = 0;
    }
    receive(m: InitUserInternal){
        self.requireMaster();
        self.owner = m.owner;
        self.registerDate = now();
        self.excess(m.excessTo, beginString().concat(self.userId.toString()).concat(" initialized").toString());
    }

    get fun data(): UserData{
        return UserData {
            master: self.master,
            userId: self.userId,
            owner: self.owner,
            blocked: self.blocked,
            lastPostId: self.lastPostId
        };
    }

    override inline fun getUserId(): Int{
        return self.userId;
    }
    override inline fun requireNotBlocked1(){
        self.requireNotBlocked();
    }
}