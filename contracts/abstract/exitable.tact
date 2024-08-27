


trait Exitable{
    inline fun exitWithoutSaving() {
        commit();
        throw(0);
    }

}