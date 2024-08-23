

trait LockableAction{

    lockableAction: map<Int as uint64, Bool>;


    inline fun lock(userId: Int){
        self.lockableAction.set(userId, true);
    }
    inline fun unlock(userId: Int){
        self.lockableAction.del(userId);
    }

    inline fun requireNotLocked(userId: Int){
        require(self.lockableAction.get(userId) == null, "Please wait untill previous transaction finish!");
    }

}