import "./nft/subscribtion-sbts.tact";
import "./profit-calculator.tact";
import "./abstract/exitable.tact";
message SubscriptionInit{
    userFromId: Int as uint64;
    data: SubscribtionData;
    payed: Int as coins;
    profitAddress: Address;
}
message SubscriptionInitSuccess{
    userContractAddress: Address;
}
//sent from contract to user after sending profit process
message SubscribtionExcess{
    destroy: Bool;
}
message SubscribtionProfit{
    query_id: Int as uint64;
}
contract Subscription with SbtItem, UserPerformable {
    override const storageReserve: Int = ton("0.01");
    //who initialized the subsctiption
    ownerUserId: Int as uint64;

    // user id, who deploys this contract and gets the money
    userToId: Int as uint64;
    // master contract address
    master: Address;
    validUntil: Int as uint64 = 0;
    revokedAt: Int as uint64 = 0;
    subscribtion: SubscribtionData? = null;
    blocked: Bool = false;


    init(master: Address, fromUserId: Int, toUserId: Int){
        self.master = master;
        self.ownerUserId = fromUserId;
        self.userToId = toUserId;
    }
    //deployment of nft
    //requires min amount + 0.1 TON
    receive(m: SubscriptionInit){
        require(self.revokedAt == 0, "Revoked");
        require(sender() == self.userContractAddress(self.userToId), "only owner contract can initialize subscribtion");
        require(m.userFromId == self.ownerUserId, "wrong user id");
        let newValidUntil = now() + m.data.paymentPeriod * m.payed / m.data.paymentAmount;
        if(self.validUntil > now()){
            //extend payment period on the amount of the previous payment
            newValidUntil += self.validUntil - now();
        }
        self.subscribtion = m.data;
        self.validUntil = newValidUntil;
        self.forward(
            m.profitAddress,
            ProfitMessageSubscribtion{
                action: PROFIT_SUBSCRIBTION,
                //keep 1% of the payment
                keepAmount: m.payed * 1/100,
                subscriptionFromUserId: self.ownerUserId,
                subscriptionToUserId: self.userToId
            }.toCell(),
            false,
            null
        );
    }
    override inline fun isNftInitialized(): Bool{
        return self.validUntil > now() && self.subscribtion != null && self.revokedAt == 0;
    }
//    receive(m: ProfitMessagePongSubscribtion){
//        require(m.action == PROFIT_SUBSCRIBTION, "wrong profit message, should not happend!");
//        require(sender() == self.profitAddress, "Not a profit contract");
//        send(SendParameters{
//            to: self.userContractAddress(self.ownerUserId),
//            value: 0,
//            bounce: false,
//            mode: SendIgnoreErrors|(m.destroy?SendRemainingBalance|SendDestroyIfZero:SendRemainingValue),
//            body: SubscribtionExcess{destroy: m.destroy}.toCell()
//        });
//    }

    //sends profits to user and system, after that system pongs message back (ProfitMessagePongSubscribtion) and if destroy is true, then contract will be destroyed, otherwise, excess would be send
    override inline fun getMasterAddress(): Address{
        return self.master;
    }

}