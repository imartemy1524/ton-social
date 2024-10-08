struct NftAuctionData {
    marketplaceFeeAddress: Address;
    marketplaceFeeFactor: Int;
    marketplaceFeeBase: Int;

    royaltyAddress: Address;
    royaltyFactor: Int;
    royaltyBase: Int;

    minBid: Int;
    maxBid: Int;
    minStep: Int;
    endTimestamp: Int;
    createdAtTimestamp: Int;

    stepTimeSeconds: Int;
    tryStepTimeSeconds: Int;

    nftOwnerAddress: Address?;
    nftAddress: Address;

    end: Bool;
    marketplaceAddress: Address;
    activated: Bool;
}
struct InitialBid{
    value: Int as coins;
    bidder: Address;
}

inline fun createAuction(nftAddress: Address, initialBid: InitialBid, marketplaceFeeAddress: Address): Address {

    let feesCell = beginCell()
        .storeAddress(marketplaceFeeAddress)
        .storeUint(1, 32) // factor
        .storeUint(100, 32) // base
        .storeAddress(marketplaceFeeAddress) // royalty address
        .storeUint(1, 32) // royalty factor
        .storeUint(100, 32) // royalty base
        .endCell();

    let bidsCell = beginCell()
        .storeCoins(initialBid.value) // min_bid
        .storeCoins(initialBid.value + ton("10000")) // max_bid
        .storeCoins(ton("0.1"))  // min_step
        .storeAddress(initialBid.bidder)      // last_member
        .storeCoins(initialBid.value)           //last_bid
        .storeUint(0, 32)       // last_bid_at
        .storeUint(now() + 3600, 32)   // end_time
        .storeUint(60*5, 32) // step_time
        .storeUint(60*5, 32) // try_step_time
        .endCell();

    let nftCell = beginCell()
        .storeBool(false).storeBool(false) // store null address
        .storeAddress(nftAddress); // nft address

    let data = beginCell()
        .storeBool(false) // end?
        .storeAddress(marketplaceFeeAddress) // mp_addr
        .storeBool(true) // activated
        .storeUint(now(), 32)
        .storeBool(false) // is_ended
        .storeRef(feesCell) // fees
        .storeRef(bidsCell) // bids
        .storeRef(nftCell.endCell()) // nft
        .endCell();
    let code = cell("te6cckECHQEABZMAART/APSkE/S88sgLAQIBIAIDAgFIBAUCKPIw2zyBA+74RMD/8vL4AH/4ZNs8GxwCAs4GBwKLoDhZtnm2eQQQgqqH8IXwofCH8KfwpfCd8JvwmfCX8JXwi/Cf8IwaIiYaGCIkGBYiIhYUIiAUIT4hHCD6INggtiD0INIgsRsaAgEgCAkCASAYGQT1AHQ0wMBcbDyQPpAMNs8+ELA//hDUiDHBbCO0DMx0x8hwACNBJyZXBlYXRfZW5kX2F1Y3Rpb26BSIMcFsI6DW9s84DLAAI0EWVtZXJnZW5jeV9tZXNzYWdlgUiDHBbCa1DDQ0wfUMAH7AOAw4PhTUhDHBY6EMzHbPOABgGxIKCwATIIQO5rKAAGphIAFcMYED6fhS10nCAvLygQPqAdMfghAFE42REroS8vSAQNch+kAw+HJw+GJ/+GTbPBwEhts8IMABjzgwgQPt+CP4UL7y8oED7fhCwP/y8oED8AKCEDuaygC5EvLy+FJSEMcF+ENSIMcFsfLhkwF/2zzbPOAgwAIMFQ0OAIwgxwDA/5IwcODTHzGLZjYW5jZWyCHHBZIwceCLRzdG9wghxwWSMHLgi2ZmluaXNoghxwWSMHLgi2ZGVwbG95gBxwWRc+BwAYpwIPglghBfzD0UyMsfyz/4Us8WUAPPFhLLACH6AssAyXGAGMjLBfhTzxZw+gLLasyCCA9CQHD7AsmDBvsAf/hif/hm2zwcBPyOwzAygQPt+ELA//LygQPwAYIQO5rKALny8vgj+FC+jhf4UlIQxwX4Q1IgxwWx+E1SIMcFsfLhk5n4UlIQxwXy4ZPi2zzgwAOSXwPg+ELA//gj+FC+sZdfA4ED7fLw4PhLghA7msoAoFIgvvhLwgCw4wL4UPhRofgjueMA+E4SDxARAiwCcNs8IfhtghA7msoAofhu+CP4b9s8FRIADvhQ+FGg+HADcI6VMoED6PhKUiC58vL4bvht+CP4b9s84fhO+EygUiC5l18DgQPo8vDgAnDbPAH4bfhu+CP4b9s8HBUcApT4TsAAjj1wIPglghBfzD0UyMsfyz/4Us8WUAPPFhLLACH6AssAyXGAGMjLBfhTzxZw+gLLasyCCA9CQHD7AsmDBvsA4w5/+GLbPBMcAvrbPPhOQFTwAyDCAI4rcCCAEMjLBVAHzxYi+gIWy2oVyx+L9NYXJrZXRwbGFjZSBmZWWM8WyXL7AJE04vhOQAPwAyDCAI4jcCCAEMjLBVAEzxYi+gITy2oSyx+LdSb3lhbHR5jPFsly+wCRMeKCCA9CQHD7AvhOWKEBoSDCABoUAMCOInAggBDIywX4Us8WUAP6AhLLassfi2UHJvZml0jPFsly+wCRMOJwIPglghBfzD0UyMsfyz/4Tc8WUAPPFhLLAIIImJaA+gLLAMlxgBjIywX4U88WcPoCy2rMyYMG+wAC8vhOwQGRW+D4TvhHoSKCCJiWgKFSELyZMAGCCJiWgKEBkTLijQpWW91ciBiaWQgaGFzIGJlZW4gb3V0YmlkIGJ5IGFub3RoZXIgdXNlci6ABwP+OHzCNBtBdWN0aW9uIGhhcyBiZWVuIGNhbmNlbGxlZC6DeIcIA4w8WFwA4cCCAGMjLBfhNzxZQBPoCE8tqEssfAc8WyXL7AAACWwARIIQO5rKAKmEgAB0IMAAk18DcOBZ8AIB8AGAAIPhI0PpA0x/TH/pA0x/THzAAyvhBbt3tRNDSAAH4YtIAAfhk0gAB+Gb6QAH4bfoAAfhu0x8B+G/THwH4cPpAAfhy1AH4aNQw+Gn4SdDSHwH4Z/pAAfhj+gAB+Gr6AAH4a/oAAfhs0x8B+HH6QAH4c9MfMPhlf/hhAFT4SfhI+FD4T/hG+ET4QsjKAMoAygD4Tc8W+E76Assfyx/4Us8WzMzJ7VQBqlR8");
    let g: StateInit = StateInit{ data, code };
    let to = contractAddress(g);
    send(SendParameters{
        to,
        code: g.code,
        data: g.data,
        value: initialBid.value + ton("0.02"),
        bounce: false,
        body: null
    });
    return to;

}