//import "../nft/nft-structs.tact";
//import "../nft/user-nft.tact";

trait AchievementCollection{
    abstract const CollectionName: String;
    abstract const CollectionDescription: String;
    abstract const LogoURL: String;
    abstract const MartketplaceURL: String;
    // one can select any (true/false) as a value
    virtual const BUILD_NFT_DATA_AS_SNAKE: Bool = true;
    lastSbtId: Int;
    get fun get_collection_data(): CollectionData {
        let data: map<Int, ElString> = emptyMap();
        data.set(sha256("name"), ElString{ value: self.CollectionName});
        data.set(sha256("description"), ElString{ value: self.CollectionDescription});
        data = setImage(data, self.LogoURL);
        //        data.set( sha256("image"), ElString{ value: self.LogoURL});
        data.set(sha256("marketplace"), ElString{ value: self.MartketplaceURL});
        return CollectionData{
            next_item_index: self.lastSbtId,
            collection_content: buildData(data, self.BUILD_NFT_DATA_AS_SNAKE),
            owner_address: NullAddress,
        };
    }
    get fun get_nft_content(index: Int, individual_content: Cell): Cell {
        let content: IndividualContentAchivement = IndividualContentAchivement.fromCell(individual_content);
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

    abstract inline fun at(index: Int): Address;

}