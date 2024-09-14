trait AchievementRecieveable with IUser, Ownable{
    nickname: String?;
    userId: Int;
    likesCount: Int;
    postsCount: Int;
    commentsCount: Int;
    receivedAchievements: Int;
    achievementMinterAddress: Address;
    owner: Address;

    inline fun checkPostsAchievements(send: Bool): Bool{
        if send{
            require(context().value >= ton("0.13"), "Not enough funds to deploy achievement");
        }
        let ans = self.check(ACHIVEMENT_POST_1, self.postsCount);
        if ans != -1 && send {
            self.__sendAchievement(ans);
        }
        return ans != -1;
    }
    inline fun checkCommentAchievements(send: Bool): Bool{
        if send{
            require(context().value >= ton("0.13"), "Not enough funds to deploy achievement");
        }
        let ans = self.check(ACHIVEMENT_COMMENT_1, self.commentsCount);
        if ans != -1 && send{
            self.__sendAchievement(ans);
        }
        return ans != -1;
    }
    inline fun checkLikeAchievements(send: Bool): Bool{
        if send{
            require(context().value >= ton("0.13"), "Not enough funds to deploy achievement");
        }
        let ans = self.check(ACHIVEMENT_LIKE_1, self.likesCount);
        if ans != -1 &&  send{
            self.__sendAchievement(ans);
        }
        return ans != -1;
    }
//    inline fun checkSubscribtionsAchievements(send: Bool): Bool{
//        return self.check(send, ACHIVEMENT_FOLLOWER_1, self.followersCount);
//    }

    fun check(startI: Int, now: Int): Int{
        let i = startI;
        let valid = true;
        let powered: Int = 1;
        while(i < startI + 15 && valid){
            valid = (now >= powered);
            if(valid && self.__notYetReceivedAchievement(i)){
                return i;
            }
            powered *= 10;
            i += 1;
        }
        return -1;
    }
    fun __sendAchievement(type: Int){
        dump("send...");
        dump(myAddress().toString());
        self.receivedAchievements |= (1 << (type-1));
        self.forward(
            self.achievementMinterAddress,
            ReceiveAchivement{ achievementId: type, userId: self.userId, excessTo: self.owner }.toCell(),
            true,
            null
        );
    }

//    receive("inc"){
//        self.receivedAchievements = self.receivedAchievements + 1;
//    }

    bounced(m: bounced<ReceiveAchivement>){
        dump("error");
//        self.receivedAchievements = self.receivedAchievements & (~(1 << (m.achievementId-1)));
        self.forward(self.owner, "error".asComment(), false, null);
    }

    inline fun __notYetReceivedAchievement(type: Int): Bool{
        return (self.receivedAchievements & (1 << (type - 1))) == 0;
    }

}