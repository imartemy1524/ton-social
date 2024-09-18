#!/usr/bin/bash

git clone https://github.com/imartemy1524/tact-plus-plus
cd tact-plus-plus || exit
npm install yarn
yarn install
npm run gen || exit
npm run build || exit
# check if dir exists
if [ -d "../node_modules/@tact-lang/compiler" ]; then
  echo "NPM detected..."
  rm -rf ../node_modules/@tact-lang/compiler/dist
  mv dist ../node_modules/@tact-lang/compiler/
  cd ..
  rm -rf tact-plus-plus
fi
if [ -d "../node_modules/.pnpm/@tact-lang+compiler@1.5.1/node_modules/@tact-lang/compiler/dist" ]; then
  echo "PNPM detected..."
  rm -rf ../node_modules/.pnpm/@tact-lang+compiler@1.5.1/node_modules/@tact-lang/compiler/dist
  mv dist ../node_modules/.pnpm/@tact-lang+compiler@1.5.1/node_modules/@tact-lang/compiler/
  cd ..
  rm -rf tact-plus-plus
fi
