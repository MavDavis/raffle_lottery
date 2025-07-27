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
    uint256 private immutable s_lastTimeStamp;

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
    // error Raffle__UpkeepNotNeeded(address payable balance, uint256 usersLength, uint256 raffleState );

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
        s_lastTimeStamp = block.timestamp;
        i_callbackGasLimit = callbackGasLimit;
        // uint256 balance = address(this).balance;
        // if (balance > 0) {
        //     payable(msg.sender).transfer(balance);
        // }
    }
/**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. Implicity, your subscription is funded with LINK.
     */
    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        // override
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = s_listOfUsers.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0"); // can we comment this out?
    }

    /**
     * @dev Once `checkUpkeep` is returning `true`, this function is called
     * and it kicks off a Chainlink VRF call to get a random winner.
     */
    function performUpkeep(bytes calldata /* performData */ ) external /*override*/ {
        (bool upkeepNeeded,) = checkUpkeep("");
        // require(upkeepNeeded, "Upkeep not needed");
        if (!upkeepNeeded) {
            // revert Raffle__UpkeepNotNeeded(address(this).balance, s_listOfUsers.length, uint256(s_raffleState));
        }

        s_raffleState = RaffleState.CALCULATING;

        // Will revert if subscription is not set and funded.
        // uint256 requestId = s_vrfCoordinator.requestRandomWords(
        //     VRFV2PlusClient.RandomWordsRequest({
        //         keyHash: i_gasLane,
        //         subId: i_subscriptionId,
        //         requestConfirmations: REQUEST_CONFIRMATIONS,
        //         callbackGasLimit: i_callbackGasLimit,
        //         numWords: NUM_WORDS,
        //         extraArgs: VRFV2PlusClient._argsToBytes(
        //             // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
        //             VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
        //         )
        //     })
        // );
        // // Quiz... is this redundant?
        // emit RequestedRaffleWinner(requestId);
    }
    function pickWinner() external  returns (address) {
        // check time spent
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
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
        return s_listOfUsers[requestId];
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
