trait AchievementRecieveableLikes with AchievementRecieveable{
    //system variables
    nickname: String?;
    userId: Int;
    achievementMinterAddress: Address;
    owner: Address;
    receivedAchievements: Int;

    likesCount: Int;
    inline fun checkLikeAchievements(send: Bool): Bool{
        let ans = self.checkAchievement(send, ACHIVEMENT_LIKE_1, self.likesCount);
        return ans;
    }

}