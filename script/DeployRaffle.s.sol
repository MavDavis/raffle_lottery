// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRaffle is Script{
    function run()public{

        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        vm.startBroadcast(config.account);
     
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.subscriptionId,
            config.gasLane,
            config.automationUpdateInterval,
            config.callbackGasLimit,
            config.vrfCoordinatorV2_5
        );
        vm.stopBroadcast();
        console.log("Raffle deployed to: ", address(raffle));
    }
    // function deployRaffle()public return (Raffle, HelperConfig){

    // }
}