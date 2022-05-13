// SPDX-License-Identifier: AGPL-1.0

pragma solidity 0.8.9;
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "hardhat/console.sol";
import "./ITokenLock.sol";

contract ProofOfPresence is Context, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    struct Booking {
        uint256 cost;
        bool active;
    }
    struct Year {
        uint16 number;
        uint256 start;
        uint256 end;
    }

    ITokenLock public immutable wallet;

    mapping(address => mapping(uint16 => uint256)) internal _internalBalance;
    mapping(address => mapping(uint16 => EnumerableSet.UintSet)) internal _internalDates;
    mapping(address => mapping(uint16 => mapping(uint256 => Booking))) internal _bookings;
    Year[] internal _years;

    constructor(address _wallet) {
        wallet = ITokenLock(_wallet);
        _years.push(Year(2022, block.timestamp, 1672531199));
        _years.push(Year(2023, 1672531200, 1704067199));
        _years.push(Year(2024, 1704067200, 1735689599));
    }

    function book(uint256[] memory bookingDates) public {
        uint256 lastDate;
        uint256 totalPrice;
        for (uint256 i = 0; i < bookingDates.length; i++) {
            require(bookingDates[i] > block.timestamp, "date should be in the future");
            uint16 year = getYear(bookingDates[i]);
            require(year > uint16(0), "Reservations not yet allowed");
            require(EnumerableSet.add(_internalDates[_msgSender()][year], bookingDates[i]), "Booking already exists");
            // Simplistic pricing
            uint256 price = 1 ether;
            _bookings[_msgSender()][year][bookingDates[i]] = Booking(price, true);
            _internalBalance[_msgSender()][year] += price;

            if (lastDate < bookingDates[i]) lastDate = bookingDates[i];
            totalPrice += price;
        }
        wallet.restakeOrDepositAtFor(_msgSender(), _expectedStaked(_msgSender()), lastDate);
    }

    function getYear(uint256 tm) internal view returns (uint16) {
        for (uint16 i; i < _years.length; i++) {
            if (_years[i].start <= tm && _years[i].end >= tm) return _years[i].number;
        }
        return uint16(0);
    }

    function cancel(uint256[] memory cancellingDates) public {
        for (uint256 i = 0; i < cancellingDates.length; i++) {
            require(cancellingDates[i] > block.timestamp, "Can not cancel past booking");
            // check booking existance
            uint16 year = getYear(cancellingDates[i]);

            require(
                EnumerableSet.remove(_internalDates[_msgSender()][year], cancellingDates[i]),
                "Booking does not exists"
            );
            _internalBalance[_msgSender()][year] -= _bookings[_msgSender()][year][cancellingDates[i]].cost;
            delete _bookings[_msgSender()][year][cancellingDates[i]];
        }
    }

    function _expectedStaked(address account) internal view returns (uint256) {
        uint256 max;
        for (uint16 i = 0; i < _years.length; i++) {
            if (_years[i].end < block.timestamp) continue;
            uint256 amount = _internalBalance[account][_years[i].number];
            if (amount > max) max = amount;
        }
        return max;
    }

    function getDates(address account) public view returns (uint256[] memory) {
        return EnumerableSet.values(_internalDates[account][getYear(block.timestamp)]);
    }

    function getBooking(address account, uint256 _date) public view returns (uint256, uint256) {
        Booking storage booking = _bookings[account][getYear(_date)][_date];
        return (_date, booking.cost);
    }
}
