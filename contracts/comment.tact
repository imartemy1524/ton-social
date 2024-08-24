import "./abstract/parentable.tact";


struct CommentData{
    userId: Int as uint64;
    text: String;
    date: Int as uint64;
    master: Address;
    parent: Address;
    childrenCount: Int as uint64;
}

contract Comment with CommentBase, Masterable, Parentable, LikeableObject, Commentable{
    master: Address;
    parent: Address;

    //own variables
    date: Int as uint64 = 0;
    text: String = "";
    commentId: Int as uint64;

    ownerUserId: Int as uint64 = 0;
    likes: map<Int as uint8, Int as int64>;

    //from Commentable
    commentsCount: Int as uint64 = 0;

    init(master: Address, parent: Address, commentId: Int){
        self.master = master;
        self.commentId = commentId;
        self.parent = parent;
    }
    override inline fun getMasterAddress(): Address{
        return self.master;
    }
    get fun data(): CommentData{
        return CommentData{
            userId: self.ownerUserId,
            text: self.text,
            date: self.date,
            master: self.master,
            parent: self.parent,
            childrenCount: self.commentsCount,
        };
    }

}