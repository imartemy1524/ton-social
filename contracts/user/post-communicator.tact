//liking
message UserAddLikePost{
    postId: Int as uint64;
    ownerUserId: Int as uint64;
    isLike: LikeValue;
}
message UserRemoveLikePost{
    postId: Int as uint64;
    ownerUserId: Int as uint64;
}
//post messages
message UserUpdateTextPost{
    postId: Int as uint64;
    text: String;
}
message UserCreatePost{
    text: String;
}

//trait, that allows object to create posts, like it, change post text
trait PostCommunicator with Ownable, Masterable, Blockable{
    virtual const MinPostFee: Int = ton("0.1");
    lastPostId: Int;
    owner: Address;
    master: Address;
    blocked: Bool;

    receive(m: UserCreatePost){
        self.requireOwner();
        self.requirePostFee();
        self.requireNotBlocked();
        self.lastPostId += 1;
        let post: StateInit = initOf UserPost(self.master, self.getUserId(), self.lastPostId);
        send(SendParameters{
            to: contractAddress(post),
            value: 0,
            mode: SendRemainingValue,
            body: SetPostDataMessage{text: m.text, excessTo: self.owner}.toCell(),
            code: post.code,
            data: post.data
        });
    }
    receive(m: UserUpdateTextPost){
        self.requireOwner();
        self.requirePostFee();
        self.requireNotBlocked();
        require(self.lastPostId >= m.postId, "Post not found");
        let post: StateInit = initOf UserPost(self.master, self.getUserId(), m.postId);
        send(SendParameters{
            to: contractAddress(post),
            value: 0,
            mode: SendRemainingValue,
            body: SetPostDataMessage{text: m.text, excessTo: self.owner}.toCell()
        });
    }
    receive(m: UserAddLikePost){
        self.requireOwner();
        self.requirePostFee();
        self.requireNotBlocked();
        let post: StateInit = initOf UserPost(self.master, m.ownerUserId, m.postId);
        send(SendParameters{
            to: contractAddress(post),
            value: 0,
            mode: SendRemainingValue,
            body: SetLikeInternal{value: m.isLike}.toCell()
        });
    }

    inline abstract fun getUserId(): Int;

    get fun post(postId: Int): Address{
        let data: StateInit = initOf UserPost(self.master, self.getUserId(), postId);
        return contractAddress(data);
    }
    inline fun requirePostFee(){
        require(context().value >= self.MinPostFee, "Please send at least 0.1 ton to continue");
    }
}