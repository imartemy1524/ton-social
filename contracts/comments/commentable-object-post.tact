import "../comment.tact";
message AddCommentInternalObject {
    data: CommentCreateData;
}

trait CommentableObjectPost with UserPerformable, Masterable {
    master: Address;
    commentsCount: Int;
    abstract const ObjectTypeId: Int;
    abstract inline fun getObjectId(): Cell;
    receive(m: AddCommentInternalObject) {
        self.requireSenderIsUser(m.data.fromUserId);

        self.commentsCount += 1;
        let comment: StateInit = self.getCommentAt(self.commentsCount);

        send(SendParameters{
            value: 0,
            mode: SendRemainingValue,
            to: contractAddress(comment),
            body: InternalCommentSetTextParent{data: m.data}.toCell(),
            code: comment.code,
            data: comment.data
        });

    }
    inline fun getCommentAt(id: Int): StateInit{
        return (initOf Comment(self.master, self.ObjectTypeId, self.getObjectId(), id))
    }
    get fun comment(id: Int): Address{
        let state: StateInit = self.getCommentAt(id);
        return contractAddress(state);
    }
}