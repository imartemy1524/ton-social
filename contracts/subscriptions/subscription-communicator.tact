import "./user-subscription-collection.tact";
struct UserSubscriptionsData{
    //how much subscriptions this user has
    toMeCount: Int as uint32 = 0;
    //how much subscriptions this user gave to other users (subscribed to them)
    fromMeCount: Int as uint32 = 0;

    levels: map<Int as uint8, SubscriptionData>;
}
message SubscriptionSetLevels{
    levels: map<Int as uint8, SubscriptionData>;
}


trait SubscriptionCommunicator with IUser, Ownable, UserPerformable, ProfitCommunicator, Exitable, Excessable, AchievementRecieveableSubscription, UserSubscriptionCollection {
    virtual const minSubscriptionFee: Int = ton("0.3");
    subscriptionsData: UserSubscriptionsData;
    nickname: String?;
    userId: Int;
    owner: Address;
    achievementMinterAddress: Address;
    profitAddress: Address;
    receivedAchievements: Int;
    avatar: String?;

    override fun subscriptionsCount(): Int{
        return self.subscriptionsData.toMeCount;
    }

    override fun collectionDescription(): String{
        return "SBT collection of subscriptions for current user.";
    }
    override fun collectionName(): String{
        return beginString().concat("User ").concat(self.nickname == null?beginString().concat("id").concat(self.userId.toString()).toString():self.nickname!!).concat(" subscriptions").toString();
    }

    // wallet -> (owner user contract) -> (subscription user contract) (reserves amount) -> (subscription contract) -> (global profit contract) -> excess
    receive(m: ExternalSubscribeToUser){
        self.requireOwner();
        require(m.subscribeToUserId != self.userId, "can't subscribe to yourself");
        require(context().value >= self.minSubscriptionFee, "not enough funds to subscribe");
        self.forward(
            self.userContractAddress(m.subscribeToUserId),
            InternalStartSubscription{
                fromUserId: self.userId,
                level: m.level,

            }.toCell(),
            true,
            null
        );
        self.exitWithoutSaving();
    }

    receive(m: InternalStartSubscription){
        self.requireSenderIsUser(m.fromUserId);
        let level = self.subscriptionsData.levels.get(m.level);
        require(level != null, "level not found");
        require(context().value >= level!!.paymentAmount + self.minSubscriptionFee, "not enough funds to subscribe");
        let subsription = self.getMySubscription(m.fromUserId);
        self.subscriptionsData.toMeCount += 1;
        //save 99% of the amount to this account
        nativeReserve(level!!.paymentAmount * 99/100, ReserveExact | ReserveAddOriginalBalance );
        send(SendParameters{
            to: contractAddress(subsription),
            value: 0,
            bounce: true,
            mode: SendRemainingBalance,
            body: SubscriptionInit{
                data: level!!,
                userFromId: m.fromUserId,
                profitAddress: self.profitAddress
            }.toCell(),
            data: subsription.data,
            code: subsription.code
        });
    }
    receive(m: ExcessFromProfitSubscription){
        require(sender() == self.profitAddress, "Not a profit contract");
        require(m.success, "Profit failed");
        self.subscriptionsData.fromMeCount += 1;
        if(!self.checkSubscriptionAchievements(true)){
            self.excess(self.owner, "ok");
        }
    }
    bounced(b: bounced<SubscriptionInit>){
        //excess to original sender on bounce
        self.forward(
            self.userContractAddress(b.userFromId),
            "error".asComment(),
            false,
            null
        );
    }
    fun getSubscription(userToId: Int, userFromId: Int): StateInit{
        return initOf Subscription(self.getMasterAddress(), userFromId, userToId);
    }
    inline fun getMySubscription(userFromId: Int): StateInit{
        return self.getSubscription(self.userId, userFromId);
    }


    //levels setter
    override fun at(index: Int): Address{
        return contractAddress(self.getMySubscription(index));
    }
    receive(m: SubscriptionSetLevels){
        self.requireOwner();
        self.subscriptionsData.levels = m.levels;
    }
}
