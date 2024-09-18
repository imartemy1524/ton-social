# TON Social network

### What is this project about?

There are many social networks in the world, but none of them are **fully** decentralized. 

What is it, a fully decentralized social network? It is a social network that is not controlled by any single entity, but by the blockchain. 

This projects contains implementation of a social network on the TON blockchain, where **all** data about users/posts/comments/likes stored and managed **directly** by smart contract, written in tact language.


### Conception

Let's take a look, how it works. First of all, there is [Account](./contracts/user.tact) - the main ~~object~~ contract, through which real users (wallets V5, V4 and etc.) communicates with other ~~objects~~ smart contracts (by sending messages to them through wallets, for example TonKeeper). 

You can think of it as a typical "account", which exists in any social media. 
It implements NFT interface, thus the ownership can be sold/transferred to other wallet (official way to sold accounts).

Owner can set account's avatar (it can be stored either directly in blockchain or in any IPFS-like/TON-Storage-like service, contract support any of them), nickname (he can purchase NFT with unique nickname), and some other data.



Now, what **account** can do?
1. Each account can create [posts](./contracts/post.tact) (share some text data), which would be linked to it. 
2. Other users can leave [comments](./contracts/comment.tact) to the post or to other comments (answering them).
3. Users can [like](./contracts/abstract/likeable.tact) any [post](./contracts/post.tact) or [comments](./contracts/comment.tact) (in future, like can contain some value, to support user).
4. Users can receive [achievements](./contracts/achievement.tact) (SBT) for doing actions.

### Features

- [x] Users can create accounts (many accounts) from one wallet, and use this account to communicate with other users and objects.
- [x] Users can create posts, edit them, like them and comment them.
- [x] Users can answer other comments, like them and edit.
- [x] Users receive SBT-achievements, when they done some actions (add 1,10,100,... likes, posts, subscriptions, comments)
- [ ]  Users can have unique nickname in the system and can be found by this nickname.





#### Is it fully decentralized?
Right now, there are 2 "centralized" parts in the system: 
1. Moderation. We're going to get rid of it in the future, introducing "reputation", s.t. users with good reputation can moderate the content, getting a little profit from it.
2. Frontend. It's opensource, but doesn't stored directly on blockchain (yet). Anyway, it can be accessed by `.ton` domain name.


## Developing

To start developing, you need to install the dependencies:

```bash
npm install
```
You can use either `npm`,`yarn`, `pnpm` or any other package manager you like.

After installation, it is required to polyfill the TACT language, which is used in the project (see [tact-plus-plus](https://github.com/imartemy1524/tact-plus-plus)). 
To do this, you need to run the following command:

```bash
./polyfilltact.sh
```

## Project structure

-   `contracts` - source code of all the smart contracts of the project and their dependencies.
-   `wrappers` - wrapper classes (implementing `Contract` from ton-core) for the contracts, including any [de]serialization primitives and compilation functions.
-   `tests` - tests for the contracts.
-   `scripts` - scripts used by the project, mainly the deployment scripts.

## How to use

### Build

`npx blueprint build`

### Test

`npx blueprint test`

### Deploy or run another script

`npx blueprint run`

