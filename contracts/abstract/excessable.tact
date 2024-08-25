
trait Excessable{
    inline fun excess(address: Address, message: String){
        self.forward(address, message.asComment(), false, null);
    }
}