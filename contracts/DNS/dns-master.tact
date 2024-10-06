
trait DnsMaster with DNSResolverMy, UserPerformable, Ownable{
    owner: Address;

    override fun doResolveDNS(subdomainFull: Slice, category: Int): DNSResolveResult {
        let maped: map<Int as uint256, Cell> = emptyMap();
        let prefix = 0;
        if (subdomainFull.bits() == 0) {
            maped.set(sha256("wallet"), dnsResolveWallet(myAddress()));
        }
        else{
            let subdomain = dnsExtractTopDomain(subdomainFull);
            prefix = subdomain.bits();
            if(subdomain.startsWithOwner() && subdomain.bits() == 5*8){
                maped.set(sha256("wallet"), dnsResolveWallet(self.owner));
                prefix += 8;
            }
            else {
                //if starts with "id"
                if(subdomain.startsWithId()){
                    // skip "id"
                    subdomain.skipBits(16);
                }
                //now suppose, that subdomain - ID of user (in string)
                let idNumber = subdomain.stringToInt();
                let address = self.userContractAddress(idNumber);
                maped.set(sha256("dns_next_resolver"), dnsResolveNext(address));
            }
        }
        return dnsResolveResult(prefix, maped, category);
    }
}