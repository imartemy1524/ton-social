struct Context{

}
message(0x1001) GetMessage {
    context: Slice;
}
message(0x1002) SetMessage {
    value: Cell;
    context: Slice;
}
message(0x1003) DeleteMessage {
    context: Slice;
}
message(0x1004) PongGet {
    keySignature: Int;
    value: Cell?;
    context: Slice;
}
message(0x1005) PongSet {
    keySignature: Int;
    oldValue: Cell?;
    newValue: Cell;
    context: Slice;
}
message(0x1006) PongDelete {
    keySignature: Int;
    oldValue: Cell?;
    context: Slice;
}

trait AsyncMap {
    virtual fun handleGet(value: Cell?, context: Slice){}
    virtual fun handleSet(oldValue: Cell?, newValue: Cell, context: Slice){}
    virtual fun handleDelete(oldValue: Cell?, context: Slice){}

    //functions, which one can call
    fun getValue(key: Cell, context: Slice){
        let id = key.hash();
        send(
        SendParameters{
            value: 0,
            mode: SendRemainingValue,
            body: GetMessage{
            context: context}.toCell(),
            to: self.addressOf(key),
        });
    }
    // If response to is null - the response would be send to this contract, and can be handled by handleSet
    fun setValue(key: Cell, value: Cell, context: Slice){
        let b = initOf ChildElement(myAddress(), key.hash());
        send(SendParameters{
                value: 0,
                mode: SendRemainingValue,
                body: SetMessage{
                    value: value,
                    context: context
                }.toCell(),
            to: addressOf(b),
            data: b.data,
            code: b.code,
        });
    }
    fun deleteValue(key: Cell, context: Slice){
        let b = initOf ChildElement(myAddress(), key.hash());
            send(SendParameters{
                value: 0,
                mode: SendRemainingValue,
                body: DeleteMessage{ context: context}.toCell(),
            to: addressOf(b),
            data: b.data,
            code: b.code,
        });
    }

    bounced(m: bounced<GetMessage>){
        self.handleGet(null, m.context);
    }
    bounced(m: bounced<DeleteMessage>){
        self.handleDelete(null, m.context);
    }
    receive(m: PongGet){
        self.requireSender(m.keySignature);
        self.handleGet(m.value, m.context);
    }
    receive(m: PongDelete){
        self.requireSender(m.keySignature);
        self.handleDelete(m.oldValue, m.context);
    }
    receive(m: PongSet){
        self.requireSender(m.keySignature);
        self.handleSet(m.oldValue, m.newValue, m.context);
    }
    fun addressOf(key: Cell): Address{
        let id = key.hash();
        let data: StateInit = initOf ChildElement(myAddress(), key);
        return addressOf(data);
    }
    inline fun requireSender(keySignature: Int){
        require(sender() == addressOf(initOf ChildElement(myAddress(), keySignature)));
    }

    get fun child_address(key: Cell): Address{
        let ans = self.addressOf(key);
        return ans;
    }
}


contract ChildElement{
    id: Int;
    value: Cell?;
    master: Address;
    init(master: Address, id: Int){
        self.master = master;
        self.id = id;
        self.value = null;
    }
    receive(m: GetMessage){
        self.requireMaster();
        self.pong(PongGet{
            value: self.value,
            context: m.context,
            keySignature: self.id
        }.toCell());
    }
    receive(m: SetMessage){
        self.requireMaster();
        let oldValue: Cell? = self.value;
        self.value = m.value;
        if(m.needResponse){
            send(SendParameters{
                value: 0,
                mode: SendRemainingValue,
                body: PongSet{
                    keySignature: self.id,
                    context: m.context,
                    oldValue,
                    newValue: m.value,
                }.toCell()
            });
        }
    }
    receive(m: DeleteMessage){
        self.requireMaster();
        let oldValue: Cell? = self.value;
        self.value = null;
        self.pong(PongDelete{
            context: m.context,
            keySignature: self.id,
            oldValue
        }.toCell(), SendRemainingBalance|SendDestroyIfZero);
    }

    fun requireMaster(){
        require(sender() == self.master);
    }

    fun pong(m: Cell, mode: Int){
        send(SendParameters{
        value: 0,
        mode: mode,
        body: m,
        to: self.master
        });
    }


    get fun value(): Cell?{
        return self.value;
    }
}