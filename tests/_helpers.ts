import {
    Blockchain,
    BlockchainTransaction,
    printTransactionFees,
    SandboxContract,
    TreasuryContract,
} from '@ton/sandbox';
import { User } from '../wrappers/User';
import { Master } from '../wrappers/Master';
import { beginCell, BitBuilder, BitReader, Builder, Cell, Dictionary, Slice, toNano } from '@ton/core';
import { sha256_sync } from '@ton/crypto';
import { readFile } from 'node:fs/promises';
import { readFileSync } from 'fs';

export interface SocialMedia {
    blockchain: Blockchain;
    userWallets: SandboxContract<TreasuryContract>[];
    userAccounts: SandboxContract<User>[];
    superMaster: SandboxContract<Master>;
    masterOwner: SandboxContract<TreasuryContract>;
    master: SandboxContract<Master>;
}
export const DefaultAvatar = "<svg viewBox='0 0 320 320' width='320' height=\"320\" xmlns=\"http://www.w3.org/2000/svg\" shape-rendering=\"crispEdges\"><path fill=\"rgb(213,229,230)\" d=\"M0 0 h20v10h-20z\"/><path fill=\"rgb(253,246,224)\" d=\"M20 0 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M30 0 h70v10h-70z\"/><path fill=\"rgb(253,246,224)\" d=\"M100 0 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M110 0 h210v10h-210z\"/><path fill=\"rgb(213,229,230)\" d=\"M0 10 h30v10h-30z\"/><path fill=\"rgb(253,246,224)\" d=\"M30 10 h20v10h-20z\"/><path fill=\"rgb(213,229,230)\" d=\"M50 10 h50v10h-50z\"/><path fill=\"rgb(253,246,224)\" d=\"M100 10 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M110 10 h50v10h-50z\"/><path fill=\"rgb(253,246,224)\" d=\"M160 10 h30v10h-30z\"/><path fill=\"rgb(213,229,230)\" d=\"M190 10 h130v10h-130z\"/><path fill=\"rgb(213,229,230)\" d=\"M0 20 h50v10h-50z\"/><path fill=\"rgb(253,246,224)\" d=\"M50 20 h20v10h-20z\"/><path fill=\"rgb(213,229,230)\" d=\"M70 20 h30v10h-30z\"/><path fill=\"rgb(253,246,224)\" d=\"M100 20 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M110 20 h40v10h-40z\"/><path fill=\"rgb(253,246,224)\" d=\"M150 20 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M160 20 h30v10h-30z\"/><path fill=\"rgb(253,246,224)\" d=\"M190 20 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M200 20 h120v10h-120z\"/><path fill=\"rgb(253,246,224)\" d=\"M0 30 h30v10h-30z\"/><path fill=\"rgb(213,229,230)\" d=\"M30 30 h40v10h-40z\"/><path fill=\"rgb(253,246,224)\" d=\"M70 30 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M80 30 h20v10h-20z\"/><path fill=\"rgb(253,246,224)\" d=\"M100 30 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M110 30 h30v10h-30z\"/><path fill=\"rgb(253,246,224)\" d=\"M140 30 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M150 30 h50v10h-50z\"/><path fill=\"rgb(253,246,224)\" d=\"M200 30 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M210 30 h110v10h-110z\"/><path fill=\"rgb(213,229,230)\" d=\"M0 40 h30v10h-30z\"/><path fill=\"rgb(253,246,224)\" d=\"M30 40 h20v10h-20z\"/><path fill=\"rgb(213,229,230)\" d=\"M50 40 h30v10h-30z\"/><path fill=\"rgb(253,246,224)\" d=\"M80 40 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M90 40 h10v10h-10z\"/><path fill=\"rgb(253,246,224)\" d=\"M100 40 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M110 40 h20v10h-20z\"/><path fill=\"rgb(253,246,224)\" d=\"M130 40 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M140 40 h60v10h-60z\"/><path fill=\"rgb(253,246,224)\" d=\"M200 40 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M210 40 h110v10h-110z\"/><path fill=\"rgb(213,229,230)\" d=\"M0 50 h50v10h-50z\"/><path fill=\"rgb(253,246,224)\" d=\"M50 50 h40v10h-40z\"/><path fill=\"rgb(213,229,230)\" d=\"M90 50 h20v10h-20z\"/><path fill=\"rgb(253,246,224)\" d=\"M110 50 h20v10h-20z\"/><path fill=\"rgb(213,229,230)\" d=\"M130 50 h70v10h-70z\"/><path fill=\"rgb(253,246,224)\" d=\"M200 50 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M210 50 h110v10h-110z\"/><path fill=\"rgb(213,229,230)\" d=\"M0 60 h190v10h-190z\"/><path fill=\"rgb(253,246,224)\" d=\"M190 60 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M200 60 h120v10h-120z\"/><path fill=\"rgb(213,229,230)\" d=\"M0 70 h90v10h-90z\"/><path fill=\"rgb(253,246,224)\" d=\"M90 70 h20v10h-20z\"/><path fill=\"rgb(213,229,230)\" d=\"M110 70 h50v10h-50z\"/><path fill=\"rgb(253,246,224)\" d=\"M160 70 h30v10h-30z\"/><path fill=\"rgb(213,229,230)\" d=\"M190 70 h130v10h-130z\"/><path fill=\"rgb(213,229,230)\" d=\"M0 80 h60v10h-60z\"/><path fill=\"rgb(253,246,224)\" d=\"M60 80 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M70 80 h30v10h-30z\"/><path fill=\"rgb(253,246,224)\" d=\"M100 80 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M110 80 h20v10h-20z\"/><path fill=\"rgb(253,246,224)\" d=\"M130 80 h30v10h-30z\"/><path fill=\"rgb(213,229,230)\" d=\"M160 80 h160v10h-160z\"/><path fill=\"rgb(213,229,230)\" d=\"M0 90 h20v10h-20z\"/><path fill=\"rgb(253,246,224)\" d=\"M20 90 h40v10h-40z\"/><path fill=\"rgb(213,229,230)\" d=\"M60 90 h10v10h-10z\"/><path fill=\"rgb(253,246,224)\" d=\"M70 90 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M80 90 h40v10h-40z\"/><path fill=\"rgb(253,246,224)\" d=\"M120 90 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M130 90 h190v10h-190z\"/><path fill=\"rgb(253,246,224)\" d=\"M0 100 h20v10h-20z\"/><path fill=\"rgb(213,229,230)\" d=\"M20 100 h50v10h-50z\"/><path fill=\"rgb(253,246,224)\" d=\"M70 100 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M80 100 h50v10h-50z\"/><path fill=\"rgb(253,246,224)\" d=\"M130 100 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M140 100 h180v10h-180z\"/><path fill=\"rgb(213,229,230)\" d=\"M0 110 h40v10h-40z\"/><path fill=\"rgb(253,246,224)\" d=\"M40 110 h30v10h-30z\"/><path fill=\"rgb(213,229,230)\" d=\"M70 110 h30v10h-30z\"/><path fill=\"rgb(253,246,224)\" d=\"M100 110 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M110 110 h30v10h-30z\"/><path fill=\"rgb(253,246,224)\" d=\"M140 110 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M150 110 h170v10h-170z\"/><path fill=\"rgb(213,229,230)\" d=\"M0 120 h30v10h-30z\"/><path fill=\"rgb(253,246,224)\" d=\"M30 120 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M40 120 h60v10h-60z\"/><path fill=\"rgb(253,246,224)\" d=\"M100 120 h20v10h-20z\"/><path fill=\"rgb(213,229,230)\" d=\"M120 120 h30v10h-30z\"/><path fill=\"rgb(253,246,224)\" d=\"M150 120 h30v10h-30z\"/><path fill=\"rgb(213,229,230)\" d=\"M180 120 h140v10h-140z\"/><path fill=\"rgb(213,229,230)\" d=\"M0 130 h20v10h-20z\"/><path fill=\"rgb(253,246,224)\" d=\"M20 130 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M30 130 h60v10h-60z\"/><path fill=\"rgb(253,246,224)\" d=\"M90 130 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M100 130 h20v10h-20z\"/><path fill=\"rgb(253,246,224)\" d=\"M120 130 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M130 130 h50v10h-50z\"/><path fill=\"rgb(253,246,224)\" d=\"M180 130 h20v10h-20z\"/><path fill=\"rgb(213,229,230)\" d=\"M200 130 h120v10h-120z\"/><path fill=\"rgb(213,229,230)\" d=\"M0 140 h20v10h-20z\"/><path fill=\"rgb(253,246,224)\" d=\"M20 140 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M30 140 h60v10h-60z\"/><path fill=\"rgb(253,246,224)\" d=\"M90 140 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M100 140 h20v10h-20z\"/><path fill=\"rgb(253,246,224)\" d=\"M120 140 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M130 140 h70v10h-70z\"/><path fill=\"rgb(253,246,224)\" d=\"M200 140 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M210 140 h110v10h-110z\"/><path fill=\"rgb(213,229,230)\" d=\"M0 150 h20v10h-20z\"/><path fill=\"rgb(253,246,224)\" d=\"M20 150 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M30 150 h50v10h-50z\"/><path fill=\"rgb(253,246,224)\" d=\"M80 150 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M90 150 h40v10h-40z\"/><path fill=\"rgb(253,246,224)\" d=\"M130 150 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M140 150 h60v10h-60z\"/><path fill=\"rgb(253,246,224)\" d=\"M200 150 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M210 150 h110v10h-110z\"/><path fill=\"rgb(213,229,230)\" d=\"M0 160 h20v10h-20z\"/><path fill=\"rgb(253,246,224)\" d=\"M20 160 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M30 160 h50v10h-50z\"/><path fill=\"rgb(253,246,224)\" d=\"M80 160 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M90 160 h40v10h-40z\"/><path fill=\"rgb(253,246,224)\" d=\"M130 160 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M140 160 h60v10h-60z\"/><path fill=\"rgb(253,246,224)\" d=\"M200 160 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M210 160 h110v10h-110z\"/><path fill=\"rgb(213,229,230)\" d=\"M0 170 h20v10h-20z\"/><path fill=\"rgb(253,246,224)\" d=\"M20 170 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M30 170 h40v10h-40z\"/><path fill=\"rgb(253,246,224)\" d=\"M70 170 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M80 170 h60v10h-60z\"/><path fill=\"rgb(253,246,224)\" d=\"M140 170 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M150 170 h50v10h-50z\"/><path fill=\"rgb(253,246,224)\" d=\"M200 170 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M210 170 h110v10h-110z\"/><path fill=\"rgb(213,229,230)\" d=\"M0 180 h30v10h-30z\"/><path fill=\"rgb(253,246,224)\" d=\"M30 180 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M40 180 h30v10h-30z\"/><path fill=\"rgb(253,246,224)\" d=\"M70 180 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M80 180 h70v10h-70z\"/><path fill=\"rgb(253,246,224)\" d=\"M150 180 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M160 180 h30v10h-30z\"/><path fill=\"rgb(253,246,224)\" d=\"M190 180 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M200 180 h120v10h-120z\"/><path fill=\"rgb(213,229,230)\" d=\"M0 190 h40v10h-40z\"/><path fill=\"rgb(253,246,224)\" d=\"M40 190 h30v10h-30z\"/><path fill=\"rgb(213,229,230)\" d=\"M70 190 h90v10h-90z\"/><path fill=\"rgb(253,246,224)\" d=\"M160 190 h30v10h-30z\"/><path fill=\"rgb(213,229,230)\" d=\"M190 190 h130v10h-130z\"/><path fill=\"rgb(213,229,230)\" d=\"M0 200 h320v10h-320z\"/><path fill=\"rgb(213,229,230)\" d=\"M0 210 h60v10h-60z\"/><path fill=\"rgb(196,215,187)\" d=\"M60 210 h90v10h-90z\"/><path fill=\"rgb(213,229,230)\" d=\"M150 210 h110v10h-110z\"/><path fill=\"rgb(209,187,215)\" d=\"M260 210 h30v10h-30z\"/><path fill=\"rgb(213,229,230)\" d=\"M290 210 h30v10h-30z\"/><path fill=\"rgb(213,229,230)\" d=\"M0 220 h30v10h-30z\"/><path fill=\"rgb(196,215,187)\" d=\"M30 220 h150v10h-150z\"/><path fill=\"rgb(213,229,230)\" d=\"M180 220 h70v10h-70z\"/><path fill=\"rgb(209,187,215)\" d=\"M250 220 h30v10h-30z\"/><path fill=\"rgb(253,246,224)\" d=\"M280 220 h10v10h-10z\"/><path fill=\"rgb(209,187,215)\" d=\"M290 220 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M300 220 h20v10h-20z\"/><path fill=\"rgb(213,229,230)\" d=\"M0 230 h10v10h-10z\"/><path fill=\"rgb(196,215,187)\" d=\"M10 230 h200v10h-200z\"/><path fill=\"rgb(213,229,230)\" d=\"M210 230 h40v10h-40z\"/><path fill=\"rgb(209,187,215)\" d=\"M250 230 h50v10h-50z\"/><path fill=\"rgb(213,229,230)\" d=\"M300 230 h20v10h-20z\"/><path fill=\"rgb(196,215,187)\" d=\"M0 240 h250v10h-250z\"/><path fill=\"rgb(209,187,215)\" d=\"M250 240 h50v10h-50z\"/><path fill=\"rgb(213,229,230)\" d=\"M300 240 h20v10h-20z\"/><path fill=\"rgb(196,215,187)\" d=\"M0 250 h250v10h-250z\"/><path fill=\"rgb(209,187,215)\" d=\"M250 250 h10v10h-10z\"/><path fill=\"rgb(196,215,187)\" d=\"M260 250 h10v10h-10z\"/><path fill=\"rgb(209,187,215)\" d=\"M270 250 h10v10h-10z\"/><path fill=\"rgb(196,215,187)\" d=\"M280 250 h10v10h-10z\"/><path fill=\"rgb(209,187,215)\" d=\"M290 250 h10v10h-10z\"/><path fill=\"rgb(213,229,230)\" d=\"M300 250 h20v10h-20z\"/><path fill=\"rgb(196,215,187)\" d=\"M0 260 h250v10h-250z\"/><path fill=\"rgb(209,187,215)\" d=\"M250 260 h10v10h-10z\"/><path fill=\"rgb(196,215,187)\" d=\"M260 260 h30v10h-30z\"/><path fill=\"rgb(209,187,215)\" d=\"M290 260 h10v10h-10z\"/><path fill=\"rgb(196,215,187)\" d=\"M300 260 h20v10h-20z\"/><path fill=\"rgb(196,215,187)\" d=\"M0 270 h240v10h-240z\"/><path fill=\"rgb(209,187,215)\" d=\"M240 270 h10v10h-10z\"/><path fill=\"rgb(196,215,187)\" d=\"M250 270 h70v10h-70z\"/><path fill=\"rgb(196,215,187)\" d=\"M0 280 h320v10h-320z\"/><path fill=\"rgb(196,215,187)\" d=\"M0 290 h320v10h-320z\"/><path fill=\"rgb(196,215,187)\" d=\"M0 300 h320v10h-320z\"/><path fill=\"rgb(196,215,187)\" d=\"M0 310 h320v10h-320z\"/><path fill=\"rgb(123,43,93)\" d=\"M120 230 h80v10h-80z\"/><path fill=\"rgb(123,43,93)\" d=\"M110 240 h100v10h-100z\"/><path fill=\"rgb(123,43,93)\" d=\"M110 250 h100v10h-100z\"/><path fill=\"rgb(123,43,93)\" d=\"M100 260 h120v10h-120z\"/><path fill=\"rgb(123,43,93)\" d=\"M100 270 h120v10h-120z\"/><path fill=\"rgb(123,43,93)\" d=\"M100 280 h120v10h-120z\"/><path fill=\"rgb(123,43,93)\" d=\"M100 290 h120v10h-120z\"/><path fill=\"rgb(123,43,93)\" d=\"M100 300 h20v10h-20z\"/><path fill=\"rgb(164,107,134)\" d=\"M120 300 h10v10h-10z\"/><path fill=\"rgb(123,43,93)\" d=\"M130 300 h90v10h-90z\"/><path fill=\"rgb(123,43,93)\" d=\"M100 310 h20v10h-20z\"/><path fill=\"rgb(164,107,134)\" d=\"M120 310 h10v10h-10z\"/><path fill=\"rgb(123,43,93)\" d=\"M130 310 h90v10h-90z\"/><path fill=\"rgb(34,36,37)\" d=\"M120 230 h80v10h-80z\"/><path fill=\"rgb(253,246,224)\" d=\"M110 240 h100v10h-100z\"/><path fill=\"rgb(253,246,224)\" d=\"M110 250 h100v10h-100z\"/><path fill=\"rgb(34,36,37)\" d=\"M100 260 h120v10h-120z\"/><path fill=\"rgb(34,36,37)\" d=\"M100 270 h120v10h-120z\"/><path fill=\"rgb(253,246,224)\" d=\"M100 280 h120v10h-120z\"/><path fill=\"rgb(253,246,224)\" d=\"M100 290 h120v10h-120z\"/><path fill=\"rgb(34,36,37)\" d=\"M100 300 h120v10h-120z\"/><path fill=\"rgb(34,36,37)\" d=\"M100 310 h120v10h-120z\"/><path fill=\"rgb(234,213,71)\" d=\"M120 60 h80v10h-80z\"/><path fill=\"rgb(234,213,71)\" d=\"M100 70 h120v10h-120z\"/><path fill=\"rgb(234,213,71)\" d=\"M90 80 h140v10h-140z\"/><path fill=\"rgb(234,213,71)\" d=\"M90 90 h40v10h-40z\"/><path fill=\"rgb(230,177,67)\" d=\"M130 90 h60v10h-60z\"/><path fill=\"rgb(234,213,71)\" d=\"M190 90 h40v10h-40z\"/><path fill=\"rgb(234,213,71)\" d=\"M80 100 h40v10h-40z\"/><path fill=\"rgb(230,177,67)\" d=\"M120 100 h10v10h-10z\"/><path fill=\"rgb(234,213,71)\" d=\"M130 100 h60v10h-60z\"/><path fill=\"rgb(241,227,127)\" d=\"M190 100 h10v10h-10z\"/><path fill=\"rgb(234,213,71)\" d=\"M200 100 h40v10h-40z\"/><path fill=\"rgb(234,213,71)\" d=\"M80 110 h30v10h-30z\"/><path fill=\"rgb(230,177,67)\" d=\"M110 110 h10v10h-10z\"/><path fill=\"rgb(234,213,71)\" d=\"M120 110 h80v10h-80z\"/><path fill=\"rgb(241,227,127)\" d=\"M200 110 h10v10h-10z\"/><path fill=\"rgb(234,213,71)\" d=\"M210 110 h30v10h-30z\"/><path fill=\"rgb(234,213,71)\" d=\"M80 120 h30v10h-30z\"/><path fill=\"rgb(230,177,67)\" d=\"M110 120 h10v10h-10z\"/><path fill=\"rgb(234,213,71)\" d=\"M120 120 h80v10h-80z\"/><path fill=\"rgb(241,227,127)\" d=\"M200 120 h10v10h-10z\"/><path fill=\"rgb(234,213,71)\" d=\"M210 120 h30v10h-30z\"/><path fill=\"rgb(234,213,71)\" d=\"M80 130 h30v10h-30z\"/><path fill=\"rgb(230,177,67)\" d=\"M110 130 h10v10h-10z\"/><path fill=\"rgb(234,213,71)\" d=\"M120 130 h80v10h-80z\"/><path fill=\"rgb(241,227,127)\" d=\"M200 130 h10v10h-10z\"/><path fill=\"rgb(234,213,71)\" d=\"M210 130 h30v10h-30z\"/><path fill=\"rgb(234,213,71)\" d=\"M80 140 h30v10h-30z\"/><path fill=\"rgb(230,177,67)\" d=\"M110 140 h10v10h-10z\"/><path fill=\"rgb(234,213,71)\" d=\"M120 140 h80v10h-80z\"/><path fill=\"rgb(241,227,127)\" d=\"M200 140 h10v10h-10z\"/><path fill=\"rgb(234,213,71)\" d=\"M210 140 h30v10h-30z\"/><path fill=\"rgb(234,213,71)\" d=\"M80 150 h30v10h-30z\"/><path fill=\"rgb(230,177,67)\" d=\"M110 150 h10v10h-10z\"/><path fill=\"rgb(234,213,71)\" d=\"M120 150 h80v10h-80z\"/><path fill=\"rgb(241,227,127)\" d=\"M200 150 h10v10h-10z\"/><path fill=\"rgb(234,213,71)\" d=\"M210 150 h30v10h-30z\"/><path fill=\"rgb(234,213,71)\" d=\"M80 160 h30v10h-30z\"/><path fill=\"rgb(230,177,67)\" d=\"M110 160 h10v10h-10z\"/><path fill=\"rgb(234,213,71)\" d=\"M120 160 h80v10h-80z\"/><path fill=\"rgb(241,227,127)\" d=\"M200 160 h10v10h-10z\"/><path fill=\"rgb(234,213,71)\" d=\"M210 160 h30v10h-30z\"/><path fill=\"rgb(234,213,71)\" d=\"M80 170 h30v10h-30z\"/><path fill=\"rgb(230,177,67)\" d=\"M110 170 h10v10h-10z\"/><path fill=\"rgb(234,213,71)\" d=\"M120 170 h80v10h-80z\"/><path fill=\"rgb(241,227,127)\" d=\"M200 170 h10v10h-10z\"/><path fill=\"rgb(234,213,71)\" d=\"M210 170 h30v10h-30z\"/><path fill=\"rgb(234,213,71)\" d=\"M80 180 h40v10h-40z\"/><path fill=\"rgb(230,177,67)\" d=\"M120 180 h10v10h-10z\"/><path fill=\"rgb(234,213,71)\" d=\"M130 180 h60v10h-60z\"/><path fill=\"rgb(241,227,127)\" d=\"M190 180 h10v10h-10z\"/><path fill=\"rgb(234,213,71)\" d=\"M200 180 h30v10h-30z\"/><path fill=\"rgb(230,177,67)\" d=\"M230 180 h10v10h-10z\"/><path fill=\"rgb(234,213,71)\" d=\"M90 190 h40v10h-40z\"/><path fill=\"rgb(241,227,127)\" d=\"M130 190 h10v10h-10z\"/><path fill=\"rgb(34,36,37)\" d=\"M140 190 h10v10h-10z\"/><path fill=\"rgb(241,227,127)\" d=\"M150 190 h40v10h-40z\"/><path fill=\"rgb(234,213,71)\" d=\"M190 190 h30v10h-30z\"/><path fill=\"rgb(230,177,67)\" d=\"M220 190 h10v10h-10z\"/><path fill=\"rgb(234,213,71)\" d=\"M90 200 h60v10h-60z\"/><path fill=\"rgb(34,36,37)\" d=\"M150 200 h20v10h-20z\"/><path fill=\"rgb(234,213,71)\" d=\"M170 200 h50v10h-50z\"/><path fill=\"rgb(230,177,67)\" d=\"M220 200 h10v10h-10z\"/><path fill=\"rgb(234,213,71)\" d=\"M100 210 h100v10h-100z\"/><path fill=\"rgb(230,177,67)\" d=\"M200 210 h20v10h-20z\"/><path fill=\"rgb(230,177,67)\" d=\"M120 220 h80v10h-80z\"/><path fill=\"rgb(34,36,37)\" d=\"M110 140 h20v10h-20z\"/><path fill=\"rgb(253,246,224)\" d=\"M130 140 h10v10h-10z\"/><path fill=\"rgb(34,36,37)\" d=\"M140 140 h10v10h-10z\"/><path fill=\"rgb(34,36,37)\" d=\"M170 140 h20v10h-20z\"/><path fill=\"rgb(253,246,224)\" d=\"M190 140 h10v10h-10z\"/><path fill=\"rgb(34,36,37)\" d=\"M200 140 h10v10h-10z\"/><path fill=\"rgb(34,36,37)\" d=\"M110 150 h20v10h-20z\"/><path fill=\"rgb(253,246,224)\" d=\"M130 150 h10v10h-10z\"/><path fill=\"rgb(34,36,37)\" d=\"M140 150 h10v10h-10z\"/><path fill=\"rgb(34,36,37)\" d=\"M170 150 h20v10h-20z\"/><path fill=\"rgb(253,246,224)\" d=\"M190 150 h10v10h-10z\"/><path fill=\"rgb(34,36,37)\" d=\"M200 150 h10v10h-10z\"/><path fill=\"rgb(34,36,37)\" d=\"M110 160 h40v10h-40z\"/><path fill=\"rgb(34,36,37)\" d=\"M170 160 h40v10h-40z\"/><path fill=\"rgb(34,36,37)\" d=\"M120 170 h20v10h-20z\"/><path fill=\"rgb(34,36,37)\" d=\"M180 170 h20v10h-20z\"/></svg>"//readFileSync(__dirname+'/../avatar.jpg', {encoding: 'binary'});

