import "@stdlib/deploy";
import "./abstract/lockable-action.tact";
import "./abstract/likeable.tact";
import "./abstract/masterable.tact";
import "./user/user-ownable.tact";
import "./user/user-performable.tact";

import "./comments/commentable-object-post.tact";
message SetPostDataMessage{
    text: String;
    excessTo: Address;
}
struct PostCreateData{
    text: String;
    excessTo: Address;
}
struct PostData{
    text: String?;
    likesCount: Int as uint32;
    dislikesCount: Int as uint32;
    ownerUserId: Int as uint64;
    postId: Int as uint64;
    masterAddress: Address;
    commentsCount: Int as uint64;
}
contract UserPost with Deployable, LikeableObject, Excessable, UserOwnable, CommentableObjectPost {
    //post variables
    postId: Int as uint64;
    text: String?;

    //from user ownable
    ownerUserId: Int as uint64;
    master: Address;

    //from likeable object
    lockableAction: map<Int as uint64, Int as uint8>;
    likesCount: Int as uint32;
    dislikesCount: Int as uint32;
    // from comments
    commentsCount: Int as uint64 = 0;


    init(masterAddress: Address, ownerUserId: Int, postId: Int){
        self.ownerUserId = ownerUserId;
        self.postId = postId;
        self.likesCount = 0;
        self.dislikesCount = 0;
        self.text = null;
        self.master = masterAddress;
    }

    override inline fun getMasterAddress(): Address{
        return self.master;
    }
    override inline fun getObjectId(): Cell{
        return CommentParentPostObjectType{
            postId: self.postId,
            userOwnerId: self.ownerUserId
        }.toCell();
    }
    //TODO: COMMENT_TYPE_POST
    override const ObjectTypeId: Int = 1;

    receive(m: SetPostDataMessage){
        self.requireOwner(sender());
        self.text = m.text;
        self.excess(m.excessTo, "ok");
    }

    get fun data(): PostData{
        return PostData{
            text: self.text,
            likesCount: self.likesCount,
            dislikesCount: self.dislikesCount,
            ownerUserId: self.ownerUserId,
            masterAddress: self.master,
            postId: self.postId,
            commentsCount: self.commentsCount
        };
    }

}
