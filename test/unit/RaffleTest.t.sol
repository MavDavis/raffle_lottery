// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Test} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test{
            Raffle raffle;
            HelperConfig helperConfig;

            uint256 subscriptionId;
            bytes32 gasLane;
            uint256 automationUpdateInterval;
            uint256 entranceFee;
            uint32 callbackGasLimit;
            address vrfCoordinatorV2_5;
            address link;
            address account;

            address public PLAYER = makeAddr("player");
            uint256 public constant PLAYER_STARTING_BALANCE = 10 ether;
            // Deploy the Raffle contract and HelperConfig
      function setUp() public {
         DeployRaffle deployRaffle = new DeployRaffle();
         (raffle, helperConfig) = deployRaffle.run();
         HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
         // Set the variables from the config
               subscriptionId = config.subscriptionId;
               gasLane = config.gasLane; 
               automationUpdateInterval = config.automationUpdateInterval;
               entranceFee = config.entranceFee;
               callbackGasLimit = config.callbackGasLimit;
               vrfCoordinatorV2_5 = config.vrfCoordinatorV2_5;
               link = config.link;
               account = config.account;


         }

        function testRaffleInitialization() public view {
         assertEq(uint256(raffle.getRaffleState()), uint256(Raffle.RaffleState.OPEN));
         } 
         function testRaffleEntranceFeeReverts() public {
            vm.prank(PLAYER);
            vm.expectRevert(Raffle.Raffle_RevertValueIsLowerThanEntranceFee.selector);
            raffle.acceptsUserToEnterRaffle();
         }
      //    find why this test is failing
         function testAcceptsUserToEnterRaffle() public {
            vm.prank(PLAYER);
            vm.deal(PLAYER, PLAYER_STARTING_BALANCE);
            raffle.acceptsUserToEnterRaffle{value: entranceFee}();
            emit log_uint(entranceFee); // Should print 10000000000000000
            assertEq(raffle.getPlayer(0), PLAYER);
         }
    }
