message InitizlizeNickname{
    nickname: String;
    owner: Address;
}

contract NicknamesCollectionItem with DnsItem, DnsNftItem{
    master: Address;
    owner: Address = address("UQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJKZ");
    nickname: String = "";
    linked: Bool = false;
    init(collection: Address, nicknameHash: Int){
        self.master = collection;
    }

    receive(m: InitizlizeNickname){
        self.requireMaster();
        self.nickname = m.nickname;
    }


}

