import "./sender.tact";
// Public structs
struct LikeValue{
    //islike = true - like, false - dislike
    // char=0, char=1 - like, char=2 - dislike
    char: Int as uint8;
}
struct SingleLikeData{
    likeValue: LikeValue;
    date: Int as uint64;
    to: Address;
    userId: Int as uint64;
}

// Internal messages
message SetLikeInternal {
    value: LikeValue;
    excessTo: Address;
}

message SetLikeInternalNotification {
    excessTo: Address;
    userId: Int as uint64;
    oldValue: LikeValue;
    newValue: LikeValue;
}
message SetLikeSuccess{
    excessTo: Address;
    newValue: LikeValue;
}
message ExcessFromLike{success: Bool;}


// Main trait for likeable objects (which can be liked).
// Likes should be added from main user contract, which DEPLOYS UserLike contracts for each user.

trait LikeableObject with Excessable{

    // liketype -> count
    likes: map<Int as uint8, Int as int64>;

    /// ---
    /// Public functions
    /// ---
    receive(m: SetLikeInternalNotification){
        self.requireLikeSender(m.userId);
        if(m.oldValue.char != 0){
            self.likes.set(m.oldValue.char, self.likes.get(m.oldValue.char)!!-1);
        }
        if(m.newValue.char != 0){
            let oldValue: Int? = self.likes.get(m.newValue.char) ;
            self.likes.set(m.newValue.char, (oldValue == null ? 0 : oldValue!!)+1);
        }
        self.reply(SetLikeSuccess{
            excessTo: m.excessTo,
            newValue: m.newValue
        }.toCell());
    }
    inline fun requireLikeSender(keySignature: Int){
        require(sender() == contractAddress(initOf UserLike(self.getMasterAddress(), myAddress(), keySignature)), "Sender is not a child element");
    }

    get fun like(userId: Int): Address{
        let data: StateInit = initOf UserLike(self.getMasterAddress(), myAddress(), userId);
        return contractAddress(data);
    }
    virtual inline fun getMasterAddress(): Address{
        require(false, "Not implemented");
        return NullAddress;
    }
    inline fun likesValues(): map<Int as uint8, Int as int64>{
        let ans = self.likes;
        foreach(key, value in ans){
            if(value == 0 || key == 0){
                ans.del(key);
            }
        }
        return ans;
    }

}


contract UserLike with Blockable, UserOwnable{
    //block object to prevent double messages
    blocked: Bool = false;
    master: Address;
    ownerUserId: Int as uint64;
    value: LikeValue;
    // local master - Likeable object
    toObject: Address;
    lastEdit: Int as uint64 = 0;
    init(master: Address, toObject: Address, owner: Int){
        self.toObject = toObject;
        self.ownerUserId = owner;
        self.value = LikeValue{char: 0};
        self.master = master;
    }

    receive(m: SetLikeInternal){
        self.requireOwner();
        self.requireNotBlocked();
        require(self.value.char != m.value.char, "You can't like twice");
        self.blocked = true;
        self.forward(
            self.toObject,
            SetLikeInternalNotification{
                userId: self.ownerUserId,
                oldValue: self.value,
                newValue: m.value,
                excessTo: m.excessTo
            }.toCell(),
            true,
            null
        );
    }
    receive(m: SetLikeSuccess){
        self.requireFromObject();
        self.value = m.newValue;
        self.blocked = false;
        self.lastEdit = now();
        self.forward(m.excessTo, ExcessFromLike{success: true}.toCell(), false, null);
    }
    bounced(m: bounced<SetLikeInternalNotification>){
        //Very sad, you're baka, the contract doesn't exists, or you've passed invalid address, or contract doesn't accept likes.
        //But if there is situation, that it just don't yet exists, but it would exists in future - we should unblock actions
        self.blocked = false;
    }

    inline fun requireFromObject(){
        require(sender() == self.toObject, "Only object can call this callback function");
    }
    get fun value(): SingleLikeData{
        return SingleLikeData{
            likeValue: self.value,
            date: self.lastEdit,
            to: self.toObject,
            userId: self.ownerUserId
        };
    }
    override inline fun getMasterAddress(): Address{
        return self.master;
    }


}
