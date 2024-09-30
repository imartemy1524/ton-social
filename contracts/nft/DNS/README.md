# How does TON DNS works

As there aren't any good articles in the internet about how TON DNS works, I decided to write one.

There is a [standard](https://github.com/ton-blockchain/TIPs/issues/81), which I still don't understand in the way, it presented in the article, thus I will try to explain it in my own words.

## What is TON DNS

TON DNS is a decentralized domain name system on TON blockchain. It allows to "register" domain names and 'link' them to next objects (domain may be linked to few of them at the same time).:

-  Wallet addresses (category=`sha256("wallet")`)
-  Websites, hosted either in [ADNL network](https://docs.ton.org/learn/networking/adnl) OR in [TON Storage](https://blog.ton.org/ton-storage) (category=`sha256("site")`)
-  Ton Storage object (category=`sha256("storage")`)
-  Redirects (category=`sha256("next_resolver")`) - to "redirect" the request to another smart contract (for example, one can build subdomains this way, by "cutting" parts of the domain by ".", and "redirecting" resolve request to other smart contracts)

## How does resolving works?

In case of `func`, your smart-contract needs to implement `(int, cell) dnsresolve(slice subdomain, int category) method_id` getter function

In case of `tact`, you can use `DNSResolver` trait from standard `"@stdlib/dns"`library and implement `    override fun doResolveDNS(subdomain: Slice, category: Int): DNSResolveResult` method. 


## How does resolving process works?

[//]: # (All domains in TON are **subdomain**. For example, domain `my-bob.ton` has "root" part `ton`, and "subdomain" part `my-bob`.)

Suppose, that one wants to resolve domain `telegram.pavel-durov.ton`.

1. When anyone tries to resolve it, he first "converts" domain into machine-readable format (which would be passed as `subdomain` parameter to `dnsresolve` function): he splits domain by `.`, revert it and join by `\0` (null-terminated string): 
    ```typescript
    function convertDomainToSubdomain(domain: string): string {
        return domain.split('.').reverse().join('\0') + '\0';
        //or
        return '\0' + domain.split('.').reverse().join('\0') + '\0';
    }
    
    ```

    For example, our domain `telegram.pavel-durov.ton` would be converted to `\0ton\0pavel-durov\0telegram\0` OR `ton\0pavel-durov\0telegram\0` (first `\0` is optional).

2. Sets `N = ` root smart contract, which is stored in [blockchain config #4](https://tonviewer.com/config#4)
    
    Sets `subdomain = "\0ton\0pavel-durov\0telegram\0"`.

3. Calls `dnsresolve(subdomain, ???)`  function of the contract `N`. 
    
    - If contract supports "redirecting" this request to another smart contract (by returning redirect request on `dnsresolve(subdomain, sha256("next_resolver"))`), then:
        1. machine-readable domain is being "cut" by `first returned integer` (in bits). 
            
            **For example**, if one resolves `\0ton\0pavel-durov\0telegram\0` at the [root smart contract](https://tonviewer.com/Ef_lZ1T4NCb2mwkme9h2rJfESCE0W34ma9lWp7-_uY3zXDvq?section=code), it would return `4 * 8` as `first returned integer` (in bits).
 
            This would cut the domain to `\0pavel-durov\0telegram\0`.
            
        2. At the second parameter, *redirect cell* is returned im [this format](#redirect-to-another-domain).
            
            One parses `address` from there and repeats process `#3`, setting `N = ` returned address (repeats the process for subdomain string).
    
    - If contract supports `dnsresolve(subdomain, sha256("site"))`, then it returns response in [ton storage return format](#ton-storage) or [ADNL format](#adnl-format) (depends on the contract implementation).
    - If contract supports `dnsresolve(subdomain, sha256("wallet"))`, then it returns response in [address format](#address-format).
    - If contract supports `dnsresolve(subdomain, sha256("storage"))`, then it returns response in [ton storage return format](#ton-storage).
   
P.S. To get all supported categories, call `dnsresolve(subdomain, 0)` - it would return `map<Int as uint256, Cell>`, where `int` is category and `Cell` is some [response formats](#response-formats).

### Example for `telegram.pavel-durov.ton` domain (trying to get WEBSITE)

1. **Request** to root smart contract (`dnsresolve("\0pavel-durov\0telegram\0", sha256("next_resolver"))"`) from [blockchain config #4](https://tonviewer.com/config#4).
2. It crops `.ton` part (by returning `4*8` in first parameter) - domain being croped to `\0pavel-durov\0telegram\0` and redirected to [root TON DNS smart contract](https://tonviewer.com/EQC3dNlesgVD8YbAazcauIrXBPfiVhMMr5YYk2in0Mtsz0Bz?section=code)
3. **Request** to [root TON DNS smart contract](https://tonviewer.com/EQC3dNlesgVD8YbAazcauIrXBPfiVhMMr5YYk2in0Mtsz0Bz?section=code) (`dnsresolve("\0pavel-durov\0telegram\0", sha256("next_resolver"))`,
4. It crops `.pavel-durov` part (by returning length of `.pavel-durov` string * 8) domain being croped to `\0telegram\0` - and redirected to [pavel-durov TON DNS smart contract](https://tonviewer.com/Ef_lZ1T4NCb2mwkme9h2rJfESCE0W34ma9lWp7-_uY3zXDvq) (this smart contract is unique for each domain name like `pavel-durov`, `igor-durov` etc.).
5. _Suppose_, that the owner of this contract created redirect for subdomains, by setting `Subdomains` field in [TON DNS](https://dns.ton.org/#pavel-durov)
6. **Request** to [pavel-durov TON DNS smart contract](https://tonviewer.com/Ef_lZ1T4NCb2mwkme9h2rJfESCE0W34ma9lWp7-_uY3zXDvq) (`dnsresolve("\0telegram\0", sha256("next_resolver"))`).
7. It crops `.` part  and redirects request with `telegram\0` to configured `Subdomains` address above.
8. **Request** to `Subdomains` smart contract, which is (supposed) configured above. Now there are 2 possible ways to resolve this domain:
    1. `Subdomains` smart contract resolves `telegram` domain **DIRECTLY** to some website(`dnsresolve("telegram\0", sha256("site"))`) in either TON Storage using [ton storage return format](#ton-storage) or in [ADNL ton network](https://docs.ton.org/learn/networking/adnl) using [ADNL format](#adnl-format) by responding on `dnsresolve("telegram\0", sha256("site"))` request.
    2. `Subdomains` smart contract redirects resolving this domain name to another smart contract (`dnsresolve("telegram\0", sha256("next_resolver"))`), by cropping (for example) `telegram` part and returning `\0` to another smart contract.
        
        1. Then the same process repeats for resolved contract (`dnsresolve("\0", sha256("site"))`), passing `\0` as input
        2. This contract returns response either in [ton storage return format](#ton-storage) or [ADNL format](#adnl-format) `(0, responseCell)`
    


### Let's quickly repeat the process again:
1. Request to `root` with `telegram.pavel-durov.ton`  => `redirect(to=TonDns, with="telegram.pavel-durov")`
2. Request to `TonDns` with `telegram.pavel-durov` => `redirect(to=pavelDurovNFT, with="telegram")`
3. Request to `pavelDurovNFT` with `telegram` => `redirect(to=Subdomains, with="telegram")`
4. Request to `Subdomains` with `telegram` => 
   - `redirect(to=WebsiteResolver, with="")`
        1. Request to `WebsiteResolver` with `.` => `response(WebsiteLocationg=PavelDurovWebsite)`. **Resolved**.    
   - `response(WebsiteLocationg=PavelDurovWebsite)`. **Resolved**.

## Response formats

### Redirect request to another contract 
Returns for `category=sha256("next_resolver")`
```tact
fun dnsResolveNext(address: Address): Cell {
    return beginCell()
        .storeUint(0xba93, 16)
        .storeAddress(address)
        .endCell();
}
```

### Ton Storage
Returns for `category=sha256("site")`  or `category=sha256("storage")`
```tact
inline fun dnsResolveWebsiteTonStorage(cellID: Int): Cell{
    return beginCell()
        .storeUint(0x7473, 16)
        .storeUint(cellID, 256)
        .endCell();
}
```
### ADNL format
Returns for `category=sha256("site")` 
```tact
inline fun dnsResolveWebsiteADNL(cellID: Int): Cell{
    return beginCell()
        .storeUint(0xad01, 16)
        .storeUint(cellID, 256)
        .storeUint(0, 8) //flags
        .endCell();
}
```

### Address format
Returns for `category=sha256("wallet")`
```tact
fun dnsResolveWallet(address: Address): Cell {
    return beginCell()
        .storeUint(0x9fd3, 16)
        .storeAddress(address)
        .storeUint(0, 8)
        .endCell();
}
```