export async function deployMaster(): Promise<SocialMedia> {
    const blockchain = await Blockchain.create();
    const userWallets = await blockchain.createWallets(10);
    const [masterOwner] = await blockchain.createWallets(1);
    const master = blockchain.openContract(await Master.fromInit());
    await master.send(masterOwner.getSender(), { value: toNano('0.2') }, { $$type: 'Deploy', queryId: 0n });

    let userAccounts: SandboxContract<User>[] = [];
    for (const userWallet of userWallets) {
        const { transactions } = await master.send(
            userWallet.getSender(),
            { value: toNano('1') },
            { $$type: 'Register' },
        );
        // printTransactionFees(transactions);
        const userId = await master.getUsersCount();
        const user = blockchain.openContract(User.fromAddress(await master.getUser(userId)));
        //@ts-ignore
        expect(transactions as BlockchainTransaction[]).toHaveTransaction({
            from: master.address,
            to: user.address,
            success: true,
        });
        expect(await user.getOwner().then((e) => e.toString())).toBe(userWallet.address.toString());
        userAccounts.push(user);
    }

    return { blockchain, userWallets, userAccounts, master, masterOwner, superMaster: master };
}



//parsing onchain data in NFT
//reference: https://stackblitz.com/edit/ton-onchain-nft-parser?file=src%2Fmain.ts
//https://docs.ton.org/develop/dapps/asset-processing/metadata
interface ChunkDictValue {
    content: Buffer;
}
interface NFTDictValue {
    content: Buffer;
}
class NftOnChainDataParserClass {
    flattenSnakeCell(cell: Cell) {
        let c: Cell | null = cell;

        const bitResult = new BitBuilder(100000);
        while (c) {
            const cs = c.beginParse();
            if (cs.remainingBits === 0) {
                break;
            }

            const data = cs.loadBits(cs.remainingBits);
            bitResult.writeBits(data);
            c = c.refs && c.refs[0];
        }

        const endBits = bitResult.build();
        const reader = new BitReader(endBits);

        return reader.loadBuffer(reader.remaining / 8);
    }

