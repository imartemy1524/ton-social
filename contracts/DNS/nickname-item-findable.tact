

trait NicknameItemFindable{
    nicknameCollection: Address?;
    fun nickNameContractAt(nickname: String): StateInit{
        let hash = nickname.asSlice().hash();
        return initOf NicknamesCollectionItem(self.nicknameCollection!!, hash);
    }
}