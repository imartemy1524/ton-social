import "@stdlib/deploy";
import "./abstract/lockable-action.tact";
import "./abstract/likeable.tact";
import "./abstract/masterable.tact";
import "./user/user-ownable.tact";
import "./user/user-performable.tact";

import "./comments/commentable.tact";
message SetPostDataMessage{
    text: String;
    excessTo: Address;
}
struct PostData{
    text: String;
    likes: map<Int as uint8, Int as int64>;
    postId: Int as uint64;
    ownerUserId: Int as uint64;
    commentsCount: Int as uint64;
    master: Address;
    date: Int as uint64;
}
//sources of user post contract. Only user can communicate with this contract through his own contract (User)
contract UserPost with LikeableObject, Excessable, Commentable, UserOwnable {
    override const storageReserve: Int = ton("0.02");

    //post variables
    postId: Int as uint64;
    text: String = "";
    date: Int as uint64 = 0;

    master: Address;

    //from user ownable
    ownerUserId: Int as uint64;

    //from likeable object
    likes: map<Int as uint8, Int as int64>;

    // from comments
    commentsCount: Int as uint64 = 0;


    init(masterAddress: Address, ownerUserId: Int, postId: Int){
        self.ownerUserId = ownerUserId;
        self.postId = postId;
        self.master = masterAddress;
    }

    override inline fun getMasterAddress(): Address{
        return self.master;
    }

    receive(m: SetPostDataMessage){
        self.requireSenderIsUser(self.ownerUserId);
        self.text = m.text;
        if(self.date == 0){
            self.date = now();
        }
        self.excess(m.excessTo, "ok");
    }

    get fun data(): PostData{
        return PostData{
            text: self.text,
            likes: self.likesValues(),
            ownerUserId: self.ownerUserId,
            master: self.master,
            postId: self.postId,
            commentsCount: self.commentsCount,
            date: self.date
        };
    }

    override inline fun getObjectOwnerUserId(): Int{
        return self.ownerUserId;
    }
    override inline fun requireInitialized(){
        require(self.date != 0, "Post is not initialized");
    }

}
