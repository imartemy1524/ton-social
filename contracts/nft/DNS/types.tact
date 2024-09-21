
struct NicknameContent{
    nickname: String;
}

extends inline fun buildNftName(self: NicknameContent, index: Int): String{
    return beginString().concat("Domain ").concat(self.nickname).concat(".nt").toString();
}
extends inline fun buildDescription(self: NicknameContent, index: Int): String{
    return beginString().concat("Domain ").concat(self.nickname).concat(" is a unique domain name on NetoTon blockchain").toString();
}
extends inline fun buildImage(self: NicknameContent, index: Int): String{
    //TODO: add image for NFT domain item
    return "http://";
}


extends inline fun buildAttributesString(self: NicknameContent): String{
    let builderAttributes = createJsonArray()
    .appendObject(
    createJsonObject()
    .appendString("trait_type", "Nickname")
    .appendString("value", self.nickname)
    )
    .appendObject(
    createJsonObject()
    .appendString("trait_type", "Length")
    .appendString("value", (self.nickname.asSlice().bits()/8).toString())
    );
    return builderAttributes.toString();
}
