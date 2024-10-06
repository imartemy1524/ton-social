
message ChangeAvatar {
    avatar: String?;
}

trait AvatarChanger with Ownable, Excessable {
    owner: Address;
    avatar: String? = null;
    receive(m: ChangeAvatar){
        self.requireOwner();
        self.avatar = m.avatar;
        self.excess(self.owner, "ok");
    }

}