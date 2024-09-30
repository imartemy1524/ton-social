import "./dns-resolver.tact";
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
trait DnsItem with DNSResolverMy, Masterable{
    owner: Address?;
    master: Address;
    linked: Bool;
    nickname: String;
    inline fun requireOwner(){
        require( self.owner != null && sender() == self.owner!!, "Invalid sender");
    }
    //original domain could be smthng like "profile.user-nickname.net.ton
    //subdomain - maybesomethingelse\0
    //category - sha256("wallet") || sha256("site") || sha256("storage") || sha256("next_resolver")
    override fun doResolveDNS(subdomainOld: Slice, category: Int): DNSResolveResult {
        require(self.isInitialized(), "Not initialized");
        let dict: map<Int as uint256, Cell> = emptyMap();
        let prefix = 0;
        // Self-domain resolving - no subdomain found (someone enters ".neto.ton" or "neto.ton")
        if (subdomainOld.empty()) {
            if(self.owner != null && self.linked){
                dict.set(sha256("next_resolver"), dnsResolveNext(self.owner!!));
            }
            dict.set(sha256("site"), dnsResolveNext(self.master));

        }
        else{
            // remove subdomain from the slice (neto\user-nickname\0....) -> (user-nickname\0....)
            let subdomain = dnsExtractTopDomain(subdomainOld);
            //equals to "domain" - reference to this NFT contract
            if(subdomain.startsWithDomain() && subdomain.bits() == 48){
                prefix = subdomainOld.bits();
                dict.set(sha256("wallet"), dnsResolveWallet(myAddress()));
            }
            else if(self.owner != null && self.linked){
                prefix = 0;
                dict.set(sha256("next_resolver"), dnsResolveNext(self.owner!!));
            }

        }
        return dnsResolveResult(prefix, dict, category);
    }


    receive(m: InternalLinkNicknameToAccount){
        self.requireOwner();
        self.linked = true;
        self.reply(InternalLinkNicknamePong{ nickname: self.nickname}.toCell());
    }
    receive(m: InternalDeleteNicknameToAccount){
        self.requireOwner();
        self.linked = false;
        self.reply(InternalDeleteNicknamePong{ newNickname: m.newNickname, oldNickname: self.nickname}.toCell());
    }

    abstract fun isInitialized(): Bool;

}

