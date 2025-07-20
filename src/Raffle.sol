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
    /** Errors */
    error Raffle_RevertValueIsLowerThanEntranceFee();
    /* States */
    uint256 immutable private i_entranceFee;
    uint256 immutable private i_interval;
    uint256 immutable private s_timestamp;
    address[] public listOfUsers;
    /* Events */
    event Ruffle_addedNewUser(address indexed user);
    constructor(uint256 entranceFee, address _vrfCoordinator) VRFConsumerBaseV2Plus (_vrfCoordinator){
        i_entranceFee = entranceFee;
        i_interval = 60000;
        s_timestamp = block.timestamp;
         //ethers
    }
    function pickWinner()view external returns (address){
        // check time spent
        if((block.timestamp - s_timestamp) < i_interval){
            revert ();
        }
         requestId = s_vrfCoordinator.requestRandomWords(
            // VRFV2PlusClient.RandomWordsRequest({
            //     keyHash: s_keyHash,
            //     subId: s_subscriptionId,
            //     requestConfirmations: requestConfirmations,
            //     callbackGasLimit: callbackGasLimit,
            //     numWords: numWords,
            //     extraArgs: VRFV2PlusClient._argsToBytes(
            //         // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
            //         VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            //     )
            // })
        );
        return listOfUsers[0];
        
    }
    function acceptsUserToEnterRaffle()payable external {
       if( msg.value <= i_entranceFee){
            revert Raffle_RevertValueIsLowerThanEntranceFee();
       }
        listOfUsers.push(msg.sender);
        emit Ruffle_addedNewUser(msg.sender);
        
    }
       function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        // uint256 d20Value = (randomWords[0] % 20) + 1;
        // s_results[s_rollers[requestId]] = d20Value;
        // emit DiceLanded(requestId, d20Value);
    }
    // getters
    function getEntranceFee()view public returns  (uint256){
        return i_entranceFee;
    }
}