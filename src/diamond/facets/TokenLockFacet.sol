// SPDX-License-Identifier: AGPL-1.0

pragma solidity 0.8.9;
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../libraries/AppStorage.sol";
import "../libraries/StakeManagerLib.sol";

contract TokenLockFacet is Modifiers, Context, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using StakeManagerLib for AppStorage;
    // TODO: this events are duplicated in the library
    event DepositedTokens(address account, uint256 amount);
    event WithdrawnTokens(address account, uint256 amount);

    function deposit(uint256 amount) public {
        // _deposit(_msgSender(), amount, block.timestamp);
        s.deposit(_msgSender(), amount, block.timestamp);
    }

    function withdrawMax() public returns (uint256) {
        return s.withdrawMax(_msgSender());
    }

    function withdraw(uint256 requested) public returns (uint256) {
        return s.withdraw(_msgSender(), requested);
    }

    function restakeMax() public {
        s.restakeMax(_msgSender());
    }

    function restake(uint256 requestedAmount) public {
        s.restake(_msgSender(), requestedAmount);
    }

    function unlockedAmount(address account) public view returns (uint256) {
        return s.unlockedAmount(account);
    }

    function lockedAmount(address account) public view returns (uint256) {
        return s.lockedAmount(account);
    }

    function balanceOf(address account) public view returns (uint256) {
        return s._balances[account];
    }

    function depositsFor(address account) public view returns (Deposit[] memory) {
        return s._deposits[account];
    }
}
