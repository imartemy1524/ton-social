import "../nft/subscribtion-sbts.tact";

struct IndividualContentAchivement{
//    userId: Int as uint64;
    type: Int as uint8;
    owner: Address;
}


trait AbstractAchivementSbt with Masterable, Exitable{
//    ownerUserId: Int;
    owner: Address?;
    type: Int;
    master: Address;
    index: Int;

    fun requireOwner() {
        nativeThrowUnless(132, self.owner != null && sender() == self.owner!!);
    }

    abstract fun collectionAddress(): Address;
    receive(msg: GetStaticData){
        self.reply(ReportStaticData{
        query_id: msg.query_id, index_id: self.index, collection: self.collectionAddress()}.toCell());
    }
    receive(msg: Transfer){
        throw(132);
    }
    inline fun requireNftInitialized(){
        require(self.owner != null, "Not Initiated");
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
            item_id: self.index,
            owner: self.owner!!,
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
        item_id: self.index,
        initiator: sender(),
        owner: self.owner!!,
        data: msg.forward_payload,
        revoked_at: 0,
        content
        }.toCell(),
        true, null
        );

        self.exitWithoutSaving();
    }
    bounced(msg: bounced<OwnershipProof>) {
        self.forward(self.owner!!, OwnershipProofBounced{
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
            to: self.owner!!,
            bounce: false,
            body: Excesses{ query_id: msg.query_id}.toCell()
        });
        self.owner = null;
    }

    //revoke subscribtion
    receive(msg: Revoke) {
        self.requireNftInitialized();
        //should not be revoked
        throw(132);
    }

    get fun get_authority_address(): Address? {
        let ans = self.collectionAddress();
        return ans;
    }
    get fun get_revoked_time(): Int {
        return 0;
    }

    get fun get_nft_data(): GetNftData {
        return GetNftData{
            is_initialized: self.owner != null,
            index: self.index,
            collection_address: self.collectionAddress(),
            owner_address: self.owner!!,
            individual_content: self.getContent()
        };
    }
    inline fun getContent(): Cell{
        return IndividualContentAchivement{
            owner: self.owner!!,
            type: self.type
        }.toCell()
    }
}

