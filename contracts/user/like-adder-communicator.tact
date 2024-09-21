import "../abstract/likeable.tact";
message UserAddLike{
    to: Address;
    isLike: LikeValue;
}


trait LikeAdderCommunicator with Masterable, Ownable, AchievementRecieveableLikes, Blockable{
    //fields from AchievemenetRecieveable
    nickname: String?;
    userId: Int;
    receivedAchievements: Int;
    achievementMinterAddress: Address;
    blocked: Bool;

    //own fields
    likesCount: Int;
    master: Address;
    owner: Address;

    virtual const MinLikeFee: Int = ton("0.2");
    //Adds like to (Contract(m.to) instanceof LikeableObject)
    receive(m: UserAddLike){
        self.requireNotBlocked();
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
        self.requireNotBlocked();
        self.checkLikeAchievements(true);
    }
    abstract inline fun getUserId(): Int;
}