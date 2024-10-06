extends fun stringToInt(self: Slice): Int {
    // Cast the String as a Slice for parsing

    // A variable to store the accumulated number
    let acc: Int = 0;

    // Loop until the String is empty
    while (!self.empty()) {
        let char: Int = self.loadUint(8); // load 8 bits (1 byte) from the Slice
        //check if char in range 0-9a-z

        acc = (acc * 10) + (char - 48);     // using ASCII table to get numeric value
        // Note, that this approach would produce unexpected results
        //   when the starting String contains non-numeric characters!
    }

    // Produce the resulting number
    return acc;
}
