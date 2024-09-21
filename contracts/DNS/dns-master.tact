import "@stdlib/dns";

trait DnsMaster with DNSResolver, UserPerformable, Ownable{
    owner: Address;

    override fun doResolveDNS(subdomainFull: Slice, category: Int): DNSResolveResult {
        if (subdomainFull.bits() == 0) {
            let dict: map<Int as uint256, Cell> = emptyMap();
            dict.set(sha256("wallet"), dnsResolveWallet(myAddress()));

            if category == 0 {
                return DNSResolveResult{prefix: 0, record: dict.asCell()};
            }
            return DNSResolveResult{prefix: 0, record: dict.get(category)};
        }
        let maped: map<Int as uint256, Cell> = emptyMap();
        let subdomain = dnsExtractTopDomain(subdomainFull);
        let prefix = subdomain.bits();
        //starts with "id"
        if(subdomain.startsWithId()){
            subdomain.skipBits(16);
            let idNumber = subdomain.stringToInt();
            let address = self.userContractAddress(idNumber);
            maped.set(sha256("dns_next_resolver"), dnsResolveNext(address));
        }
        //starts with "owner"
        else if(subdomain.startsWithOwner() && subdomain.bits() == 5*8){
            maped.set(sha256("wallet"), dnsResolveWallet(self.owner));
        }

        if category == 0 {
            return DNSResolveResult{prefix, record: maped.asCell()};
        }
        return DNSResolveResult{prefix, record: maped.get(category)};
    }
}