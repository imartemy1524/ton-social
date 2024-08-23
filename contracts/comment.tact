const COMMENT_TYPE_POST: Int = 1;
const COMMENT_TYPE_COMMENT: Int = 2;

struct CommentParentPostObjectType{
    postId: Int as uint64;
    userOwnerId: Int as uint64;
}
struct CommentParentCommentObjectType{
    objectType: Int;
    objectId: Cell;
    commentId: Int;
}

contract Comment with CommentBase, Masterable{
    date: Int as uint64;
    master: Address;
    objectId: Cell;
    objectType: Int as uint8;
    text: String;
    commentId: Int as uint64;
    userOwnerId: Int as uint64;
    lockableAction: map<Int as uint64, Int as uint8>;
    likesCount: Int as uint32 = 0;
    dislikesCount: Int as uint32 = 0;


    init(master: Address, objectType: Int, objectId: Cell, commentId: Int){
        self.master = master;
        self.objectType = objectType;
        self.objectId = objectId;
        self.commentId = commentId;
        self.date = now();
        self.userOwnerId = 0;
        self.text = "";
    }


    override inline fun getParentObjectAddress(): Address{
        if(self.objectType == COMMENT_TYPE_POST){
            let slice: CommentParentPostObjectType = CommentParentPostObjectType.fromCell(self.objectId);
            let commentParentState = (initOf UserPost(self.master, slice.userOwnerId, slice.postId));
            return contractAddress(commentParentState);
        }
        else if(self.objectType == COMMENT_TYPE_COMMENT){
            let slice: CommentParentCommentObjectType = CommentParentCommentObjectType.fromCell(self.objectId);
            let commentParentState = (initOf Comment(self.master, slice.objectType, slice.objectId, slice.commentId));
            return contractAddress(commentParentState);
        }
        else{
            require(false, "Unknown object type");
            return NullAddress;
        }
    }
}