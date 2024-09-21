
import "../nft-auctionable.tact";

trait DnsNftItem {
    owner: Address?;
    nickname: String;
    master: Address;
    const ComputeFee: Int = ton("0.011");
    receive(msg: Transfer){
        require(self.owner != null && sender() == self.owner!!, "Only owner or master can transfer this NFT");
        let ctx = context(); // Reference: https://docs.tact-lang.org/language/ref/common#context

        self.owner = msg.new_owner;  // change current owner to the new_owner
        //f@cking work with comissions... IDK, how it works
        let msgValue: Int = self.msgValue(ctx.value);
        if (msg.forward_amount > 0) {
            send(SendParameters{
                to: msg.new_owner,
                value: msg.forward_amount,
                mode: SendPayGasSeparately,
                bounce: true,
                body: OwnershipAssigned{
                    query_id: msg.query_id,
                    prev_owner: ctx.sender,
                    forward_payload: msg.forward_payload
                }.toCell()
            });
        }

        msgValue -= ctx.readForwardFee();
        if (msg.response_destination != null) {
            send(SendParameters{
                to: msg.response_destination!!,
                value: msgValue - msg.forward_amount,
                mode: SendPayGasSeparately,
                bounce: true,
                body: Excesses{ query_id: msg.query_id }.toCell()
            });
        }
    }

    inline fun msgValue(value: Int): Int {
        let tonBalanceBeforeMsg: Int = myBalance() - value;
        let storageFee: Int = self.storageReserve - min(tonBalanceBeforeMsg, self.storageReserve);
        return value - (storageFee + self.ComputeFee);
    }
    get fun get_nft_data(): GetNftData {
        return GetNftData{
            is_initialized: self.doesExists(),
            index: self.nickname.asSlice().hash(),
            collection_address: self.master,
            owner_address: self.owner,
            individual_content: self.getIndividualContent()
        };
    }

    inline fun getIndividualContent(): Cell{
        return NicknameContent{
            nickname: self.nickname
        }.toCell();
    }

    abstract fun doesExists(): Bool;
    receive(msg: GetStaticData){
        let ctx = context();
        self.forward(
            sender(),
            ReportStaticData{ query_id: msg.query_id, index_id: self.nickname.asSlice().hash(), collection: self.master}.toCell(),
            false,
            null
        );
    }



}