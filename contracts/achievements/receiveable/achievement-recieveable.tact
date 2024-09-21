trait AchievementRecieveable with IUser, Ownable{
    nickname: String?;
    userId: Int;
    receivedAchievements: Int;
    achievementMinterAddress: Address;
    owner: Address;


    fun checkAchievement(send: Bool, startI: Int, now: Int): Bool{
        if send {
            require(context().value >= ton("0.13"), "Not enough funds to deploy achievement");
        }
        let i = startI;
        let valid = true;
        let powered: Int = 1;
        while(i < startI + 15 && valid){
            valid = (now >= powered);
            if(valid && self.__notYetReceivedAchievement(i)){
                if send {
                    self.__sendAchievement(i);
                }
                return true;
            }
            powered *= 10;
            i += 1;
        }
        return false;
    }
    inline fun __sendAchievement(type: Int){
        self.receivedAchievements |= (1 << (type-1));
        self.forward(
            self.achievementMinterAddress,
            ReceiveAchivement{
                achievementId: type, userId: self.userId, excessTo: self.owner }.toCell(),
                true,
                null
        );
    }

    //    receive("inc"){
    //        self.receivedAchievements = self.receivedAchievements + 1;
    //    }

    bounced(m: bounced<ReceiveAchivement>){
        //        self.receivedAchievements = self.receivedAchievements & (~(1 << (m.achievementId-1)));
        self.forward(self.owner, "error".asComment(), false, null);
    }

    inline fun __notYetReceivedAchievement(type: Int): Bool{
        return (self.receivedAchievements & (1 << (type - 1))) == 0;
    }

}