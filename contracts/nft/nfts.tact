import "./nft-structs.tact";


struct NFTCellString{
    byte: Int as uint8;
    data: String;
}
struct ElString{value: String;}
//https://medium.com/nexton-node/nfts-with-on-chain-metadata-on-ton-tutorial-55ac0cbb17d5#a51c
inline fun nftTextToCell(value: String): Cell {
    return beginCell().storeUint(0, 8).storeSlice(value.asSlice()).asCell();
}
// builds and returns cell of onchain NFT content, generated dynamically
// Official reference (not clear): https://github.com/ton-blockchain/TEPs/blob/master/text/0064-token-data-standard.md
// Good reference: https://medium.com/nexton-node/nfts-with-on-chain-metadata-on-ton-tutorial-55ac0cbb17d5

inline fun buildData(content: map<Int, ElString>): Cell{
    let ans: map<Int as uint256, Cell> = emptyMap();
    foreach(key, value in content){
        //
        ans.set(key,nftTextToCell(value.value));
    }
    return beginCell().storeInt(0, 8).storeBool(true).storeRef(ans.asCell()!!.asSlice().asCell()).endCell()
//    OnChainData{
//        byte: 0,
//        data: ans
//    }.toCell();
}

trait NftItem with Masterable, Ownable, IUser, Blockable{
    const ComputeFee: Int = ton("0.011");
    blocked: Bool;
    userId: Int;
    nickname: String?;
    master: Address;
    owner: Address;
    avatar: String?;
    receive(msg: GetStaticData){
        let ctx: Context = context();
            send(SendParameters {
            to: ctx.sender,
            value: 0,
            mode: SendRemainingValue,  // (return msg amount except gas fees)
            bounce: true,
            body: ReportStaticData{
            query_id: msg.query_id, index_id: self.userId, collection: self.master}.toCell()
        });
    }

    receive(msg: Transfer){
        self.requireNotBlocked();
        require(sender() == self.owner || sender() == self.master, "Only owner or master can transfer this NFT");
        let ctx: Context = context(); // Reference: https://docs.tact-lang.org/language/ref/common#context

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


    // does.... a..... computes feee...??? Magically....
    inline fun msgValue(value: Int): Int {
        let tonBalanceBeforeMsg: Int = myBalance() - value;
        let storageFee: Int = self.storageReserve - min(tonBalanceBeforeMsg, self.storageReserve);
        return value - (storageFee + self.ComputeFee);
    }
    // getter
    get fun get_nft_data(): GetNftData {
        return GetNftData{
            is_initialized: self.owner != NullAddress,
            index: self.userId,
            collection_address: self.master,
            owner_address: self.owner,
            individual_content: IndividualContent{
                avatar: self.avatar,
                nickname: self.nickname != null? self.nickname: null
            }.toCell()
        };
    }

}




trait NftCollection with Ownable, UserPerformable{
    abstract const CollectionName: String;
    abstract const CollectionDescription: String;
    abstract const LogoURL: String;
    abstract const MartketplaceURL: String;
    abstract const DefaultUserAvatar: String;
    abstract inline fun getRoyaltyAddress(): Address;
    lastUserId: Int;
    //percents * 100 (1234 = 12.34%)
    royaltyNumberator: Int;
    owner: Address;

    get fun get_collection_data(): CollectionData {
        //TODO: fix asSlice and then asCell...
        let data: map<Int, ElString> = emptyMap();
        data.set(sha256("name"), ElString{value: self.CollectionName});
        data.set(sha256("description"), ElString{value: self.CollectionDescription});
        data.set(sha256("image"), ElString{value: self.LogoURL});
        data.set(sha256("marketplace"), ElString{value: self.MartketplaceURL});
        return CollectionData{
            next_item_index: self.lastUserId,
            collection_content: buildData(data),
            owner_address: self.owner,
        };
    }
    get fun get_nft_content(index: Int, individual_content: Cell): Cell {
        let content: IndividualContent = IndividualContent.fromCell(individual_content);
        let data: map<Int, ElString> = emptyMap();
        let builderName = beginString();
        builderName.append("User ");
        appendNickName(builderName, content.nickname, index);
        let builderDescription = beginString();
        builderDescription.append("Unique user ");
        appendNickName(builderDescription, content.nickname, index);
        builderDescription.append(" in NetoTON social network");

        data.set(sha256("name"), ElString{value: builderName.toString()});
        data.set(sha256("image"), ElString{value:(content.avatar != null) ? content.avatar!! : self.DefaultUserAvatar});
        data.set(sha256("description"), ElString{value: builderDescription.toString()});

        return buildData(data);
    }
    get fun get_nft_address_by_index(index: Int): Address {
        return self.userContractAddress(index);
    }
    get fun royalty_params(): RoyaltyParams {
        return RoyaltyParams{
            numerator: self.royaltyNumberator,
            denominator: 100_00,
            destination: self.getRoyaltyAddress()
        };
    }


}

inline fun appendNickName(builder: StringBuilder, nickname: String?, index: Int){
    if(nickname != null){
        builder.append(nickname!!);
    } else {
        builder.append("#");
        builder.append(index.toString());
    }
}