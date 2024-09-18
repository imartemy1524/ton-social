trait AchievementRecieveableComment with AchievementRecieveable{
    //system variables
    nickname: String?;
    userId: Int;
    achievementMinterAddress: Address;
    owner: Address;
    receivedAchievements: Int;

    commentsCount: Int;
    inline fun checkCommentAchievements(send: Bool): Bool{
        let ans = self.checkAchievement(send, ACHIVEMENT_COMMENT_1, self.commentsCount);
        return ans;
    }

}