import "./nft-structs.tact";
import "./metadata.tact";
import "../utils/json.tact";

inline fun setImage(data: map<Int, ElString>, avatar: String): map<Int, ElString>{
    //starts with http
    if(avatar.asSlice().preloadUint(32)== 0b01101000011101000111010001110000){
        data.set(sha256("image"), ElString{ value: avatar});
    } else {
        data.set(sha256("image_data"), ElString{ value: avatar});
    }
    return data;
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
            body: Excesses{
            query_id: msg.query_id }.toCell()
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
            individual_content: self.getIndividualContent()
        };
    }
    abstract inline fun getIndividualContent(): Cell;

}


trait NftCollection with Ownable, UserPerformable{
    abstract const CollectionName: String;
    abstract const CollectionDescription: String;
    abstract const LogoURL: String;
    abstract const MartketplaceURL: String;
    abstract inline fun getDefaultAvatar(): String;
    abstract inline fun getRoyaltyAddress(): Address;
    //if true - build data as snake cell, otherwise as dict
    virtual const BUILD_NFT_DATA_AS_SNAKE: Bool = false;
    lastUserId: Int;
    //percents * 100 (1234 = 12.34%)
    royaltyNumberator: Int;
    owner: Address;

    get fun get_collection_data(): CollectionData {
        //TODO: fix asSlice and then asCell...
        let data: map<Int, ElString> = emptyMap();
        data.set(sha256("name"), ElString{
        value: self.CollectionName});
        data.set(sha256("description"), ElString{ value: beginString().concat(self.lastUserId.toString()).concat(" ").concat(self.CollectionDescription).toString()});
        data = setImage(data, self.LogoURL);
//        data.set( sha256("image"), ElString{ value: self.LogoURL});
        data.set(sha256("marketplace"), ElString{
        value: self.MartketplaceURL});
        return CollectionData{
            next_item_index: self.lastUserId,
            collection_content: buildData(data, self.BUILD_NFT_DATA_AS_SNAKE),
            owner_address: self.owner,
        };
    }
    get fun get_nft_content(index: Int, individual_content: Cell): Cell {
        let content: IndividualContent = IndividualContent.fromCell(individual_content);
        let data: map<Int, ElString> = emptyMap();

        data.set(sha256("name"), ElString{
        value: content.buildNftName(index)});
        let avatar: String = content.avatar != null? content.avatar!!: self.getDefaultAvatar();

        data = setImage(data, avatar);
        data.set(sha256("description"), ElString{
        value: content.buildDescription(index)});
        //TODO: fix later
        data.set(sha256("marketplace"), ElString{ value: self.MartketplaceURL});
        data.set(sha256("attributes"), ElString{ value: content.buildAttributesString()});
        let ans = buildData(data, self.BUILD_NFT_DATA_AS_SNAKE);
        return ans;
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

