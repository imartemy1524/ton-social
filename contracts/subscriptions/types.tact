message ExternalSubscribeToUser{
    subscribeToUserId: Int as uint64;
    level: Int as uint8;
}


message InternalStartSubscription{
    fromUserId: Int as uint64;
    level: Int as uint8;
}