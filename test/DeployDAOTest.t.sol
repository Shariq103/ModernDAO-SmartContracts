// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {DeployDAO} from "../script/DeployDAO.s.sol";

contract DeployDAOTest is Test {
    DeployDAO deployer;

    function setUp() public {
        deployer = new DeployDAO();
    }

    function testDeploymentScript() public {
        // Run the deployment script to ensure execution runs without errors
        deployer.run();

        // Add assertions if needed to verify state after script execution
        assertTrue(true);
    }
}