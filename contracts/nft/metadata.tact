import "../utils/date.tact";
struct IndividualContent {
    avatar: String?;
    nickname: String?;
    postsCount: Int as uint64;
    registerDate: Int as uint64;
}


inline extends mutates fun appendNickName(self: StringBuilder, nickname: String?, index: Int){
    if(nickname != null){
        self.append(nickname!!);
    } else {
        self.append("#");
        self.append(index.toString());
    }
    //    return self;
}
extends fun buildNftName(self: IndividualContent, index: Int): String {
    let builderName = beginString();
    builderName.append("User ");
    builderName.appendNickName(self.nickname, index);
    return builderName.toString();
}
extends fun buildDescription(self: IndividualContent, index: Int): String {
    let builderDescription = beginString();
    builderDescription.append("Unique user ");
    builderDescription.appendNickName(self.nickname, index);
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
struct ElString{
    value: String;}
//Store nft text as snake cell
inline fun nftTextToCellAsMultiref(input: String): Cell {
    let slice: Slice = input.asSlice();

    let builder = beginString()
    //   write "0" as uint
    .concat("\x00")
    //   write input as string (s.t. cell refs would be recalculated)
    .concat(input);
    return builder.toString().asSlice().asCell();

}
//Store nft text as a dict cell

inline fun nftTextToCellAsDict(input: String): Cell{
    let dict: map<Int as uint32, Cell> = emptyMap();
    let curr: Slice = input.asSlice();
    let valid = true;
    let i = 0;
    while(valid){
        dict.set(i, curr.loadBits(curr.bits()).asCell());
        i += 1;
        valid = !curr.refsEmpty();
        if(valid){
            curr = curr.loadRef().asSlice();
        }
    }

    return beginCell()
    //1 - chunk dict
    .storeUint(1, 8)
    .storeBool(true)
    .storeRef(dict.asCell()!!)
    .asCell();

}
//https://medium.com/nexton-node/nfts-with-on-chain-metadata-on-ton-tutorial-55ac0cbb17d5#a51c

inline fun nftTextToCell(input: String, storeAsSnake: Bool): Cell {
    if(storeAsSnake) {
        return nftTextToCellAsMultiref(input);
    }
    return nftTextToCellAsDict(input);
}
inline fun buildData(content: map<Int, ElString>, asSnake: Bool): Cell{
    let ans: map<Int as uint256, Cell> = emptyMap();
    foreach(key, value in content){
        //
        ans.set(key, nftTextToCell(value.value, asSnake));
    }
    return beginCell().storeInt(0, 8).storeBool(true).storeRef(ans.asCell()!!).endCell()
    //    OnChainData{
    //        byte: 0,
    //        data: ans
    //    }.toCell();
}


//inline fun nftTextToCell(input: String): Cell {
//    let slice: Slice = input.asSlice();
//    //                                  write 0 bit
//    let builder = beginString().concat("\x00").concat(input).toString();
//    return builder.asSlice().asCell();
//}

// builds and returns cell of onchain NFT content, generated dynamically
// Official reference (not clear): https://github.com/ton-blockchain/TEPs/blob/master/text/0064-token-data-standard.md
// Good reference: https://medium.com/nexton-node/nfts-with-on-chain-metadata-on-ton-tutorial-55ac0cbb17d5

