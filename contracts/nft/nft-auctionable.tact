
struct Bid{
    owner: Address;
    amount: Int as coins;
}
message BidMessage{
    bid: Bid;
}
message ExcessFromBid{
    flag: Bool;
}
struct AuctionData{
    lastBid: Bid?;
    endDate: Int as uint64;
}
message EndAuctionMessage{}

trait NftAuctionable with Masterable{
    auctionEndDate: Int;
    lastBid: Bid?;
    master: Address;
    owner: Address?;
    virtual const BidStep: Int = ton("0.5");
    virtual const Fee: Int = ton("0.04");
    fun startAuction(startAmount: Int, owner: Address){
        require(self.lastBid == null, "Already initialized");
        self.auctionEndDate = now() + 3600;
        self.lastBid = Bid{owner, amount: startAmount};
    }
    receive(m: BidMessage){
        require(self.auctionEndDate != 0 && self.lastBid != null, "Auction not started yet!");
        require(context().value - self.Fee >= max(m.bid.amount, self.lastBid!!.amount + self.BidStep), "Invalid amount sent");
        require(now() < self.auctionEndDate, "Auction ended");
        self.releasePreviousBid();
        self.lastBid = m.bid;
        // + 10 minutes
        self.auctionEndDate += 60 * 10;
    }

    receive(m: EndAuctionMessage){
        require(self.lastBid != null, "No bids found");
        require(sender() == self.lastBid!!.owner, "Invalid sender!");
        require(now() >= self.auctionEndDate, "Auction not yet ended!");
        self.owner = self.lastBid!!.owner;
        self.auctionEndDate = 0;
        self.lastBid = null;
        nativeReserve(self.storageReserve, ReserveExact);
        send(SendParameters{bounce: false, to: self.master, value: 0, mode: SendRemainingBalance | SendIgnoreErrors, body: ExcessFromBid{flag: true}.toCell()});
    }

    inline fun releasePreviousBid(){
        send(SendParameters{
            to: self.lastBid!!.owner,
            value: self.lastBid!!.amount,
            mode: SendPayGasSeparately,
            body: null
        });
    }

}