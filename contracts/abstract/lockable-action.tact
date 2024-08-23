

trait LockableAction{

    lockableAction: map<Int as uint64, Int as uint8>;


    inline fun lock(userId: Int){
        self.lockableAction.set(userId, 0);
    }
    inline fun unlock(userId: Int){
        self.lockableAction.del(userId);
    }

    inline fun requireNotLocked(userId: Int){
        require(self.lockableAction.get(userId) == null, "Please wait untill previous transaction finish!");
    }

}