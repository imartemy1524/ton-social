const PROFIT_SUBSCRIBTION: Int = 1;

message(0x112912F) ProfitMessage{
    //PROFIT_* const
    action: Int as uint8;
    keepAmount: Int as coins;
    forwardPayload: Slice as remaining;
}
message(0x112912F) ProfitMessageSubscribtion{
    //PROFIT_* const
    action: Int as uint8;
    keepAmount: Int as coins;
    destroy: Bool;
}
message(0x212912F) ProfitMessagePong{
    //PROFIT_* const
    action: Int as uint8;
    forwardPayload: Slice as remaining;
}
message(0x312912F) ProfitMessagePongSubscribtion{
    //PROFIT_* const
    action: Int as uint8;
    destroy: Bool;
}

message DeployProfitCalculator{
    initData: StateInit;
    body: Cell;
}

// Contract to calculate profit
contract ProfitCalculator with Masterable, Exitable{
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


    receive(m: ProfitMessage){
        if(m.action != PROFIT_SUBSCRIBTION && m.action != 0){
            throw(1);
        }
        self.counters.set(m.action, self.counters.get(PROFIT_SUBSCRIBTION)!! + 1);
        //reserver keepAmount and pong message back
        nativeReserve(m.keepAmount + myBalance(), ReserveExact|ReserveAddOriginalBalance);
        send(SendParameters{
            to: sender(),
            value: 0,
            bounce: false,
            mode: SendRemainingValue|SendIgnoreErrors,
            body: ProfitMessagePong{
                action: m.action,
                forwardPayload: m.forwardPayload
            }.toCell()
        });
    }
    receive(m: Slice){
        //ok, probably...???
        self.exitWithoutSaving();
    }
}