import "./nft/subscribtion-sbts.tact";
import "./profit-calculator.tact";
import "./abstract/exitable.tact";
message SubscribtionInit{
    data: SubscribtionData;
}
message SubscribtionInitSuccess{
    userContractAddress: Address;
}
//sent from contract to user after sending profit process
message SubscribtionExcess{
    destroy: Bool;
}
message SubscribtionProfit{
    query_id: Int as uint64;
}
contract Subscribtion with SbtItem {
    override const storageReserve: Int = ton("0.01");
    //who initialized the subsctiption
    ownerUserId: Int as uint64;

    // user id, who deploys this contract and gets the money
    userToId: Int as uint64;
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
    receive(m: SubscribtionInit){
        self.requireNotBlocked();
        require(sender() == self.userContractAddress(self.userToId), "only owner contract can initialize subscribtion");
        if(self.subscribtion != null){
            //extend payment period on the amount of the previous payment
            m.data.paymentPeriod += m.data.paymentPeriod * self.releaseFunds(0, false) / m.data.paymentAmount;
        }
        self.subscribtion = m.data;
        self.validUntil = m.data.paymentPeriod + now();
        self.forward(
            self.userContractAddress(self.ownerUserId),
            SubscribtionInitSuccess{
                userContractAddress: self.userContractAddress(self.userToId)
            }.toCell(),
            false,
            null
        );
    }
    override inline fun isNftInitialized(): Bool{
        return self.validUntil > now() && self.subscribtion != null && self.revokedAt == 0;
    }
    receive(m: ProfitMessagePongSubscribtion){
        require(m.action == PROFIT_SUBSCRIBTION, "wrong profit message, should not happend!");
        require(sender() == contractAddress(initOf ProfitCalculator(self.master)), "Not a profit contract");
        self.blocked = false;
        send(SendParameters{
            to: self.userContractAddress(self.ownerUserId),
            value: 0,
            bounce: false,
            mode: SendIgnoreErrors|(m.destroy?SendRemainingBalance|SendDestroyIfZero:SendRemainingValue),
            body: SubscribtionExcess{destroy: m.destroy}.toCell()
        });
    }

    //sends profits to user and system, after that system pongs message back (ProfitMessagePongSubscribtion) and if destroy is true, then contract will be destroyed, otherwise, excess would be send
    override inline fun releaseFunds(queryId: Int, destroy: Bool): Int{
        if(self.subscribtion != null){
            let amount = self.calculateCurrentAmount(destroy);

            let systemFee: Int = self.getSystemFee(amount);
            let reward: Int = amount - systemFee;
            //send profit to user
            send(SendParameters{
                to: self.userContractAddress(self.userToId),
                value: reward,
                bounce: false,
                mode: SendIgnoreErrors,
                body: SubscribtionProfit{query_id: queryId}.toCell()
            });
            //send profit to system
            send(SendParameters{
                to: contractAddress(initOf ProfitCalculator(self.master)),
                value: min(systemFee + ton("0.05"), myBalance() - reward - ton("0.01")),
                bounce: false,
                mode: SendIgnoreErrors,
                body: ProfitMessageSubscribtion{action: PROFIT_SUBSCRIBTION, keepAmount: systemFee, destroy}.toCell()
            });

            if(self.validUntil > now()){
                self.validUntil = now();
            }
            self.subscribtion = null;
            self.blocked = true;
            return self.subscribtion!!.paymentAmount - systemFee - reward;
        }
        return 0;
    }

    inline fun calculateCurrentAmount(destroy: Bool): Int{
        let amount: Int = self.subscribtion!!.paymentAmount;
        let timePassedFromStart: Int = (self.subscribtion!!.paymentPeriod - self.validUntil + now());
        amount = min(self.subscribtion!!.paymentAmount * timePassedFromStart / self.subscribtion!!.paymentPeriod + (destroy?self.subscribtion!!.cacelationFee:0), amount);
        return amount;
    }
    override inline fun getMasterAddress(): Address{
        return self.master;
    }

}