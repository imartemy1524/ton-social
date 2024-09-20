import "@stdlib/dns";


@interface("org.tact-lang.contract.dns.v0")
trait INicknamesCollection with DNSResolver, Masterable, OwnableTransferable{
    master: Address;
    owner: Address;
    abstract const CollectionName: String;
    abstract const LogoURL: String;
    abstract const MartketplaceURL: String;
    abstract inline fun collectionDescription(): String;
    virtual const BUILD_NFT_DATA_AS_SNAKE: Bool = true;
    nicknamesCount: Int;
    //ADNL link to website OR ADNL link to ton storage
    websiteId: Int;
    // is it a pointer to ADNL website (true - ADNL website, false - ton storage)
    isPointerToADNL: Bool;
    get fun get_collection_data(): CollectionData {
        let data: map<Int, ElString> = emptyMap();
        data.set(sha256("name"), ElString{ value: self.CollectionName});
        data.set(sha256("description"), ElString{ value: self.collectionDescription()});
        data = setImage(data, self.LogoURL);
        data.set(sha256("marketplace"), ElString{
        value: self.MartketplaceURL});
        return CollectionData{
            next_item_index: self.nicknamesCount,
            collection_content: buildData(data, self.BUILD_NFT_DATA_AS_SNAKE),
            owner_address: null
        };
    }

    get fun get_nft_content(index: Int, individual_content: Cell): Cell {
        let content: NicknameContent = NicknameContent.fromCell(individual_content);
        let data: map<Int, ElString> = emptyMap();

        data.set(sha256("name"), ElString{value: content.buildNftName(index)});
        data = setImage(data, content.buildImage(index));
        data.set(sha256("description"), ElString{ value: content.buildDescription(index)});
        data.set(sha256("attributes"), ElString{ value: content.buildAttributesString()});
        let ans = buildData(data, self.BUILD_NFT_DATA_AS_SNAKE);
        return ans;
    }
    get fun get_nft_address_by_index(index: Int): Address {
        return self.at(index);
    }
    //subdomain - \0neto\0user-nickname\0maybesomethingelse\0
    //category - sha256("wallet") || sha256("site") || sha256("storage") || sha256("dns_next_resolver")
    override fun doResolveDNS(subdomain: Slice, category: Int): DNSResolveResult {

        // Self-domain resolving - no subdomain found (someone enters ".neto.ton" or "neto.ton")
        if (subdomain.bits() == 0) {
            //return link to adnl website
            let siteRecord = self.isPointerToADNL ? dnsResolveWebsiteADNL(self.adnlLink) : dnsResolveWebsiteTonStorage(self.adnlLink);
            let walletRecord = dnsResolveWallet(self.master);

            // category == 0 - return all possible records
            if category == 0 {
                let dict: map<Int as uint256, Cell> = emptyMap();
                dict.set(sha256("wallet"), walletRecord);
                dict.set(sha256("site"), siteRecord);
                let dict = dict.asCell()!!;
                return DnsResolveResult{prefix: 0, record: dict};
            }
            if category == sha256("site"){
                return DnsResolveResult{prefix: 0, record: siteRecord};
            }
            if category == sha256("wallet"){
                return DnsResolveResult{prefix: 0, record: walletRecord};
            }
            //return link to master contract
            return DnsResolveResult{prefix: 0, record: null};
        }

        // remove subdomain from the slice (neto\user-nickname\0....) -> (user-nickname\0....)
        let length = dnsExtractTopDomainLength(subdomain) + 1;
        subdomain.skipBits(length);
        // Resolve subdomain
        let resolvedDomain = self.resolveSubDomain(subdomain, length);
        // category == 0 - return all possible records
        if category == 0{
            let maped: map<Int as uint256, Cell> = emptyMap();
            maped.set(sha256("dns_next_resolver"), resolvedDomain.record);
            return DNSResolveResult{prefix: resolvedDomain.prefix, record: maped.asCell()};
        }
        if category == sha256("dns_next_resolver"){
            return resolvedDomain;
        }
        return DNSResolveResult{prefix: resolvedDomain.prefix, record: null};
    }

    //subDomain - "user-nickname\0maybesomethingelse\0"
    //category - sha256("wallet") || sha256("site") || sha256("storage") || sha256("dns_next_resolver")
    //prefixLength - length of the subdomain
    inline fun resolveSubDomain(subDomain: Slice, prefixLength: Int): DNSResolveResult {
        //"user-nickname" should be extracted
        let subdomain = dnsExtractTopDomain(subDomain);
        let referenceAddress = self.at(subdomain.hash());
        return DNSResolveResult {
            prefix: prefixLength,
            record: dnsResolveNext(referenceAddress)
        };
    }

    abstract inline fun at(domainHash: Cell): Address;


}


// add smthng like bob.neto.ton