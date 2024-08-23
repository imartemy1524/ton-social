import "../comments/comment-base.tact";
message ExternalAddCommentPost{
    postId: Int as uint64;
    postOwnerId: Int as uint64;
    comment: CommentCreateData;
}

// trait for user to send comments to different objects
trait CommentCommunicator with Ownable, Blockable, Masterable{
    owner: Address;
    master: Address;
    blocked: Bool;
    virtual const NeedFeeToCreateComment: Int = ton("0.1");
    receive(m: ExternalAddCommentPost){
        self.requireNotBlocked();
        require(context().value >= self.NeedFeeToCreateComment, "Value must be >= 0.1");
        let post = contractAddress(initOf UserPost(self.master, m.postOwnerId, m.postId));
        //we should send message to post, becuase it should increase comments count and blockchain should verify, that post exists (the post controlls the progress of crating comments)
        send(SendParameters{
            value: 0,
            mode: SendRemainingValue,
            to: post,
            body: AddCommentInternalObject{
                data: CommentCreateData{
                    text: m.comment.text,
                    excessTo: self.owner,
                    fromUserId: self.getUserId()
                }
            }.toCell()
        });

    }
}