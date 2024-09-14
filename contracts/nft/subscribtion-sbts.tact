// prove_ownership#04ded148 query_id:uint64 dest:MsgAddress
// forward_payload:^Cell with_content:Bool = InternalMsgBody;
message(0x04ded148) ProveOwnership {
    query_id: Int as uint64;
    dest: Address;
    forward_payload: Cell;
    with_content: Bool;
}

// ownership_proof#0524c7ae query_id:uint64 item_id:uint256 owner:MsgAddress
// data:^Cell revoked_at:uint64 content:(Maybe ^Cell) = InternalMsgBody;
message(0x0524c7ae) OwnershipProof {
    query_id: Int as uint64;
    item_id: Int as uint256;
    owner: Address;
    data: Cell;
    revoked_at: Int as uint64;
    content: Cell?;
}

message(0xc18e86d2) OwnershipProofBounced {
    query_id: Int as uint64;
}

// request_owner#d0c3bfea query_id:uint64 dest:MsgAddress
// forward_payload:^Cell with_content:Bool = InternalMsgBody;

message(0xd0c3bfea) RequestOwner {
    query_id: Int as uint64;
    dest: Address;
    forward_payload: Cell;
    with_content: Bool;
}

// owner_info#0dd607e3 query_id:uint64 item_id:uint256 initiator:MsgAddress owner:MsgAddress
// data:^Cell revoked_at:uint64 content:(Maybe ^Cell) = InternalMsgBody;

message(0x0dd607e3) OwnerInfo {
    query_id: Int as uint64;
    item_id: Int as uint256;
    initiator: Address;
    owner: Address;
    data: Cell;
    revoked_at: Int as uint64;
    content: Cell?;
}


// destroy#1f04537a query_id:uint64 = InternalMsgBody;
message(0x1f04537a) Destroy {
    query_id: Int as uint64;
}

// revoke#6f89f5e3 query_id:uint64 = InternalMsgBody;

message(0x6f89f5e3) Revoke {
    query_id: Int as uint64;
}

// take_excess#d136d3b3 query_id:uint64 = InternalMsgBody;

message(0xd136d3b3) TakeExcess {
    query_id: Int as uint64;
}
struct SubscribtionData{
    level: Int as uint8;
    paymentPeriod: Int as uint64;
    paymentAmount: Int as coins;
    cacelationFee: Int as coins;
}
struct IndividualContentSBT{
    data: SubscribtionData?;
    expiredAt: Int as uint64;
}

trait SbtItem with Masterable, UserOwnable, Exitable, Blockable{
    //who initialized the subsctiption
    ownerUserId: Int;
    //to whom the subscription is
    userToId: Int;
    master: Address;
    validUntil: Int;
    blocked: Bool;
    revokedAt: Int ;
    subscribtion: SubscribtionData?;
    virtual fun getSystemFee(oldValue: Int): Int{
        //return 2% of the value
        return oldValue/50;
    }

    receive(msg: GetStaticData){
        self.requireNotBlocked();
        self.reply(ReportStaticData{ query_id: msg.query_id, index_id: self.ownerUserId, collection: self.userContractAddress(self.userToId)}.toCell());
    }
    receive(msg: Transfer){
        throw(132);
    }
    receive(msg: ProveOwnership) {
        self.requireNotBlocked();
        require(self.isNftInitialized(), "Not Initiated");
        self.requireOwner();
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
                revoked_at: self.revokedAt,
                content
            }.toCell(),
            true, null
        );
        self.exitWithoutSaving();
    }
    receive(msg: RequestOwner) {
        self.requireNotBlocked();
        require(self.isNftInitialized(), "Not Initiated");
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
                revoked_at: self.revokedAt,
                content
            }.toCell(),
            true, null
        );

        self.exitWithoutSaving();
    }
    bounced(msg: bounced<OwnershipProof>) {
        self.forward(self.userContractAddress(self.ownerUserId), OwnershipProofBounced{query_id: msg.query_id}.toCell(), false, null);
        self.exitWithoutSaving();
    }
    //call when subscribtion is ended, to get excess funds back, if you don't want to continue it
    receive(msg: Destroy) {
        self.requireNotBlocked();
        require(self.isNftInitialized(), "Not Initiated");
        self.requireOwner();
        self.releaseFunds(msg.query_id, true);
    }

    //revoke subscribtion
    receive(msg: Revoke) {
        require(self.isNftInitialized(), "Not Initiated");
        self.requireNotBlocked();
        self.requireSenderIsUser(self.userToId);
        require(self.revokedAt == 0, "Already revoked");
        self.releaseFunds(msg.query_id, true);
        self.revokedAt = now();
    }


    inline fun getAuthority(): Address{
        let ans = self.userContractAddress(self.userToId);
        return ans;
    }
    get fun get_authority_address(): Address? {
        return self.getAuthority();
    }
    get fun get_revoked_time(): Int {
        return self.revokedAt;
    }

    get fun get_nft_data(): GetNftData {
        return GetNftData{
            is_initialized: self.isNftInitialized(),
            index: self.ownerUserId,
            collection_address: self.userContractAddress(self.userToId),
            owner_address: self.userContractAddress(self.ownerUserId),
            individual_content: self.getContent()
        };
    }
    inline fun getContent(): Cell{
        return IndividualContentSBT{
            data: self.subscribtion,
            expiredAt: self.validUntil

        }.toCell()
    }

    abstract inline fun isNftInitialized(): Bool;
    abstract inline fun releaseFunds(queryId: Int, isExit: Bool): Int;
}

