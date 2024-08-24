
trait Excessable with Sender{
    inline fun excess(address: Address, message: String){
        self.sendWithMinStorage(SendParameters{
            value: 0,
            mode: SendRemainingValue,
            body: message.asComment(),
            to: address,
        // do not bounce - this is excess :)
            bounce: false
        });
    }
}