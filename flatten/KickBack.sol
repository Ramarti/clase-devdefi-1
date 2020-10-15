// Dependency file: @openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol

// pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// Root file: contracts/KickBack.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;

// import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

contract KickBack {
    using SafeMath for uint256;

    enum EventState {
        Registration,
        Cancelled,
        Started,
        Ended
    }

    struct Participant {
      address addr;
      bool didAssist;
      bool didReclaim;
    }
    mapping(address => Participant) public participants;

    uint256 public deposit;
    uint256 public reclaimedContributions;
    uint256 public duration;
    address public admin;
    uint256 limitOfParticipants;
    uint256 public payoutAmount;
    uint256 public registered;
    uint256 public totalAttended;
    uint256 public endedAt;

    EventState public eventState;

    // Events
    event StateChange(uint state);
    event Register(address indexed participant);
    event Reclaim(address indexed participant, uint256 amount);
    event CancelEvent(uint256 endedAt);
    event Withdraw(address indexed participant, uint256 amount);
    event Attended(address indexed participant, uint256 totalAttended);

    modifier onlyAdmin() {
        require(admin == msg.sender,"Sender not authorized");
        _;
    }

    modifier isState(EventState _state) {
        require(eventState == _state,"Tryng to operate in wrong event state");
        _;
    }

    modifier isEventFinished() {
        require(eventState == EventState.Cancelled || eventState == EventState.Ended,"Event not finished");
        _;
    }

    modifier canWithdraw {
        require(payoutAmount > 0, 'payout is 0');
        Participant storage participant = participants[msg.sender];
        require(isRegistered(msg.sender), 'you did not register');
        require(isAttended(msg.sender), 'you did not attend');
        require(participant.didReclaim == false, 'you already withdrawn');
        _;
    }

    constructor(uint256 _deposit, uint256 _limitOfParticipants) public {
      deposit = _deposit;
      admin = msg.sender;
      limitOfParticipants = _limitOfParticipants;
      changeState(EventState.Registration);
    }

    function isAttended(address _addr) public view returns (bool){
        if (!isRegistered(_addr)) {
            return false;
        }
        return participants[_addr].didAssist;
    }

    function isRegistered(address _addr) view public returns (bool){
        return participants[_addr].addr != _addr;
    }

    function register() external payable isState(EventState.Registration) {
        require(registered < limitOfParticipants, 'participant limit reached');
        require(isRegistered(msg.sender), 'already registered');
        require(msg.value == deposit, 'must send exact deposit amount');

        registered = registered.add(1);
        participants[msg.sender] = Participant(msg.sender, true, false);

        emit Register(msg.sender);
    }

    function startEvent() external isState(EventState.Registration) onlyAdmin {
        changeState(EventState.Started);
    }

    function withdraw() external isEventFinished canWithdraw {
        participants[msg.sender].didReclaim = true;
        msg.sender.transfer(payoutAmount);
        emit Withdraw(msg.sender, payoutAmount);
    }

    function markAttendance(address _participant) external onlyAdmin isState(EventState.Started) {
      participants[_participant].didAssist = true;
      totalAttended = totalAttended.add(1);
      require(totalAttended <= registered, 'should not have more attendees than registered');
      emit Attended(_participant, totalAttended);
    }

    function finalizeEvent() external onlyAdmin isState(EventState.Started) {
        endedAt = block.timestamp;

        require(totalAttended <= registered, 'should not have more attendees than registered');

        if (totalAttended > 0) {
            payoutAmount = uint256(address(this).balance).div(totalAttended);
        }

        changeState(EventState.Ended);
    }

    function cancel() external onlyAdmin isState(EventState.Registration) {
        payoutAmount = deposit;
        changeState(EventState.Cancelled);
    }

    function changeState(EventState _newState) internal {
        eventState = _newState;
        emit StateChange(uint(_newState));
    }

}
