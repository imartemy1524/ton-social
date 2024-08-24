

trait IUser{
    nickname: String?;
    userId: Int;

    inline fun userNickname(): String{
        if(self.nickname != null){return self.nickname!!;}
        return beginString().concat("id").concat(self.userId.toString()).toString();
    }
}