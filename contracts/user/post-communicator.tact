//post messages
message UserUpdateTextPost{
    postId: Int as uint64;
    text: String;
}
message UserCreatePost{
    text: String;
}

//trait, that allows object to create posts, like it, change post text
trait PostCommunicator with Ownable, Masterable, Blockable, AchievementRecieveable, Exitable{
    virtual const MinPostFee: Int = ton("0.2");

    //from achievements minter
    nickname: String?;
    likesCount: Int;
    receivedAchievements: Int;
    achievementMinterAddress: Address;

    //own (almost) variables
    postsCount: Int;
    commentsCount: Int;
    owner: Address;
    master: Address;
    blocked: Bool;
    userId: Int;

    receive(m: UserCreatePost){
        self.requireOwner();
        self.requirePostFee();
        self.requireNotBlocked();
        self.postsCount += 1;
        let post: StateInit = initOf UserPost(self.master, self.userId, self.postsCount);
        send(SendParameters{
            to: contractAddress(post),
            value: 0,
            mode: SendRemainingValue,
            // if one needs to deploy SBT after creating a post - then we need to receive "excess" message from post back to this contract
            body: SetPostDataMessage{text: m.text, excessTo: self.checkPostsAchievements(false) ? myAddress(): self.owner}.toCell(),
            code: post.code,
            data: post.data
        });
    }
    receive(m: UserUpdateTextPost){
        self.requireOwner();
        self.requirePostFee();
        self.requireNotBlocked();
        require(self.postsCount >= m.postId, "Post not found");
        let post: StateInit = initOf UserPost(self.master, self.userId, m.postId);
        send(SendParameters{
            to: contractAddress(post),
            value: 0,
            mode: SendRemainingValue,
            body: SetPostDataMessage{text: m.text, excessTo: self.owner}.toCell()
        });
        self.exitWithoutSaving();
    }

    receive(m: ExcessFromPost){
        //send post achievement
        self.checkPostsAchievements(true);
    }
    get fun post(postId: Int): Address{
        let data: StateInit = initOf UserPost(self.master, self.userId, postId);
        return contractAddress(data);
    }
    inline fun requirePostFee(){
        require(context().value >= self.MinPostFee, "Please send at least 0.1 ton to continue");
    }
}