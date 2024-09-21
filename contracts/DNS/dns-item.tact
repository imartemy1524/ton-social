import "@stdlib/dns";
message InternalLinkNicknamePong{
    nickname: String;
}
message InternalLinkNicknameToAccount{
    fromUserId: Int as uint64;
}
message InternalDeleteNicknameToAccount{
    newNickname: String;
}
message InternalDeleteNicknamePong{
    newNickname: String;
    oldNickname: String;
}


trait DnsItem with DNSResolver, Ownable, Masterable{
    owner: Address;
    master: Address;
    linked: Bool;
    nickname: String;
    //original domain could be smthng like "profile.user-nickname.net.ton
    //subdomain - \0maybesomethingelse\0
    //category - sha256("wallet") || sha256("site") || sha256("storage") || sha256("dns_next_resolver")
    override fun doResolveDNS(subdomainOld: Slice, category: Int): DNSResolveResult {
        let dict: map<Int as uint256, Cell> = emptyMap();
        let prefix = 0;
        // Self-domain resolving - no subdomain found (someone enters ".neto.ton" or "neto.ton")
        if (subdomainOld.bits() == 0) {
            //return link to adnl website
            let walletRecord = dnsResolveWallet(self.master);
            dict.set(sha256("wallet"), walletRecord);
            let v = dnsResolveNext(self.master);
            dict.set(sha256("site"), v);
            // IDK here, because if I want to return reference for "site" to parent contract, what should I do? Should i include "dns_resolve_next", or no?
            dict.set(sha256("dns_resolve_next"), v);

        }
        else{
            // remove subdomain from the slice (neto\user-nickname\0....) -> (user-nickname\0....)
            let subdomain = dnsExtractTopDomain(subdomainOld);
            //equals to "domain" - reference to this NFT contract
            if(subdomain.startsWithDomain() && subdomain.bits() == 48){
                prefix = subdomainOld.bits();
                dict.set(sha256("wallet"), dnsResolveWallet(myAddress()));
            }
            else{
                prefix = 0;
            }
        }
        return dnsResolveResult(prefix, dict, category);
    }


    receive(m: InternalLinkNicknameToAccount){
        self.requireOwner();
        self.linked = true;
        self.reply(InternalLinkNicknamePong{nickname: self.nickname}.toCell());
    }
    receive(m: InternalDeleteNicknameToAccount){
        self.requireOwner();
        self.linked = false;
        self.reply(InternalDeleteNicknamePong{newNickname: m.newNickname, oldNickname: self.nickname}.toCell());
    }
}

