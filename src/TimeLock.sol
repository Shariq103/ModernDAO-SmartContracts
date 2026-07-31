// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.6.0
pragma solidity ^0.8.27;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

/**
 * @title TimeLock
 * @author Mohd Shariq
 * @notice Production-grade Timelock Controller managing the execution delay for DAO proposals.
 */
contract TimeLock is TimelockController {
    /**
     * @notice Initializes the Timelock controller with a minimum delay, initial proposers, and initial executors, minDelay is how long you have to wait before executing.
     * @param minDelay The minimum time (in seconds) that must pass before a queued operation can be executed.
     * @param proposers Array of addresses granted the PROPOSER_ROLE.
     * @param executors Array of addresses granted the EXECUTOR_ROLE.
     */
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) TimelockController(minDelay, proposers, executors, msg.sender) {}
}