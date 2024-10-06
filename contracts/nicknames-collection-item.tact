message InitializeNickname{
    nickname: String;
    owner: Address;
    amount: Int as coins;
}
struct DomainData{
    auction: AuctionData;
    owner: Address?;
    master: Address;
    linked: Bool;
    nickname: String;
}

contract NicknamesCollectionItem with DnsItem, DnsNftItem, NftAuctionable{
    master: Address;
    owner: Address? = null;
    nickname: String = "";
    linked: Bool = false;
    auctionEndDate: Int as uint64 = 0;
    lastBid: Bid?;

    override const storageReserve: Int = ton("0.05");

    init(collection: Address, nicknameHash: Int){
        self.master = collection;
    }

    receive(m: InitializeNickname){
        self.requireMaster();
        require(self.auctionEndDate == 0, "Already started!");
        require(self.owner == null, "Owner already set!");
        require(context().value > m.amount, "Not enough funds sent");
        self.nickname = m.nickname;
        if(m.amount == 0){
            self.owner = m.owner;
        }
        else{
            self.startAuction(m.amount, m.owner);
        }
    }
    override inline fun doesExists(): Bool{
        return self.nickname != "";
    }

    override inline fun isInitialized(): Bool{
        return self.owner != null;
    }


    get fun data(): DomainData{
        return DomainData{
            auction: AuctionData{
                lastBid: self.lastBid,
                endDate: self.auctionEndDate
            },
            owner: self.owner,
            master: self.master,
            linked: self.linked,
            nickname: self.nickname
        };
    }


}

