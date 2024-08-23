
struct InternalCommentSetText{

}
struct CommentData{
    userId: Int as uint64;
    text: String;
    date: Int as uint64;
}

trait CommentBase with LikeableObject{
    //answering comment ID
    date: Int;
    parentCommentId: Int;
    objectId: Int;
    answersCount: Int;
    abstract fun requireParentSender();
    abstract fun getParentAddress(): Address;

    fun parent(): Address{
        let data: StateInit = initOf Commentable(self.getParentAddress(), self.objectId);
        return contractAddress(data);
    }
    receive(m: InternalCommentSetText){
        self.date = now();
        self.requireParentSender();
        self.text = m.text;
    }



}