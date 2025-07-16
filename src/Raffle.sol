// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

/*
* @Title A ruffle smart contract that takes in users for a bet and picks a random winner
* @dev Implements chainLink VRV v2.5
* @author Mavsdavis
* @notice cc: Title
 **/
contract Raffle{
    uint256 immutable private i_entranceFee;
    constructor(uint256 entranceFee){
        i_entranceFee = entranceFee; //ethers
    }
    function pickWinner()view public returns (address){
        
    }
    function acceptsUserToEnterRaffle(address User)payable public {
        
    }
    // getters
    function getEntranceFee()view public returns  (uint256){
        return i_entranceFee;
    }
}