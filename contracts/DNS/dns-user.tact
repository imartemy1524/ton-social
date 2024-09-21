import "./types.tact";
message ExternalValidateNickname{
    nickname: String;
}
message TransferNickname{
    nickname: String;
    transfer: Transfer;
}

trait DnsUser with IUser, DNSResolverMy, NicknameItemFindable, Ownable, Excessable{
    userId: Int;
    nickname: String?;
    owner: Address;


    blockedDNS: Bool;
    nicknameCollection: Address?;
    override fun doResolveDNS(subdomainFull: Slice, category: Int): DNSResolveResult {
        let dict: map<Int as uint256, Cell> = emptyMap();
        let skip = 0;
        // Self-domain resolving
        if(subdomainFull.empty()){
            dict.set(sha256("wallet"), dnsResolveWallet(myAddress()));
        }
        else{
            skip = subdomainFull.bits();
            let subdomain = dnsExtractTopDomain(subdomainFull);
            //starts with "owner"
            if(subdomain.startsWithOwner() && subdomain.bits() == 5*8){
                dict.set(sha256("wallet"), dnsResolveWallet(self.owner));
            }
            if(subdomain.startsWithDomain() && subdomain.bits() == 6*8 && self.nickname != null){
                let address = contractAddress(self.nickNameContractAt(self.nickname!!));
                dict.set(sha256("wallet"), dnsResolveWallet(address));
            }
            //TODO: add post-id, subscription-id, etc.
        }
        return dnsResolveResult(skip, dict, category);

    }



    receive(m: ExternalValidateNickname){
        self.requireOwner();
        require(self.blockedDNS == false, "Blocked");
        self.blockedDNS = true;
        if(self.nickname == null){
            self.__setNickname(m.nickname);
        }
        else{
            //unlink nickname if it exits, and then in response call __setNickname
            require(context().value >= ton("0.12"), "Not enough funds");
            self.forward(
                contractAddress(self.nickNameContractAt(self.nickname!!)),
                InternalDeleteNicknameToAccount{newNickname: m.nickname}.toCell(),
                true,
                null
            )
        }
    }
    receive(m: InternalDeleteNicknamePong){
        require(sender() == contractAddress(self.nickNameContractAt(m.oldNickname)), "Invalid sender");
        require(self.blockedDNS == true, "Blocked");
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
        require(sender() == contractAddress(self.nickNameContractAt(m.nickname)), "Invalid sender");
        require(self.blockedDNS == true, "Blocked");
        self.blockedDNS = false;
        self.nickname = m.nickname;
        self.excess(self.owner, "ok");
    }


    fun __setNickname(nickname: String){
        require(context().value >= ton("0.05"), "Not enough funds");
        self.forward(
            contractAddress(self.nickNameContractAt(nickname)),
            InternalLinkNicknameToAccount{fromUserId: self.userId}.toCell(),
            true,
            null
        )
    }

    bounced(m: InternalLinkNicknameToAccount){
        self.blockedDNS = false;
    }
    receive(m: TransferNickname){
        require(context().value >= ton("0.05"), "Not enough funds");
        require(!self.blockedDNS, "should not be blocked!");
        require(self.nickname == null || m.nickname != self.nickname, "To transfer NFT you should fi");
        //TODO: think about requires above more carefully
        self.forward(contractAddress(self.nickNameContractAt(m.nickname)), m.transfer.toCell(), true, null);
    }
    bounced(m: bounced<Transfer>){
        //TODO: is this even safe, to unblock without verifying... ???
        self.blockedDNS = false;
    }
}