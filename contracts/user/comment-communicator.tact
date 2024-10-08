import "../comments/comment-base.tact";
message ExternalAddComment{
    text: String;
    //Parentable object address
    parentAddress: Address;
}
message ExternalModifyComment{
    text: String;
    //BaseComment object address
    commentAddress: Address;
}
// trait for user to send comments to different objects
trait CommentCommunicator with Ownable, Blockable, Masterable, Exitable, AchievementRecieveableComment{
    //variables from achievementRecieveable
    nickname: String?;
    userId: Int;
    receivedAchievements: Int;
    achievementMinterAddress: Address;
    //own variables
    owner: Address;
    master: Address;
    commentsCount: Int;
    blocked: Bool;
    virtual const NeedFeeToCreateComment: Int = ton("0.22");
    receive(m: ExternalAddComment){
        self.requireNotBlocked();
        self.requireOwner();
        require(context().value >= self.NeedFeeToCreateComment, "Value must be >= 0.22");
        self.validateCommentData(m.text);
        self.commentsCount += 1;
        //we should send message to post, becuase it should increase comments count and blockchain should verify, that post exists (the post controlls the progress of crating comments)
        self.forward(
            m.parentAddress,
            AddCommentInternalObject{
                data: CommentCreateData{
                    text: m.text,
                    excessTo: self.checkCommentAchievements(false) ? (myAddress()) : self.owner,
                    fromUserId: self.getUserId()
                }
            }.toCell(), true, null
        );
    }
    bounced(m: bounced<AddCommentInternalObject>){
        self.commentsCount -= 1;
        self.forward(self.owner, "error".asComment(), false, null);
    }
    receive(m: ExternalModifyComment){
        self.requireNotBlocked();
        self.requireOwner();
        require(context().value >= self.NeedFeeToCreateComment, "Value must be >= 0.22");
        self.validateCommentData(m.text);
        self.forward(
            m.commentAddress,
            InternalUpdateCommentDataFromUser{
                text: m.text,
                excessTo: self.owner
            }.toCell(),
            true,
            null
        );
        self.exitWithoutSaving();
    }
    receive(m: ExcessFromComment){
        self.requireNotBlocked();
        self.checkCommentAchievements(true);
    }

    inline fun validateCommentData(m: String){
        let lengthBytes = m.asSlice().bits() / 8;
        require(lengthBytes >= 1 && lengthBytes <= 10_000, "Message too long!");
    }
    abstract inline fun getUserId(): Int;

}