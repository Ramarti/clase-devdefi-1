//SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

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
