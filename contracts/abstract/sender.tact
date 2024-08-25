


//trait Sender{
//    virtual const MinStorageFee: Int = ton("0.01");
//    virtual const ComputeFee: Int = ton("0.011");
//    inline fun sendWithMinStorage(paramsOld: SendParameters){
//        let mode: Int = SendRemainingValue;
//        let value: Int = 0;
//        let oldBalance = (myBalance() - context().value);
//        if (oldBalance < self.MinStorageFee) {
//            value = context().value  - self.ComputeFee - self.MinStorageFee;
//            mode = 0;
//        }
//        send(SendParameters{
//            value: value,
//            mode: mode,
//            to: paramsOld.to,
//            body: paramsOld.body,
//            code: paramsOld.code,
//            data: paramsOld.data
//        });
//    }
//}