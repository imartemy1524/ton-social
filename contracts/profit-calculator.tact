const PROFIT_SUBSCRIBTION: Int = 1;
message(0x77777777) ProfitMessageSubscribtion{
    //PROFIT_* const
    action: Int as uint8;
    keepAmount: Int as coins;
    subscriptionFromUserId: Int as uint64;
    subscriptionToUserId: Int as uint64;
}
message ExcessFromProfitSubscription{
    success: Bool
}
message DeployProfitCalculator{
    initData: StateInit;
    body: Cell;
}

// Contract to calculate profit
contract ProfitCalculator with Masterable, Exitable, UserPerformable{
    override const storageReserve: Int = ton("0.02");
    counters: map<Int as uint8, Int as uint64>;
    master: Address;
    init(master: Address){
        self.master = master;
        self.counters = emptyMap();
        self.counters.set(PROFIT_SUBSCRIBTION, 0);
        self.counters.set(0, 0);
    }
    receive(deploy: DeployProfitCalculator) {
        self.requireMaster();
        self.forward(contractAddress(deploy.initData), deploy.body, true, deploy.initData);
    }


    receive(m: ProfitMessageSubscribtion){
        let fromSubscription = initOf Subscription(self.master, m.subscriptionFromUserId, m.subscriptionToUserId);
        require(sender() == contractAddress(fromSubscription), "only subscription contract can send profit message");
        self.counters.set(m.action, self.counters.get(PROFIT_SUBSCRIBTION)!! + 1);
        //reserver keepAmount and pong message back
        nativeReserve(m.keepAmount, ReserveExact | ReserveAddOriginalBalance);
        send(SendParameters{
            to: self.userContractAddress(m.subscriptionFromUserId),
            value: 0,
            bounce: false,
            mode: SendRemainingBalance | SendIgnoreErrors,
            body: ExcessFromProfitSubscription{success: true}.toCell()
        });
    }
    receive(m: Slice){
        //ok, probably...???
        self.exitWithoutSaving();
    }
    override fun getMasterAddress(): Address{
        return self.master;
    }

}