    bufferToChunks(buff: Buffer, chunkSize: number) {
        const chunks: Buffer[] = [];
        while (buff.byteLength > 0) {
            chunks.push(buff.slice(0, chunkSize));
            // eslint-disable-next-line no-param-reassign
            buff = buff.slice(chunkSize);
        }
        return chunks;
    }

    makeSnakeCell(data: Buffer): Cell {
        const chunks = this.bufferToChunks(data, 127);

        if (chunks.length === 0) {
            return beginCell().endCell();
        }

        if (chunks.length === 1) {
            return beginCell().storeBuffer(chunks[0]).endCell();
        }

        let curCell = beginCell();

        for (let i = chunks.length - 1; i >= 0; i--) {
            const chunk = chunks[i];

            curCell.storeBuffer(chunk);

            if (i - 1 >= 0) {
                const nextCell = beginCell();
                nextCell.storeRef(curCell);
                curCell = nextCell;
            }
        }

        return curCell.endCell();
    }

    encodeOffChainContent(content: string) {
        let data = Buffer.from(content);
        const offChainPrefix = Buffer.from([1]);
        data = Buffer.concat([offChainPrefix, data]);
        return this.makeSnakeCell(data);
    }

    ChunkDictValueSerializer = {
        serialize(src: ChunkDictValue, builder: Builder) {},
        parse: (src: Slice): ChunkDictValue => {
            const snake = this.flattenSnakeCell(src.loadRef());
            return { content: snake };
        },
    };

