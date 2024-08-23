// Public structs
struct LikeValue{
    //islike = true - like, false - dislike
    isLike: Bool;
}
struct SingleLikeData{
    likeValue: LikeValue?;
    date: Int as uint64;
}

// Internal messages within other system contracts for communication

message UserInternalAddLikeOrDislike {
    userId: Int as uint64;
    like: LikeValue;
    owner: Address;
}
message UserInternalRemoveLikeOrDislike{
    userId: Int as uint64;
    owner: Address;
}

// Internal messages
message SetLikeInternal {
    value: LikeValue;
    excessTo: Address;
}
message DeleteLikeInternal {
    excessTo: Address;
}
message PongSetLikeInternal {
    keySignature: Int as uint64;
    oldValue: LikeValue?;
    newValue: LikeValue;
    excessTo: Address;
}
message PongDeleteLikeInternal {
    keySignature: Int as uint64;
    oldValue: LikeValue?;
    excessTo: Address;
}



// Main trait for likeable objects (which can be liked).
// Likes should be added from main user contract

trait LikeableObject with LockableAction, UserPerformable, Excessable{
    // from base traits
    master: Address;
    lockableAction: map<Int as uint64, Int as uint8>;

    //own variables
    likesCount: Int;
    dislikesCount: Int;

    /// ---
    /// Public functions
    /// ---
    receive(m: UserInternalAddLikeOrDislike){
        self.requireSenderIsUser(m.userId);
        self.requireNotLocked(m.userId);
        //locking for each action, because they are done in async
        self.lock(m.userId);
        //set value
        self.setValue(m.userId, m.like, m.owner);
    }
    receive(m: UserInternalRemoveLikeOrDislike){
        self.requireSenderIsUser(m.userId);
        self.requireNotLocked(m.userId);

        //locking for each action, because they are done in async
        self.lock(m.userId);
        self.deleteValue(m.userId, m.owner);
    }
    /// ---
    /// Public functions end
    /// ---



    /// ---
    /// Working with async map
    // ---

    //send message to child element, to set value
    fun setValue(key: Int, value: LikeValue, owner: Address){
        let b = initOf UserLike(myAddress(), key);
        send(SendParameters{
            value: 0,
            mode: SendRemainingValue,
            body: SetLikeInternal{
                value: value,
                excessTo: owner
            }.toCell(),
            to: contractAddress(b),
            data: b.data,
            code: b.code,
        });
    }
    fun deleteValue(key: Int, owner: Address){
        let b = initOf UserLike(myAddress(), key);
            send(SendParameters{
                value: 0,
                mode: SendRemainingValue,
                body: DeleteLikeInternal{excessTo: owner}.toCell(),
                to: contractAddress(b),
                data: b.data,
                code: b.code,
            });
    }

    receive(m: PongDeleteLikeInternal){
        self.requireLikeSender(m.keySignature);
        self.handleResponseRemoveLike(m.oldValue, m.keySignature, m.excessTo);
    }
    receive(m: PongSetLikeInternal){
        self.requireLikeSender(m.keySignature);
        self.handleResponseSetLike(m.oldValue, m.newValue, m.keySignature, m.excessTo);
    }
    inline fun requireLikeSender(keySignature: Int){
        require(sender() == contractAddress(initOf UserLike(myAddress(), keySignature)), "Sender is not a child element");
    }

    get fun user_like(userId: Int): Address{
        let data: StateInit = initOf UserLike(myAddress(), userId);
        return contractAddress(data);
    }

    /// ----
    /// Handlers
    /// ----

    //handling like set
    inline fun handleResponseSetLike(oldValue: LikeValue?, newValue: LikeValue, userId: Int, userOwner: Address){
        self.unlock(userId);
        if(oldValue == null){
            if(newValue.isLike){
                self.likesCount += 1;
            }
            else{
                self.dislikesCount += 1;
            }
        }
        else if(oldValue!!.isLike && !newValue.isLike){
            self.likesCount -= 1;
            self.dislikesCount += 1;
        }
        else if(!oldValue!!.isLike && newValue.isLike){
            self.likesCount += 1;
            self.dislikesCount -= 1;
        }
        else {
            self.excess(userOwner, "Error: already has like/dislike");
            return;
        }
        self.excess(userOwner, newValue.isLike ? "Like added": "Dislike added");
    }

    //succesfully deleted like
    inline fun handleResponseRemoveLike(oldValue: LikeValue?, userId: Int, userOwner: Address){
        if(oldValue == null){
            self.unlock(userId);
            self.excess(userOwner, "Error: no like/dislike to remove");
            return;
        }
        if(oldValue!!.isLike){
            self.likesCount -= 1;
        }
        else {
            self.dislikesCount -= 1;
        }
        self.unlock(userId);
        self.excess(userOwner, oldValue!!.isLike?"Like removed": "Dislike removed");
    }


    /// ----
    /// Handlers end
    /// ----

    /// ---
    /// Working with async map end
    /// ---


}


contract UserLike{
    ownerUserId: Int as uint64;
    value: LikeValue?;
    // local master - Likeable object
    master: Address;
    last_edit: Int as uint64;
    init(master: Address, owner: Int){
        self.master = master;
        self.ownerUserId = owner;
        self.value = null;
        self.last_edit = 0;
    }

    receive(m: SetLikeInternal){
        self.requireMaster();
        let oldValue: LikeValue? = self.value;
        self.value = m.value;
        self.last_edit = now();
        self.pong(
            PongSetLikeInternal{
                keySignature: self.ownerUserId,
                oldValue,
                newValue: m.value,
                excessTo: m.excessTo
            }.toCell(),
            SendRemainingValue
        );

    }
    receive(m: DeleteLikeInternal){
        self.requireMaster();
        let oldValue: LikeValue? = self.value;
        self.value = null;
        self.pong(
            PongDeleteLikeInternal{
                keySignature: self.ownerUserId,
                oldValue,
                excessTo: m.excessTo
            }.toCell(),
            SendRemainingBalance|SendDestroyIfZero
        );
    }

    fun requireMaster(){
        require(sender() == self.master, "Only master can call this function");
    }

    fun pong(m: Cell, mode: Int){
        send(SendParameters{
            value: 0,
            mode,
            body: m,
            to: self.master
        });
    }


    get fun value(): SingleLikeData{
        return SingleLikeData{
            likeValue: self.value,
            date: self.last_edit
        };
    }
}
