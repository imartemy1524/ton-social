import "@stdlib/dns";



trait DnsItem with DNSResolver, Ownable, Masterable{
    owner: Address;
    master: Address;
    //original domain could be smthng like "profile.user-nickname.net.ton
    //subdomain - \0user-nickname\0maybesomethingelse\0
    //category - sha256("wallet") || sha256("site") || sha256("storage") || sha256("dns_next_resolver")
    override fun doResolveDNS(subdomain: Slice, category: Int): DNSResolveResult {

        // Self-domain resolving - no subdomain found (someone enters ".neto.ton" or "neto.ton")
        if (subdomain.bits() == 0) {
            //return link to adnl website
            let dict: map<Int as uint256, Cell> = emptyMap();
            let walletRecord = dnsResolveWallet(self.master);
            dict.set(sha256("wallet"), walletRecord);
            let v = dnsResolveNext(self.master);
            dict.set(sha256("site"), v);
            // IDK here, because if I want to return reference for "site" to parent contract, what should I do? Should i include "dns_resolve_next", or no?
            dict.set(sha256("dns_resolve_next"), v);

            // category == 0 - return all possible records
            if category == 0 {
                return DNSResolveResult{prefix: 0, record: dict.asCell()};
            }
            return DNSResolveResult{prefix: 0, record: dict.get(category)};
        }

        // remove subdomain from the slice (neto\user-nickname\0....) -> (user-nickname\0....)
        let subdomain = dnsExtractTopDomain(subdomain);
        //for now no more subdomains allowed
        return DNSResolveResult{prefix: subdomain.bits(), record: null};
    }

}

