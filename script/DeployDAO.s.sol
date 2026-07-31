// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {ModernDaoToken} from "../src/ModernDaoToken.sol";
import {MyGovernor} from "../src/MyGovernor.sol";
import {CustomVault} from "../src/CustomVault.sol";

contract DeployDAO is Script {
    function run() external {
        // Start broadcasting transactions using private key or default anvil signer
        vm.startBroadcast();

        // 1. Define Timelock parameters (e.g., 1 hour min delay)
        uint256 minDelay = 3600;
        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](0);

        // 2. Deploy TimeLock contract
        TimeLock timeLock = new TimeLock(minDelay, proposers, executors);

        // 3. Deploy ModernDaoToken and assign initial supply / owner to deployer
        ModernDaoToken token = new ModernDaoToken(msg.sender);

        // 4. Deploy Governor contract linking Token and TimeLock
        MyGovernor governor = new MyGovernor(token, timeLock);

        // 5. Deploy CustomVault with TimeLock set as the owner
        CustomVault vault = new CustomVault(address(timeLock));

        // 6. Setup Timelock Roles for decentralization
        bytes32 proposerRole = timeLock.PROPOSER_ROLE();
        bytes32 executorRole = timeLock.EXECUTOR_ROLE();
        bytes32 adminRole = timeLock.DEFAULT_ADMIN_ROLE();

        // Grant PROPOSER_ROLE to the Governor contract
        timeLock.grantRole(proposerRole, address(governor));
        
        // Grant EXECUTOR_ROLE to address(0) so anyone can execute passed/queued proposals
        timeLock.grantRole(executorRole, address(0));

        // Revoke DEFAULT_ADMIN_ROLE from the deployer so the Timelock manages itself
        timeLock.revokeRole(adminRole, msg.sender);

        vm.stopBroadcast();
    }
}