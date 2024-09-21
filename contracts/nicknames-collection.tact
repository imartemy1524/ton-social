import "./nicknames-collection-item.tact";
import "./DNS/index.tact";
import "./nft/metadata.tact";
import "./nft/DNS/index.tact";
import "@stdlib/ownable";
import "@stdlib/deploy";
import "./abstract/masterable.tact";
import "./abstract/parentable.tact";
import "./abstract/exitable.tact";
import "./abstract/excessable.tact";
import "./utils/json.tact";
import "./utils/string.tact";
//import "./user/iuser.tact";
message SetWebisteId{
    websiteId: Int;
    isPointerToADNL: Bool;
}
struct OneMaster{
    address: Address;
    startUserId: Int as uint64;
}
struct Masters{
    masters: map<Int as uint64, OneMaster> = emptyMap();
    size: Int as uint16;
}
message ExternalAdd{
    master: OneMaster;
}


contract NicknamesCollection with DnsCollection, DnsNFTCollection, OwnableTransferable{
    owner: Address;
    nicknamesCount: Int = 0;
    //ADNL link to website OR ADNL link to ton storage
    websiteId: Int = 0;
    // is it a pointer to ADNL website (true - ADNL website, false - ton storage)
    isPointerToADNL: Bool = true;

    masters: Masters = Masters{size: 0};

    override const storageReserve: Int = ton("0.1");
    override const CollectionName: String = "NetoTon nicknames";
    override const LogoURL: String = readFile("./nft/DNS/collection.svg", "utf8");
    override const MartketplaceURL: String = "marketplace.netoton.ton";
    override inline fun collectionDescription(): String{
        return beginString().concat(self.nicknamesCount.toString()).concat(" unique nicknames in NetoTon network, which can be linked to account.").toString();
    }
    override const BUILD_NFT_DATA_AS_SNAKE: Bool = true;
    const FEES: Int = ton("0.1");
    init(owner: Address, randomSeed: Int){
        self.owner = owner;
    }
    //deploy new DNS NFT
    receive(m: String){
        let slice = m.asSlice();
        validateNickName(slice);
        let domainHash = slice.hash();
        let dataBin = self.initOfIT(domainHash);
        let nftAddress = contractAddress(dataBin);
        //not an owner - creating nickname costs a lot
        if(sender() != self.owner){
            self.ensureFee(slice);
            //create auction
            let auctionAddress = createAuction(nftAddress, InitialBid{bidder: sender(), value:0 }, sender());
            //deploy nft
            send(SendParameters{
            value: ton("0.05"),
            bounce: false,
            body: InitizlizeNickname{nickname: slice.asString(), owner: auctionAddress}.toCell(),
            to: nftAddress,
            data: dataBin.data,
            code: dataBin.code
            });
        }
        //owner - can easly for free create nicknames
        else {
            self.forward(nftAddress, InitizlizeNickname{nickname: slice.asString(), owner: sender()}.toCell(), true, null);
        }
    }

    //helper functions
    override fun at(domainHash: Int): Address {
        let i = self.initOfIT(domainHash);
        return contractAddress(i);
    }
    inline fun initOfIT(domainHash: Int): StateInit{
        return initOf NicknamesCollectionItem(myAddress(), domainHash);
    }
    inline fun ensureFee(slice: Slice): Int{
        //require 1 ton for slice > 6 bytes length
        let i: Int = ton("1");
        if(slice.bits() == 8){
            // 1000 TON required for 1 char nickname
            i = ton("1000");
        }
        else if(slice.bits() == 8*2){
            // 100 TON required for 2 char nickname
            i = ton("100");
        }
        else if(slice.bits() == 8*3){
            // 50 TON required for 3 char nickname
            i = ton("50");
        }
        else if(slice.bits() == 8*4){
            // 25 TON required for 4 char nickname
            i = ton("25");
        }
        else if(slice.bits() == 8*5){
            // 10 TON required for 5 char nickname
            i = ton("10");
        }
        else if(slice.bits() == 8*6){
            // 5 TON required for 6 char nickname
            i = ton("5");
        }
        require(context().value >= i + self.FEES, "Not enough funds");
        return i;
    }
    override fun getMasterContract(id: Int): Address{
        //binary search in self.masters
        return getMasterContractFromMaster(self.masters, id)!!;
    }
    //add master address
    receive(m: ExternalAdd){
        self.requireOwner();
        require(self.masters.size == 0 || self.masters.masters.get(self.masters.size - 1)!!.startUserId < m.master.startUserId, "Invalid master found");
        self.masters.add(m.master);
    }

    receive(m: Deploy){
        self.requireOwner();
    }

    //update website ID
    receive(m: SetWebisteId){
        self.requireOwner();
        self.websiteId = m.websiteId;
        self.isPointerToADNL = m.isPointerToADNL;
    }
}
//binary search LAST element, which startUserId < id
fun getMasterContractFromMaster(masters: Masters, id: Int): Address? {
    let low = 0;
    let high = masters.size - 1;
    let result: Address? = null;
    while (low <= high) {
        let mid = (low + high) / 2;
        let midKey: OneMaster? = masters.masters.get(mid);
        if (midKey != null && midKey!!.startUserId < id) {
            result = midKey!!.address;
            low = mid + 1;
        }
        else{
            high = mid - 1;
        }
    }
    return result; // Default return if not found
}

extends mutates fun add(self: Masters, el: OneMaster){
    let newSize = self.size + 1;
    let newArr = self.masters;
    newArr.set(newSize-1, el);



    self = Masters{
        size: newSize,
        masters: newArr
    };
}

