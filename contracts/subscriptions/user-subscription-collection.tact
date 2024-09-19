extends inline fun buildNftName(self: IndividualContentSBT, userId: Int): String{
    return beginString()
        .concat("Subscription level ")
        .concat(self.data == null?"-1":self.data!!.level.toString())
        .concat(" from user id")
        .concat(userId.toString())
        .toString();
}
extends inline fun buildDescription(self: IndividualContentSBT, userAddress: Address): String{
    return beginString().concat("SBT, which represents subscription for user ").concat(myAddress().toString()).concat(" from user ").concat(
        userAddress.toString()
    ).toString();
}
extends inline fun buildAttributesString(self: IndividualContentSBT): String{
    return beginString()
    .concat("[{\"trait_type\":\"Level\",\"value\":\"").concat(self.data == null?"-1":self.data!!.level.toString()).concat("\"},")
    .concat("{\"trait_type\":\"Payment period\",\"value\":\"").concat(self.data == null?"-1":self.data!!.paymentPeriod.toString()).concat("\"},")
    .concat("{\"trait_type\":\"Payment amount\",\"value\":\"").concat(self.data == null?"-1":self.data!!.paymentAmount.toCoinsString()).concat("\"}")
    .concat("]")
    .toString();
}
trait UserSubscriptionCollection with UserPerformable{
    virtual inline fun collectionDescription(): String{
        return "";
    }
    virtual inline fun collectionName(): String{
        return "";
    }
    avatar: String? = null;
    virtual const BUILD_NFT_DATA_AS_SNAKE: Bool = true;
    get fun get_collection_data(): CollectionData {
        let data: map<Int, ElString> = emptyMap();
        data.set(sha256("name"), ElString{ value: self.collectionName()});
        data.set(sha256("description"), ElString{ value: self.collectionDescription()});
        //TODO: add some image and insert user's avatar inside it
        data = setImage(data, self.avatar!=null?self.avatar!!:"https://images.squarespace-cdn.com/content/v1/5478e059e4b04a873e34cd68/1545079938433-0ZHMJ1RJW2R4U6X8NOXY/Subscribe.jpeg");
        return CollectionData{ next_item_index: -1, collection_content: buildData(data, self.BUILD_NFT_DATA_AS_SNAKE),owner_address: NullAddress};
    }
    get fun get_nft_content(index: Int, individual_content: Cell): Cell {
        let content: IndividualContentSBT = IndividualContentSBT.fromCell(individual_content);
        let data: map<Int, ElString> = emptyMap();

        data.set(sha256("name"), ElString{
            value: content.buildNftName(index)
        });
        data = setImage(data, readFile("./sbt-subscription.svg", "utf8"));
        data.set(sha256("description"), ElString{ value: content.buildDescription(self.userContractAddress(index))});
        data.set(sha256("attributes"), ElString{ value: content.buildAttributesString()});
        let ans = buildData(data, self.BUILD_NFT_DATA_AS_SNAKE);
        return ans;
    }
    get fun get_nft_address_by_index(index: Int): Address {
        return self.at(index);
    }

    abstract inline fun at(index: Int): Address;

}