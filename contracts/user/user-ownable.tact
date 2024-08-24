


//IMPORTANT!!! Override getMasterAddress function in parent contract!
trait UserOwnable with UserPerformable{
    ownerUserId: Int;
    inline fun requireOwner(){
        self.requireSenderIsUser(self.ownerUserId);
    }
}