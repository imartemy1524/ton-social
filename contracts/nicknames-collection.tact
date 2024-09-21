import "./nicknames-collection-item.tact";
import "./DNS/index.tact";
import "./nft/DNS/inde.tact";
import "@stdlib/ownable";
message SetWebisteId{
    websiteId: Int;
    isPointerToADNL: Bool;
}
contract NicknamesCollection with DnsMaster, DnsCollection, Deployable, OwnableTransferable{
    master: Address;
    owner: Address;


    override const CollectionName: String = "NetoTon nicknames";
    override const LogoURL: String = readFile("./nft/DNS/collection.svg", "utf8");
    override const MartketplaceURL: String = "marketplace.netoton.ton";
    override inline fun collectionDescription(): String;
    override const BUILD_NFT_DATA_AS_SNAKE: Bool = true;
    const FEES: Int = ton("0.1");
    nicknamesCount: Int = 0;
    //ADNL link to website OR ADNL link to ton storage
    websiteId: Int = 0;
    // is it a pointer to ADNL website (true - ADNL website, false - ton storage)
    isPointerToADNL: Bool = true;
    init(master: Address){
        self.master = master;
        self.owner = myAddress();
    }

    receive(m: SetWebisteId){
        self.requireOwner();
        self.websiteId = m.websiteId;
        self.isPointerToADNL = m.isPointerToADNL;
    }
    override fun at(domainHash: Int): Address {
        let i = self.initOfIT(domainHash);
        return contractAddress(i);
    }
    receive(m: String){
        let slice = m.asSlice();
        // should be binary
        require(slice.bits() % 8 == 0, "Invalid nickname");
        // should be less than 32 bytes length
        require(slice.bits() < 8 * 32, "Invalid nickname");
        // should be more than 0 bytes length
        require(slice.bits() > 0, "Invalid nickname");
        // should contain only [a-z0-9-]
        validateNickName(slice);
        if(sender() != self.owner){
            self.ensureFee(slice);
        }
        let domainHash = slice.hash();
        let dataBin = self.initOfIT(domainHash);
        let nftAddress = contractAddress(dataBin);
        //create auction
        let auctionAddress = createAuction(nftAddress, sender());
        //deploy nft
        send(SendParameters{
            value: ton("0.05"),
            bounce: false,
            body: InitizlizeNickname{domain: slice.asString(), owner: auctionAddress},
            to: nftAddress,
            data: dataBin.data,
            code: dataBin.code
        });
    }
    inline fun initOfIT(domainHash: Int): StateInit{
        return initOf NicknamesCollectionItem(myAddress(), domainHash);
    }
    inline fun ensureFee(slice: Slice){
        if(slice.bits() == 1){
            // 1000 TON required for 1 char nickname
            require(context().value >= ton("1000") + self.FEES);
        }
        if(slice.bits() == 2){
            // 100 TON required for 2 char nickname
            require(context().value >= ton("100")  + self.FEES);
        }
        if(slice.bits() == 3){
            // 10 TON required for 3 char nickname
            require(context().value >= ton("50")  + self.FEES);
        }
        if(slice.bits() == 4){
            // 1 TON required for 4 char nickname
            require(context().value >= ton("25")  + self.FEES);
        }
        if(slice.bits() == 5){
            // 1 TON required for 5 char nickname
            require(context().value >= ton("10")  + self.FEES);
        }
        if(slice.bits() == 6){
            // 1 TON required for 6 char nickname
            require(context().value >= ton("5") + self.FEES);
        }
        require(context().value >= ton("1") + self.FEES);
    }
}


inline fun validateNickName(slice: Slice): Bool{
    repeat(slice.bits() / 8){
        let char = slice.loadUint(8);
        //check that char in range [a-z0-9-]
        require((char >= 48 && char <= 57) || (char >= 97 && char <= 122) || char == 45, "Invalid nickname");
    }
    return true;
}
