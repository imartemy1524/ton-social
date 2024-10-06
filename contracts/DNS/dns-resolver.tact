import "@stdlib/dns";
trait DNSResolverMy {

    get fun dnsresolve(subdomain: Slice, category: Int): DNSResolveResult {

        // Normalize
        let delta: Int = 0;
        if (subdomain.preloadUint(8) == 0) {
            subdomain.loadUint(8); // Skip first byte
            delta = 8;
        }

        // Checks correctness
        require(dnsInternalVerify(subdomain), "Invalid DNS name");

        // Resolve
        let res: DNSResolveResult = self.doResolveDNS(subdomain, category);
        let prefixAns =  res.prefix == 0 && delta == 8 && subdomain.bits() == 0 && self.validRedirectRecord(res.record) ? 0 : (res.prefix + delta);
        return DNSResolveResult{prefix: prefixAns, record: res.record};
    }

    virtual fun doResolveDNS(subdomain: Slice, category: Int): DNSResolveResult {
        return DNSResolveResult{prefix: subdomain.bits(), record: null};
    }

    inline fun validRedirectRecord(record: Cell?): Bool{
        return record != null && (record!!.beginParse().preloadUint(16) == 0xba93);
    }
}