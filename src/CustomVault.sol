// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract CustomVault is Ownable {
    // Errors
    error CustomVault__ValueCantBeZero();
    error CustomVault__InsufficientVaultBalance();
    error CustomVault__TransferFailed();

    // Events with parameters for better tracking
    event FundsDeposited(address indexed sender, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    // Mapping to track individual deposits
    mapping(address => uint256) public funds;

    // Constructor sets the initial owner (which will be our Timelock contract)
    constructor(address initialOwner) Ownable(initialOwner) {}

    // Function to deposit funds into the vault
    function deposit() public payable {
        if(msg.value == 0){
            revert CustomVault__ValueCantBeZero();
        }
        funds[msg.sender] += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }

    // Function to withdraw funds, strictly restricted to the owner (Timelock)
    function withdraw(address payable to, uint256 amount) public onlyOwner {
        if(address(this).balance < amount) {
            revert CustomVault__InsufficientVaultBalance();
        }
        
        // Transfer the funds securely
        (bool success, ) = to.call{value: amount}("");

        if(!success) {
            revert CustomVault__TransferFailed();
        }
        emit FundsWithdrawn(to, amount);
    }

    // Fallback/Receive to accept plain ETH transfers
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }
}