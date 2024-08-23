
trait Excessable{
    inline fun excess(address: Address, message: String){
        send(SendParameters{
            value: 0,
            mode: SendRemainingValue,
            body: message.asComment(),
            to: address,
        // do not bounce - this is excess :)
            bounce: false
        });
    }
}