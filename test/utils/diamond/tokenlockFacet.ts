import {expect} from '../../chai-setup';
import {parseEther} from 'ethers/lib/utils';
import type {TestContext} from './index';

export const setupHelpers = async ({TDFDiamond, user}: TestContext) => {
  return {
    deposit: async (amount: string) => {
      await expect(user.TDFDiamond.depositStake(parseEther(amount)), `deposit ${amount}`)
        .to.emit(TDFDiamond, 'DepositedTokens')
        .withArgs(user.address, parseEther(amount));
    },
    withdrawMax: {
      success: async (amount: string) => {
        await expect(user.TDFDiamond.withdrawMaxStake(), `withdrawMax.success ${amount}`)
          .to.emit(TDFDiamond, 'WithdrawnTokens')
          .withArgs(user.address, parseEther(amount));
      },
      none: async () => {
        await expect(user.TDFDiamond.withdrawMaxStake(), `withdrawMax.none`).to.not.emit(TDFDiamond, 'WithdrawnTokens');
      },
    },
    withdraw: {
      success: async (amount: string) => {
        await expect(user.TDFDiamond.withdrawStake(parseEther(amount)), `withdraw.success ${amount}`)
          .to.emit(TDFDiamond, 'WithdrawnTokens')
          .withArgs(user.address, parseEther(amount));
      },
      reverted: async (amount: string) => {
        await expect(
          user.TDFDiamond.withdrawStake(parseEther(amount)),
          `withdraw.reverted ${amount}`
        ).to.be.revertedWith('NOT_ENOUGHT_UNLOCKABLE_BALANCE');
      },
    },
    restakeMax: async () => {
      // TODO:
      await user.TDFDiamond.restakeMax();
    },
    restake: {
      reverted: async (amount: string) => {
        await expect(user.TDFDiamond.restake(parseEther(amount)), `restake.reverted ${amount}`).to.be.revertedWith(
          'NOT_ENOUGHT_UNLOCKABLE_BALANCE'
        );
      },
      success: async (amount: string) => {
        // TODO: `restake.success ${amount}`
        await user.TDFDiamond.restake(parseEther(amount));
      },
    },
  };
};
