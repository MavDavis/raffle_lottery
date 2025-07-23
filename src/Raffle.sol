// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/*
* @Title A ruffle smart contract that takes in users for a bet and picks a random winner
* @dev Implements chainLink VRV v2.5
* @author Mavsdavis
* @notice cc: Title
 **/
contract Raffle is VRFConsumerBaseV2Plus {
    enum RaffleState { OPEN, CALCULATING}
    // Chainlink VRF Variables
    uint256 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint256 private immutable i_entranceFee;
    // contract immutable
    uint256 private immutable i_interval;
    uint256 private immutable i_timestamp;

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    /* States */
    address private s_recentWinner;
    address payable[] private s_listOfUsers;
    RaffleState private s_raffleState;

    /* Events */
    event Ruffle_addedNewUser(address indexed user);
    event Raffle_WinnerPicked(address indexed winner);
    /**
     * Errors
     */

    error Raffle_RevertValueIsLowerThanEntranceFee();
    error Raffle__Transfer__Failed();
    error Raffle__Cannot__Acept__User__Atm();

    constructor(
        uint256 subscriptionId,
        bytes32 gasLane, // keyHash
        uint256 interval,
        uint256 entranceFee,
        uint32 callbackGasLimit,
        address vrfCoordinatorV2
    ) VRFConsumerBaseV2Plus(vrfCoordinatorV2) {
        i_gasLane = gasLane;
        i_interval = interval;
        i_subscriptionId = subscriptionId;
        i_entranceFee = entranceFee;
        s_raffleState = RaffleState.OPEN;
        i_timestamp = block.timestamp;
        i_callbackGasLimit = callbackGasLimit;
        // uint256 balance = address(this).balance;
        // if (balance > 0) {
        //     payable(msg.sender).transfer(balance);
        // }
    }

    function pickWinner() external  returns (address) {
        // check time spent
        if ((block.timestamp - i_timestamp) < i_interval) {
            revert();
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_gasLane,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
        requestId;
    }

    function acceptsUserToEnterRaffle() external payable {
        if (msg.value <= i_entranceFee) {
            revert Raffle_RevertValueIsLowerThanEntranceFee();
        }
        if(s_raffleState == RaffleState.CALCULATING){
            revert Raffle__Cannot__Acept__User__Atm();
        }
        s_listOfUsers.push(payable(msg.sender));
        emit Ruffle_addedNewUser(msg.sender);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        uint256 d20Value = (randomWords[0] % 20) + 1;
        address payable recent_winner = s_listOfUsers[d20Value];
        s_recentWinner = recent_winner;
        s_raffleState = RaffleState.OPEN;
        (bool Success, )= recent_winner.call{value:address(this).balance}("");
        if(!Success){
            revert Raffle__Transfer__Failed();
        }
        s_listOfUsers = new address payable[](0);
        emit Raffle_WinnerPicked(s_recentWinner);
        // s_results[s_rollers[requestId]] = d20Value;
        // emit DiceLanded(requestId, d20Value);
    }
    // getters

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }
}
