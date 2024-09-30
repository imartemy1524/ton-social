

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






inline fun validateNickName(slice: Slice): Bool{
    // should be byte array
    require(slice.bits() % 8 == 0, "Invalid nickname");
    // should be less than 32 bytes length
    require(slice.bits() < 8 * 32, "Invalid nickname");
    // should be more than 0 bytes length
    require(slice.bits() > 0, "Invalid nickname");

    //does not starts with "-"
    require(slice.preloadUint(8) != 45, "Invalid nickname");
    //does not starts with "domain"
    require(!slice.startsWithDomain(), "System reserved nickname");
    //does not starts with "id"
    require(!slice.startsWithId(), "System reserved nickname");
    //does not starts with "owner"
    require(!slice.startsWithOwner(), "System reserved nickname");
    //does not starts with "master"
    require(!slice.startsWithMaster(), "System reserved nickname");
//    if(slice.startsWithId()){
//        slice.skipBits(16);
//        let bitShouldNotBeInteger = slice.loadUint(8);
//        require((bitShouldNotBeInteger >= 97 && bitShouldNotBeInteger <= 122), "Invalid nickname");
//    }

    repeat(slice.bits() / 8){
        let char = slice.loadUint(8);
        //check that char in range [a-z0-9-]
        require((char >= 48 && char <= 57) || (char >= 97 && char <= 122) || char == 45, "Invalid nickname");
    }
    return true;
}


//string starts with "id"
extends inline fun startsWithOwner(self: Slice): Bool{
    return self.bits() >= 40 && self.preloadUint(40) == 0b0110111101110111011011100110010101110010;
}
//string starts with "id"
extends inline fun startsWithId(self: Slice): Bool{
    return self.bits() >= 16 && self.preloadUint(16) == 0b0110100101100100;
}
extends inline fun startsWithMaster(self: Slice): Bool{
    return self.bits() >= 48 && self.preloadUint(48) == 0b011011010110000101110011011101000110010101110010;
}

//string starts with "nft"
extends inline fun startsWithDomain(self: Slice): Bool{
    return self.bits() >= 48 && self.preloadUint(48) == 0b011001000110111101101101011000010110100101101110;
}


inline fun dnsResolveResult(prefix: Int, dict: map<Int as uint256, Cell>, category: Int): DNSResolveResult{

    let recordDef = dict.get(sha256("next_resolver"));
    if category == 0 {
        if( recordDef != null){
            if(dict.get(sha256("wallet")) == null){
                dict.set(sha256("wallet"), recordDef);
            }
            if(dict.get(sha256("site")) == null){
                dict.set(sha256("site"), recordDef);
            }
        }
        return DNSResolveResult{prefix, record: dict.asCell()};
    }
    let record = dict.get(category);
    if record == null {
        record = recordDef;
    }

    //for now no more subdomains allowed
    return DNSResolveResult{prefix, record};
}




