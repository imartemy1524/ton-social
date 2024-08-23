import "@stdlib/deploy";
import "./abstract/lockable-action.tact";
import "./abstract/likeable.tact";
import "./abstract/masterable.tact";
import "./user/user-ownable.tact";
import "./user/user-performable.tact";
message SetPostDataMessage{
    text: String;
    excessTo: Address;
}
struct PostData{
    text: String?;
    likesCount: Int;
    dislikesCount: Int;
    ownerUserId: Int;
    masterAddress: Address;
}

contract UserPost with Deployable, LikeableObject, Excessable, UserOwnable {
    //post variables
    postId: Int as uint64;
    text: String?;

    //from user ownable
    ownerUserId: Int as uint64;
    master: Address;

    //from likeable object
    lockableAction: map<Int as uint64, Bool>;
    likesCount: Int as uint32;
    dislikesCount: Int as uint32;

    init(masterAddress: Address, ownerUserId: Int, postId: Int){
        self.ownerUserId = ownerUserId;
        self.postId = postId;
        self.likesCount = 0;
        self.dislikesCount = 0;
        self.text = null;
        self.master = masterAddress;
    }
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
        };
    }
}
