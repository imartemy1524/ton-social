import "./DNS/dns-item.tact";
import "./DNS/types.tact";
struct InitizlizeNickname{
    nickname: String;
    owner: Address;
}

contract NicknamesCollectionItem with DnsItem, DnsNftItem{
    master: Address;
    owner: Address;
    nickname: String = "";
    init(collection: Address, nicknameHash: Int){
        self.master = collection;
    }

    receive(m: InitizlizeNickname){
        self.requireMaster();
        self.nickname = m.nickname;
        self.owner = address("UQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJKZ");
    }


}

