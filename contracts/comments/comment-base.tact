message InternalInitializeComment{
    data: CommentCreateData;
    objectOwnerUserId: Int as uint64;
}
struct CommentCreateData{
    text: String;
    fromUserId: Int as uint64;
    excessTo: Address;
}
message InternalUpdateCommentDataFromUser{
    text: String;
    excessTo: Address;
}
message ExcessFromComment{
    bob: Bool;
}

// comment data trait
trait CommentBase with Excessable, Parentable, UserOwnable{

    //own properties
    commentId: Int;
    date: Int;
    ownerUserId: Int;
    text: String;
    //parentable
    parent: Address;
    parentObjectUserOwnerId: Int;

    //this message should be received from parent (Commentable contract)
    receive(m: InternalInitializeComment){
        self.requireParentSender();
        self.ownerUserId = m.data.fromUserId;
        self.text = m.data.text;
        self.date = now();
        self.parentObjectUserOwnerId = m.objectOwnerUserId;
        self.forward(m.data.excessTo, ExcessFromComment{bob: true}.toCell(), false, null);
    }
    //this message used for updating
    receive(m: InternalUpdateCommentDataFromUser){
        self.requireOwner();
        self.text = m.text;
        self.excess(m.excessTo, "ok");
    }
//TODO: add deleting by admin functionality

}