    parseChunkDict(cell: Slice): Buffer {
        const dict = cell.loadDict(Dictionary.Keys.Uint(32), this.ChunkDictValueSerializer);

        let buf = Buffer.alloc(0);
        for (const [_, v] of dict) {
            buf = Buffer.concat([buf, v.content]);
        }
        return buf;
    }
}

type IDataAttribute = {
    trait_type: string;
    value: string;
}
interface NftData{
    name?: string;
    description?: string;
    image?: string;
    image_data?: Buffer;
    marketplace?: string;

    attributes?: IDataAttribute[]
}
export function decodeNftDataOnchain(data: Cell): NftData {
    const NftOnChainDataParser = new NftOnChainDataParserClass();
    const NFTDictValueSerializer = {
        serialize(src: NFTDictValue, builder: Builder) {},
        parse(src: Slice): NFTDictValue {
            const ref = src.loadRef().asSlice();

            const start = ref.loadUint(8);
            if (start === 0) {
                const snake = NftOnChainDataParser.flattenSnakeCell(ref.asCell());
                return { content: snake };
            }

            if (start === 1) {
                return { content: NftOnChainDataParser.parseChunkDict(ref) };
            }

            return { content: Buffer.from([]) };
        },
    };
    let slice = data.asSlice();

    slice.loadUint(8);
    const ans = slice.loadDict(Dictionary.Keys.Buffer(32), NFTDictValueSerializer);
    const ansMapped: Map<bigint, NFTDictValue> = new Map(
        Array.from(ans).map(([k, v]) => [BigInt('0x' + k.toString('hex')), v]),
    );
    const keys = new Map<bigint, string>(
        ['image', 'name', 'description', 'image', 'marketplace', 'image_data', 'attributes'].map((key) => [sha256(key), key]),
    );

    const realGoodObject: NftData = {};
    for (const [keyHash, valueBuffer] of ansMapped) {
        const realKey: string = keys.get(keyHash)!;
        if(!realKey){
            console.warn('key not found', keyHash);
        }
        let value: Buffer|string = valueBuffer.content;
        if(realKey === 'attributes'){
            let v = value!.toString();
            value = JSON.parse(v);
        }
        else if(realKey != 'image_data'){
            value = value!.toString();
        }
        //@ts-ignore
        realGoodObject[realKey! as unknown as 'image'] = value!;
    }
    return realGoodObject;
}

export function sha256(s: string): bigint {
    return BigInt('0x' + sha256_sync(s).toString('hex'));
}
