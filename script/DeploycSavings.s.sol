// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {cSavings} from "../src/cSavings.sol";

contract DeploycSavings is Script {
    function run() external returns (cSavings) {
        // Read from environment variables
        address cusd = vm.envAddress("CUSD_ADDRESS");
        uint256 initialRewardRate = vm.envUint("INITIAL_REWARD_RATE");
        
        vm.startBroadcast();
        cSavings savings = new cSavings(cusd, initialRewardRate);
        vm.stopBroadcast();

        console.log("cSavings deployed at:", address(savings));
        console.log("On network with cUSD:", cusd);
        console.log("Initial reward rate:", initialRewardRate);
        return savings;
    }
}