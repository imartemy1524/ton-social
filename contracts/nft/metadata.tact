import "../utils/date.tact";
struct IndividualContent {
    avatar: String?;
    nickname: String?;
    postsCount: Int as uint64;
    registerDate: Int as uint64;
}


inline fun appendNickName(builder: StringBuilder, nickname: String?, index: Int){
    if(nickname != null){
        builder.append(nickname!!);
    } else {
        builder.append("#");
        builder.append(index.toString());
    }
}
extends fun buildNftName(self: IndividualContent, index: Int): String {
    let builderName = beginString();
    builderName.append("User ");
    appendNickName(builderName, self.nickname, index);
    return builderName.toString();
}
extends fun buildDescription(self: IndividualContent, index: Int): String {
    let builderDescription = beginString();
    builderDescription.append("Unique user ");
    appendNickName(builderDescription, self.nickname, index);
    builderDescription.append(" in NetoTON social network");
    return builderDescription.toString();
}
extends fun buildAttributesString(self: IndividualContent): String {
    let builderAttributes = createJsonArray()
        .appendObject(
            createJsonObject()
                .appendString("trait_type", "Posts count")
                .appendString("value", self.postsCount.toString())
        )
        .appendObject(
            createJsonObject()
                .appendString("trait_type", "Register date")
                .appendString("value", self.registerDate.asUnixTimeDateString("/"))
        );
    return builderAttributes.toString();
}


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
    return beginCell().storeInt(0, 8).storeBool(true).storeRef(ans.asCell()!!).endCell()
    //    OnChainData{
    //        byte: 0,
    //        data: ans
    //    }.toCell();
}