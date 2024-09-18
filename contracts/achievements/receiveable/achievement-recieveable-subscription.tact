trait AchievementRecieveableSubscription with AchievementRecieveable{
    //system variables
    nickname: String?;
    userId: Int;
    achievementMinterAddress: Address;
    owner: Address;
    receivedAchievements: Int;

    subscriptionsData: UserSubscriptionsData;

    inline fun checkSubscriptionAchievements(send: Bool): Bool{
        let ans = self.checkAchievement(send, ACHIVEMENT_FOLLOWER_1, self.subscriptionsData.fromMeCount);
        return ans;
    }

}