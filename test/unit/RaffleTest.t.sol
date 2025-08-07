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
             // Events
             event Ruffle_addedNewUser(address indexed user);
             event Raffle_WinnerPicked(address indexed winner);
            // Deploy the Raffle contract and HelperConfig
      function setUp() public {
         DeployRaffle deployRaffle = new DeployRaffle();
         (raffle, helperConfig) = deployRaffle.run();
          vm.deal(PLAYER, PLAYER_STARTING_BALANCE);

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
            raffle.acceptsUserToEnterRaffle{value: entranceFee}();
            address playerRecorded = raffle.getPlayer(0);
            assert(playerRecorded == PLAYER);
         }
         function testIfRaffleEmitsEvent()public{
            vm.prank(PLAYER);
            vm.expectEmit(true, false, false, false, address(raffle));
            emit Ruffle_addedNewUser(PLAYER);
            raffle.acceptsUserToEnterRaffle{value: entranceFee}();
         }
         function testDonotAcceptUsersIfRaffleISNotOpen()public{
            vm.prank(PLAYER);
            // if raffle state is calculating, it should revert;
            // actually call the function that changes the state to calculating which is pickWinner()
            // raffle.setRaffleState(Raffle.RaffleState.CALCULATING);
            raffle.acceptsUserToEnterRaffle{value: entranceFee}();
            vm.warp(block.timestamp + automationUpdateInterval + 1);
            vm.roll(block.number + 1);
            raffle.performUpkeep("");
            vm.expectRevert(Raffle.Raffle__Cannot__Acept__User__Atm.selector);
            raffle.acceptsUserToEnterRaffle{value: entranceFee}();

         }
    }
