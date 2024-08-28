#!/usr/bin/bash

git clone https://github.com/imartemy1524/tact-plus-plus
cd tact-plus-plus || exit
npm install yarn
yarn install
npm run gen || exit
npm run build || exit
rm -rf ../node_modules/@tact-lang/compiler/dist
mv dist ../node_modules/@tact-lang/compiler/
cd ..
rm -rf tact-plus-plus
