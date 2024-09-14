import "../abstract/likeable.tact";
message UserAddLike{
    to: Address;
    isLike: LikeValue;
}


trait LikeAdderCommunicator with Masterable, Ownable, AchievementRecieveable{
    //fields from AchievemenetRecieveable
    nickname: String?;
    userId: Int;
    postsCount: Int;
    receivedAchievements: Int;
    achievementMinterAddress: Address;
    commentsCount: Int;

    //own fields
    likesCount: Int;
    master: Address;
    owner: Address;

    virtual const MinLikeFee: Int = ton("0.1");
    //Adds like to (Contract(m.to) instanceof LikeableObject)
    receive(m: UserAddLike){
        self.requireOwner();
        require(context().value >= self.MinLikeFee, "Value must be >= 0.1");
        let to: StateInit = initOf UserLike(self.master, m.to, self.getUserId());
        self.likesCount = self.likesCount + 1;
        self.forward(
            contractAddress(to),
            SetLikeInternal{
                value: m.isLike,
                excessTo: self.checkLikeAchievements(false) ? myAddress() : self.owner
            }.toCell(),
            true,
            to
        );
    }
    bounced(m: bounced<UserAddLike>){
        self.likesCount = self.likesCount - 1;
        self.forward(
            self.owner,
            "error".asComment(),
            false,
            null
        );
    }
    receive(m: ExcessFromLike){
        self.checkLikeAchievements(true);
    }
    abstract inline fun getUserId(): Int;
}