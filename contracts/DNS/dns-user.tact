message ExternalValidateNickname{
    nickname: String;
}


trait DnsUser with IUser, DNSResolver, NicknameItemFindable, Ownable, Excessable{
    blockedDNS: Bool;
    nickname: String?;
    nicknameCollection: Address;
    override fun doResolveDNS(subdomainFull: Slice, category: Int): DNSResolveResult {
        let dict: map<Int as uint256, Cell> = emptyMap();
        let skip = 0;
        // Self-domain resolving
        if(subdomainFull.empty()){
            dict.set(sha256("wallet"), dnsResolveWallet(myAddress()));
        }
        else{
            let subdomain = dnsExtractTopDomain(subdomainFull);
            skip = subdomain.bits();
            //starts with "owner"
            if(subdomain.startsWithOwner() && subdomain.bits() == 5*8){
                let dict: map<Int as uint256, Cell> = emptyMap();
                dict.set(sha256("wallet"), dnsResolveWallet(myAddress()));
            }
            //TODO: add post-id, subscription-id, etc.
        }
        return dnsResolveResult(0, dict, category);

    }



    receive(m: ExternalValidateNickname){
        self.requireOwner();
        require(self.blockedDNS == false, 101);
        self.blockedDNS = true;
        if(self.nickname == null){
            self.__setNickname(m.nickname);
        }
        else{
            //unlink nickname if it exits, and then in response call __setNickname
            require(context().value >= ton("0.12"), 102);
            self.forward(
                contractAddress(self.nickNameContractAt(self.nickname)),
                InternalDeleteNicknameToAccount{newNickname: m.nickname},
                true,
                null
            )
        }
    }
    receive(m: InternalDeleteNicknamePong){
        require(sender() == self.nickNameContractAt(m.oldNickname), 103);
        require(self.blockedDNS == true, 103);
        self.nickname = null;
        if(m.newNickname == ""){
            self.blockedDNS = false;
            self.excess(self.owner, "ok");
        }
        else{
            self.__setNickname(m.newNickname);
        }
    }
    bounced(m: bounced<InternalDeleteNicknameToAccount>){
        self.blockedDNS = false;
    }
    receive(m: InternalLinkNicknamePong){
        require(sender() == self.nickNameContractAt(m.nickname), 103);
        require(self.blockedDNS == true, 103);
        self.blockedDNS = false;
        self.nickname = m.nickname;
        self.excess(self.owner, "ok");
    }


    fun __setNickname(nickname: String){
        require(context().value >= ton("0.05"), 102);
        self.forward(
            contractAddress(self.nickNameContractAt(nickname)),
            InternalLinkNicknameToAccount{fromUserId: self.userId},
            true,
            null
        )
    }

    bounced(m: bounced<InternalLinkNicknameToAccount>){
        self.blockedDNS = false;
    }
}