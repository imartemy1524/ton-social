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
trait CommentCommunicator with Ownable, Blockable, Masterable{
    owner: Address;
    master: Address;
    blocked: Bool;
    virtual const NeedFeeToCreateComment: Int = ton("0.1");
    receive(m: ExternalAddComment){
        self.requireNotBlocked();
        self.requireOwner();
        require(context().value >= self.NeedFeeToCreateComment, "Value must be >= 0.1");
        self.validateCommentData(m.text);
        //we should send message to post, becuase it should increase comments count and blockchain should verify, that post exists (the post controlls the progress of crating comments)
        send(SendParameters{
            value: 0,
            mode: SendRemainingValue,
            to: m.parentAddress,
            body: AddCommentInternalObject{
                data: CommentCreateData{
                    text: m.text,
                    excessTo: self.owner,
                    fromUserId: self.getUserId()
                }
            }.toCell()
        });
    }
    receive(m: ExternalModifyComment){
        self.requireNotBlocked();
        self.requireOwner();
        require(context().value >= self.NeedFeeToCreateComment, "Value must be >= 0.1");
        self.validateCommentData(m.text);
        send(SendParameters{
            value: 0,
            mode: SendRemainingValue,
            to: m.commentAddress,
            body: InternalUpdateCommentDataFromUser{
                text: m.text,
                excessTo: self.owner
            }.toCell()
        });
    }

    inline fun validateCommentData(m: String){
        let lengthBytes = m.asSlice().bits() / 8;
        require(lengthBytes >=1 && lengthBytes <= 10_000, "Invalid length!");
    }
    abstract inline fun getUserId(): Int;

}