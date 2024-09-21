

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


