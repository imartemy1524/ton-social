import "../comment.tact";
message AddCommentInternalObject {
    data: CommentCreateData;
}

//IMPORTANT!!!! Override virtual getMasterAddress() function from contract code!!!
trait Commentable with UserPerformable {
    commentsCount: Int;
    receive(m: AddCommentInternalObject) {
        self.requireSenderIsUser(m.data.fromUserId);

        self.commentsCount += 1;
        let comment: StateInit = self.getCommentAt(self.commentsCount);

        send(SendParameters{
            value: 0,
            mode: SendRemainingValue,
            to: contractAddress(comment),
            body: InternalInitializeComment{data: m.data}.toCell(),
            code: comment.code,
            data: comment.data
        });

    }
    inline fun getCommentAt(id: Int): StateInit{
        return initOf Comment(self.getMasterAddress(), myAddress(), id);
    }
    get fun childComment(id: Int): Address{
        let state: StateInit = self.getCommentAt(id);
        return contractAddress(state);
    }
}