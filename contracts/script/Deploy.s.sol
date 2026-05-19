// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {SessionFiWallet} from "../src/SessionFiWallet.sol";
import {SessionManager} from "../src/SessionManager.sol";

contract Deploy is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        SessionFiWallet sessionFiWallet = new SessionFiWallet();
        SessionManager sessionManager = new SessionManager();

        vm.stopBroadcast();

        // Log deployment info
        console.log("====== SessionFi Deployment ======");
        console.log("SessionFiWallet deployed at:", address(sessionFiWallet));
        console.log("SessionManager deployed at:", address(sessionManager));
        console.log("Block number:", block.number);
    }
}
