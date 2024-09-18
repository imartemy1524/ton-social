trait AchievementRecieveablePost with AchievementRecieveable{
    nickname: String?;
    userId: Int;
    achievementMinterAddress: Address;
    owner: Address;
    receivedAchievements: Int;

    postsCount: Int;
    inline fun checkPostsAchievements(send: Bool): Bool{
        let ans= self.checkAchievement(send, ACHIVEMENT_POST_1, self.postsCount);
        return ans;
    }
}