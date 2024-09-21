
@interface("org.tact-lang.contract.dns.v0")
trait DnsCollection with Masterable, OwnableTransferable{
    master: Address;
    owner: Address;
    abstract const CollectionName: String;
    abstract const LogoURL: String;
    abstract const MartketplaceURL: String;
    abstract inline fun collectionDescription(): String;
    virtual const BUILD_NFT_DATA_AS_SNAKE: Bool = true;
    nicknamesCount: Int;
    //ADNL link to website OR ADNL link to ton storage
    websiteId: Int;
    // is it a pointer to ADNL website (true - ADNL website, false - ton storage)
    isPointerToADNL: Bool;
    get fun get_collection_data(): CollectionData {
        let data: map<Int, ElString> = emptyMap();
        data.set(sha256("name"), ElString{ value: self.CollectionName});
        data.set(sha256("description"), ElString{ value: self.collectionDescription()});
        data = setImage(data, self.LogoURL);
        data.set(sha256("marketplace"), ElString{
        value: self.MartketplaceURL});
        return CollectionData{
            next_item_index: self.nicknamesCount,
            collection_content: buildData(data, self.BUILD_NFT_DATA_AS_SNAKE),
            owner_address: null
        };
    }

    get fun get_nft_content(index: Int, individual_content: Cell): Cell {
        let content: NicknameContent = NicknameContent.fromCell(individual_content);
        let data: map<Int, ElString> = emptyMap();

        data.set(sha256("name"), ElString{value: content.buildNftName(index)});
        data = setImage(data, content.buildImage(index));
        data.set(sha256("description"), ElString{ value: content.buildDescription(index)});
        data.set(sha256("attributes"), ElString{ value: content.buildAttributesString()});
        let ans = buildData(data, self.BUILD_NFT_DATA_AS_SNAKE);
        return ans;
    }
    get fun get_nft_address_by_index(index: Int): Address {
        return self.at(index);
    }
    abstract inline fun at(domainHash: Int): Address;


}


// add smthng like bob.neto.ton