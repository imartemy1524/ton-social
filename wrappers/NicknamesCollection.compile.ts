import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/nicknames-collection.tact',
    options:{
        debug: true
    }
};
