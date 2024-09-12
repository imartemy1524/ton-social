import "../nft/subscribtion-sbts.tact";

struct IndividualContentAchivement{
    userId: Int as uint64;
    type: Int as uint8;
}


trait AbstractAchivementSbt with Masterable, UserOwnable, Exitable{
    ownerUserId: Int;
    type: Int;
    master: Address;
    index: Int;

    abstract fun collectionAddress(): Address;
    receive(msg: GetStaticData){
        self.reply(ReportStaticData{
        query_id: msg.query_id, index_id: self.index, collection: self.collectionAddress()}.toCell());
    }
    receive(msg: Transfer){
        throw(132);
    }
    inline fun requireNftInitialized(){
        require(self.ownerUserId != 0, "Not Initiated");
    }
    receive(msg: ProveOwnership) {
        self.requireOwner();
        self.requireNftInitialized();
        let content: Cell? = null;
        if (msg.with_content) {
            content = self.getContent();
        }
        self.forward(
        msg.dest,
        OwnershipProof {
        query_id: msg.query_id,
        item_id: self.ownerUserId,
        owner: self.userContractAddress(self.ownerUserId),
        data: msg.forward_payload,
        revoked_at: 0,
        content
        }.toCell(),
        true, null
        );
        self.exitWithoutSaving();
    }
    receive(msg: RequestOwner) {
        self.requireNftInitialized();
        let content: Cell? = null;
        if (msg.with_content) {
            content = self.getContent();
        }
        self.forward(
        msg.dest,
        OwnerInfo {
        query_id: msg.query_id,
        item_id: self.ownerUserId,
        initiator: sender(),
        owner: self.userContractAddress(self.ownerUserId),
        data: msg.forward_payload,
        revoked_at: 0,
        content
        }.toCell(),
        true, null
        );

        self.exitWithoutSaving();
    }
    bounced(msg: bounced<OwnershipProof>) {
        self.forward(self.userContractAddress(self.ownerUserId), OwnershipProofBounced{
        query_id: msg.query_id}.toCell(), false, null);
        self.exitWithoutSaving();
    }
    //call when subscribtion is ended, to get excess funds back, if you don't want to continue it
    receive(msg: Destroy) {
        self.requireNftInitialized();
        self.requireOwner();
        send(SendParameters{
        value: 0,
        mode: SendRemainingBalance | SendDestroyIfZero,
        to: self.userContractAddress(self.ownerUserId),
        bounce: false,
        body: Excesses{
        query_id: msg.query_id}.toCell()
        });
        self.ownerUserId = 0;
    }

    //revoke subscribtion
    receive(msg: Revoke) {
        self.requireNftInitialized();
        //should not be revoked
        throw(132);
    }

    get fun get_authority_address(): Address? {
        return self.collectionAddress();
    }
    get fun get_revoked_time(): Int {
        return 0;
    }

    get fun get_nft_data(): GetNftData {
        return GetNftData{
        is_initialized: self.ownerUserId != 0,
        index: self.index,
        collection_address: self.collectionAddress(),
        owner_address: self.ownerUserId != 0 ? self.userContractAddress(self.ownerUserId) : NullAddress,
        individual_content: self.getContent()
        };
    }
    inline fun getContent(): Cell{
        return IndividualContentAchivement{
        userId: self.ownerUserId,
        type: self.type
        }.toCell()
    }
}

