
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
    return readFile("./collection.svg", "utf8");
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


struct DNSPointerToWebsiteADNL{
    code: Int as uint16;
    //domain name ADNL
    domain: Int as uint256;
    flags: Int as uint8;
}
struct DNSPointerToTonStorage{
    code: Int as uint16;
    //domain name ADNL
    domain: Int as uint256;
}


//reference to
inline fun dnsResolveWebsiteADNL(name: Int): Cell{
    return DNSPointerToWebsiteADNL{code: 0xad01, domain: name, flags: 0}.toCell();
}

inline fun dnsResolveWebsiteTonStorage(name: Int): Cell{
    return DNSPointerToTonStorage{code: 0x7473, domain: name}.toCell();
}


