// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {ModernDaoToken} from "../src/ModernDaoToken.sol";
import {MyGovernor} from "../src/MyGovernor.sol";
import {CustomVault} from "../src/CustomVault.sol";

contract MyGovernorTest is Test {
    TimeLock timeLock;
    ModernDaoToken token;
    MyGovernor governor;
    CustomVault vault;

    uint256 public constant MIN_DELAY = 3600; // 1 hour timelock delay
    uint256 public constant VOTING_DELAY = 7200; // Match MyGovernor settings (7200 blocks)
    uint256 public constant VOTING_PERIOD = 50400; // ~1 week in blocks

    address[] proposers;
    address[] executors;

    address public constant VOTER = address(0x1);
    uint256 public constant INITIAL_SUPPLY = 1000e18;

    function setUp() public {
        // 1. Deploy Timelock
        timeLock = new TimeLock(MIN_DELAY, proposers, executors);

        // 2. Deploy Token with initial supply to this test contract and mint to voter
        token = new ModernDaoToken(address(this));
        token.mint(VOTER, INITIAL_SUPPLY);

        // 3. Deploy Governor and Vault
        governor = new MyGovernor(token, timeLock);
        vault = new CustomVault(address(timeLock));

        // 4. Setup Timelock Roles
        bytes32 proposerRole = timeLock.PROPOSER_ROLE();
        bytes32 executorRole = timeLock.EXECUTOR_ROLE();
        bytes32 adminRole = timeLock.DEFAULT_ADMIN_ROLE();

        timeLock.grantRole(proposerRole, address(governor));
        timeLock.grantRole(executorRole, address(0)); // Anyone can execute once delay passes
        timeLock.revokeRole(adminRole, address(this)); // Remove admin rights from deployer for decentralization

        // 5. Voter delegates voting power to themselves
        vm.prank(VOTER);
        token.delegate(VOTER);
    }

    function testGovernanceUpdatesVault() public {
        // Fund the vault with some ETH to test withdrawal
        vm.deal(address(vault), 10 ether);
        assertEq(address(vault).balance, 10 ether);

        uint256 withdrawAmount = 1 ether;
        string memory description = "Proposal #1: Withdraw 1 ETH from Vault";
        
        // Encode the function call for vault.withdraw(VOTER, withdrawAmount)
        bytes memory encodedFunctionCall = abi.encodeWithSelector(
            vault.withdraw.selector, 
            payable(VOTER), 
            withdrawAmount
        );

        address[] memory targets = new address[](1);
        targets[0] = address(vault);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = encodedFunctionCall;

        // --- Step 1: Propose ---
        uint256 proposalId = governor.propose(targets, values, calldatas, description);
        
        // Advance time/blocks past the 7200 voting delay to make the proposal Active
        vm.warp(block.timestamp + (VOTING_DELAY * 12) + 1); // ~12 seconds per block approx or direct block roll
        vm.roll(block.number + VOTING_DELAY + 1);
        assertEq(uint256(governor.state(proposalId)), 1); // Active

        // --- Step 2: Cast Vote ---
        uint8 voteWay = 1; // 1 = For
        string memory reason = "Building the future of DAO!";
        
        vm.prank(VOTER);
        governor.castVoteWithReason(proposalId, voteWay, reason);

        // Advance time/blocks past the voting period
        vm.warp(block.timestamp + (VOTING_PERIOD * 12) + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);
        assertEq(uint256(governor.state(proposalId)), 4); // Succeeded

        // --- Step 3: Queue Proposal ---
        bytes32 descriptionHash = keccak256(bytes(description));
        governor.queue(targets, values, calldatas, descriptionHash);
        assertEq(uint256(governor.state(proposalId)), 5); // Queued

        // Advance time past min delay (3600 seconds) for Timelock execution
        vm.warp(block.timestamp + MIN_DELAY + 1);
        vm.roll(block.number + 1);

        // --- Step 4: Execute Proposal ---
        governor.execute(targets, values, calldatas, descriptionHash);
        assertEq(uint256(governor.state(proposalId)), 7); // Executed

        // Verify Vault balance reduced and Voter received the funds safely
        assertEq(address(vault).balance, 9 ether);
        assertEq(VOTER.balance, withdrawAmount);
    }

    // 1. Test Vault Deposits and Receive fallback
    function testVaultDirectDepositAndReceive() public {
        // Test direct deposit function
        vm.deal(VOTER, 5 ether);
        vm.prank(VOTER);
        vault.deposit{value: 2 ether}();
        assertEq(vault.funds(VOTER), 2 ether);

        // Test receive fallback
        vm.prank(VOTER);
        (bool success, ) = address(vault).call{value: 3 ether}("");
        assertTrue(success);
        assertEq(address(vault).balance, 5 ether);
    }

    // 2. Test Token Burn functionality
    function testTokenBurn() public {
        vm.prank(VOTER);
        token.burn(100e18);
        assertEq(token.balanceOf(VOTER), INITIAL_SUPPLY - 100e18);
    }

    // 3. Test Unauthorized Vault Withdrawal (Should revert because owner is Timelock)
    function testUnauthorizedVaultWithdrawFails() public {
        vm.deal(address(vault), 5 ether);
        
        vm.prank(VOTER);
        vm.expectRevert(); // Since VOTER is not the owner (Timelock is), it must revert
        vault.withdraw(payable(VOTER), 1 ether);
    }

    // 4. Test Token Nonces function coverage
    function testTokenNonces() public view {
        uint256 currentNonce = token.nonces(VOTER);
        assertEq(currentNonce, 0);
    }

    // 5. Test Governor proposal threshold & nonces / extra view functions
    function testGovernorViewFunctions() public view {
        uint256 threshold = governor.proposalThreshold();
        assertEq(threshold, 0); // As configured in GovernorSettings (0 tokens required to propose)
    }

    // 6. Test Governor proposal needs queuing check
    function testGovernorProposalNeedsQueuing() public view {
        // Governor Timelock control extension uses this to check if proposal needs queueing
        bool needsQueue = governor.proposalNeedsQueuing(12345);
        assertTrue(needsQueue); // Standard OZ Timelock control returns true for standard operations
    }
// 7. Test Governor Proposal Creation and State Handling
    function testGovernorProposalFlow() public {
        uint256 withdrawAmount = 1 ether;
        string memory description = "Proposal for flow test";
        
        bytes memory encodedFunctionCall = abi.encodeWithSelector(
            vault.withdraw.selector, 
            payable(VOTER), 
            withdrawAmount
        );

        address[] memory targets = new address[](1);
        targets[0] = address(vault);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = encodedFunctionCall;

        // Proposer creates proposal
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        // Verify proposal details via Governor getters to maximize coverage safely
        uint256 snapshot = governor.proposalSnapshot(proposalId);
        uint256 deadline = governor.proposalDeadline(proposalId);
        
        assertTrue(snapshot > 0);
        assertTrue(deadline > snapshot);
    }
}