import "@stdlib/dns";


// Trait to resolve TON Dns Master queries
trait DnsMaster with DNSResolver{
    //original domain could be smthng like "profile.user-nickname.net.ton
    //subdomain - \0user-nickname\0maybesomethingelse\0
    //category - sha256("wallet") || sha256("site") || sha256("storage") || sha256("dns_next_resolver")
    override fun doResolveDNS(subdomain: Slice, category: Int): DNSResolveResult {

        // Self-domain resolving - no subdomain found (someone enters ".neto.ton" or "neto.ton")
        if (subdomain.bits() == 0) {
            //return link to adnl website
            let siteRecord = self.website();
            let walletRecord = dnsResolveWallet(self.master);
            let dict: map<Int as uint256, Cell> = emptyMap();
            dict.set(sha256("wallet"), walletRecord);
            dict.set(sha256("site"), siteRecord);

            // category == 0 - return all possible records
            if category == 0 {
                return DNSResolveResult{prefix: 0, record: dict.asCell()};
            }
            return DNSResolveResult{prefix: 0, record: dict.get(category)};
        }

        // remove subdomain from the slice (neto\user-nickname\0....) -> (user-nickname\0....)
        let subdomain = dnsExtractTopDomain(subdomain);

        // Resolve subdomain
        let resolvedDomain = self.resolveSubDomain(subdomain, "");
        let maped: map<Int as uint256, Cell> = emptyMap();
        maped.set(sha256("dns_next_resolver"), resolvedDomain);
        // category == 0 - return all possible records
        if category == 0{
            return DNSResolveResult{prefix: subdomain.bits(), record: maped.asCell()};
        }
        return DNSResolveResult{prefix: subdomain.bits(), record: resolvedDomain};
    }
    inline fun website(): Cell{
        return self.isPointerToADNL ? dnsResolveWebsiteADNL(self.adnlLink) : dnsResolveWebsiteTonStorage(self.adnlLink)
    }

    //subDomain - "user-nickname"
    //category - sha256("wallet") || sha256("site") || sha256("storage") || sha256("dns_next_resolver")
    //prefixLength - length of the subdomain
    inline fun resolveSubDomain(subdomain: Slice): Cell {
        //"user-nickname" should be extracted
        let referenceAddress = self.at(subdomain.hash());
        return dnsResolveNext(referenceAddress);
    }

    abstract inline fun at(domainHash: Cell): Address;

}