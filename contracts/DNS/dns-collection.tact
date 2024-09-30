

// Trait to resolve TON Dns Master queries
trait DnsCollection with DNSResolverMy{
    isPointerToADNL: Bool;
    websiteId: Int;
    abstract fun getMasterContract(id: Int): Address;
    //original domain could be smthng like "profile.user-nickname.net.ton
    //subdomain - \0user-nickname\0maybesomethingelse\0
    //category - sha256("wallet") || sha256("site") || sha256("storage") || sha256("next_resolver")
    override fun doResolveDNS(subdomainFull: Slice, category: Int): DNSResolveResult {
        let maped: map<Int as uint256, Cell> = emptyMap();
        let prefix = 0;

        // Self-domain resolving - no subdomain found (someone enters "neto.ton")
        if (subdomainFull.empty()) {
            //return link to adnl website
            let siteRecord = self.website();
            let walletRecord = dnsResolveWallet(self.getMasterContract((1 << 64) - 1));
            maped.set(sha256("wallet"), walletRecord);
            maped.set(sha256("site"), siteRecord);
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
                let master = self.getMasterContract(ID);
                maped.set(sha256("next_resolver"), dnsResolveNext(master));
            }
            else if(subdomain.startsWithMaster()){
                subdomain.skipBits(48);
                prefix = 48;
                maped.set(sha256("next_resolver"), dnsResolveNext(self.getMasterContract((1 << 64) - 1)));

            }
            //starts with "domain" - reference to self
            else if(subdomain.startsWithDomain() && subdomain.bits() == 48){
                prefix += 8;
                //add the ending
                maped.set(sha256("wallet"), dnsResolveWallet(myAddress()));
            }
            else{
                let nextAddr = self.at(subdomain.hash());
                let resolvedDomain = dnsResolveNext(nextAddr);
                maped.set(sha256("next_resolver"), resolvedDomain);
            }
        }

        // Resolve subdomain
        // category == 0 - return all possible records
        return dnsResolveResult(prefix, maped, category);
    }
    inline fun website(): Cell{
        return self.isPointerToADNL ? dnsResolveWebsiteADNL(self.websiteId) : dnsResolveWebsiteTonStorage(self.websiteId)
    }



    abstract fun at(domainHash: Int): Address;

}