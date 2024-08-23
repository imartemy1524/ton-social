# TON Social network

### What is this project about?

There are many social networks in the world, but none of them are **fully** decentralized. 

What is it, a fully decentralized social network? It is a social network that is not controlled by any single entity, but by the blockchain. 

This projects contains implementation of a social network on the TON blockchain, and **all** data about users/posts/comments/likes stored and managed **directly** by smart contract, written in tact language.

### Features

-  Users can create accounts (many accounts) from one wallet, and use this account to communicate with other users and objects.
-  Users can create posts, edit them, like them and comment them.
-  Users can answer other comments, like them and edit.
-  TODO: Users can have unique nickname in the system and can be found by this nickname.

#### Is it fully decentralized?
Right now, there are 2 "centralized" parts in the system: 
1. Moderation. We're going to get rid of it in the future, introducing "reputation", s.t. users with good reputation can moderate the content, getting a little profit from it.
2. Frontend. It's opensource, but doesn't stored directly on blockchain (yet). Anyway, it can be accessed by `.ton` domain name.



## Project structure

-   `contracts` - source code of all the smart contracts of the project and their dependencies.
-   `wrappers` - wrapper classes (implementing `Contract` from ton-core) for the contracts, including any [de]serialization primitives and compilation functions.
-   `tests` - tests for the contracts.
-   `scripts` - scripts used by the project, mainly the deployment scripts.

## How to use

### Build

`npx blueprint build` or `yarn blueprint build`

### Test

`npx blueprint test` or `yarn blueprint test`

### Deploy or run another script

`npx blueprint run` or `yarn blueprint run`

### Add a new contract

`npx blueprint create ContractName` or `yarn blueprint create ContractName`
