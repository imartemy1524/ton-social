import "@stdlib/dns";
extends fun stringToInt(self: Slice): Int {
    // Cast the String as a Slice for parsing

    // A variable to store the accumulated number
    let acc: Int = 0;

    // Loop until the String is empty
    while (!self.empty()) {
        let char: Int = self.loadUint(8); // load 8 bits (1 byte) from the Slice
        acc = (acc * 10) + (char - 48);     // using ASCII table to get numeric value
        // Note, that this approach would produce unexpected results
        //   when the starting String contains non-numeric characters!
    }

    // Produce the resulting number
    return acc;
}


// Trait to resolve TON Dns Master queries
trait DnsCollection with DNSResolver{
    isPointerToADNL: Bool;
    websiteId: Int;
    abstract fun getMasterContract(id: Int): Address;
    //original domain could be smthng like "profile.user-nickname.net.ton
    //subdomain - \0user-nickname\0maybesomethingelse\0
    //category - sha256("wallet") || sha256("site") || sha256("storage") || sha256("dns_next_resolver")
    override fun doResolveDNS(subdomainFull: Slice, category: Int): DNSResolveResult {
        let maped: map<Int as uint256, Cell> = emptyMap();
        let prefix = 0;

        // Self-domain resolving - no subdomain found (someone enters "neto.ton")
        if (subdomainFull.bits() == 0) {
            //return link to adnl website
            let siteRecord = self.website();
            let walletRecord = dnsResolveWallet(self.getMasterContract((1 << 64) - 1));
            let dict: map<Int as uint256, Cell> = emptyMap();
            dict.set(sha256("wallet"), walletRecord);
            dict.set(sha256("site"), siteRecord);
        }
        else{
            // remove subdomain from the slice (neto\user-nickname\0....) -> (user-nickname\0....)
            let subdomain = dnsExtractTopDomain(subdomainFull);

            prefix = subdomain.bits();
            //starts with "id"
            if(subdomain.startsWithId()){
                //pass reolver to master contract
                subdomain.skipBits(16);
                prefix = 0;
                let ID = subdomain.stringToInt();

                maped.set(sha256("dns_next_resolver"), dnsResolveNext(self.getMasterContract(ID)));
            }
            //starts with "domain" - reference to self
            else if(subdomain.startsWithDomain() && subdomain.bits() == 48){
                maped.set(sha256("wallet"), dnsResolveWallet(myAddress()));
            }
            else{
                let resolvedDomain = self.resolveSubDomain(subdomain);
                maped.set(sha256("dns_next_resolver"), resolvedDomain);
            }
        }

        // Resolve subdomain
        // category == 0 - return all possible records
        return dnsResolveResult(prefix, maped, category);
    }
    inline fun website(): Cell{
        return self.isPointerToADNL ? dnsResolveWebsiteADNL(self.websiteId) : dnsResolveWebsiteTonStorage(self.websiteId)
    }

    //subDomain - "user-nickname"
    inline fun resolveSubDomain(subdomain: Slice): Cell {
        //"user-nickname" should be extracted
        let referenceAddress = self.at(subdomain.hash());
        return dnsResolveNext(referenceAddress);
    }

    abstract fun at(domainHash: Int): Address;

}