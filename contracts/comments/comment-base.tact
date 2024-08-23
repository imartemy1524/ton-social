message InternalCommentSetTextParent{
    data: CommentCreateData;
}
struct CommentCreateData{
    text: String;
    fromUserId: Int as uint64;
    excessTo: Address;
}
struct CommentData{
    userId: Int as uint64;
    text: String;
    date: Int as uint64;
    master: Address;
    objectType: Int as uint8;
    parentAddress: Address;
}

trait CommentBase with LikeableObject, Excessable{
    //from likeable object
    lockableAction: map<Int as uint64, Int as uint8>;
    likesCount: Int;
    dislikesCount: Int;
    master: Address;
    //own properties
    commentId: Int;
    date: Int;
    userOwnerId: Int;
    objectType: Int;
    text: String;
    //    answersCount: Int;
    inline fun requireParentSender(){
        require(sender() == self.getParentObjectAddress(), "Only object parent can send messages to it");
    }
    abstract inline fun getParentObjectAddress(): Address;

    receive(m: InternalCommentSetTextParent){
        self.requireParentSender();
        self.userOwnerId = m.data.fromUserId;
        self.text = m.data.text;
        self.excess(m.data.excessTo, "ok");
    }
    get fun data(): CommentData{
        return CommentData{
            userId: self.userOwnerId,
            text: self.text,
            date: self.date,
            master: self.master,
            objectType: self.objectType,
            parentAddress: self.getParentObjectAddress()
        };
    }


}