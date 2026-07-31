# 🏛️ ModernDAO Project

A production grade, fully decentralized autonomous organization (DAO) built using **Solidity**, **OpenZeppelin Contracts**, and **Foundry**. This project implements a robust governance framework complete with vote weight tracking, timelock security controls, and a decentralized treasury vault.

---

## Author

- **Mohd Shariq** _(Smart Contract Engineer & Blockchain Developer)_

---

## 🏗️ Architecture & Core Contracts

1. **`ModernDaoToken.so` (`MDT`)**: An ERC-20 governance token featuring `ERC20Votes`, `ERC20Permit`, and `ERC20Burnable` extensions to support on-chain voting power snapshots and delegation.
2. **`TimeLock.sol`**: Manages execution delays and role-based permissions (inheriting from OpenZeppelin's `TimelockController`) to ensure all approved proposals pass through a mandatory time delay before execution.
3. **`MyGovernor.sol`**: The core governance engine powered by OpenZeppelin Governor extensions (`GovernorSettings`, `GovernorCountingSimple`, `GovernorVotes`, `GovernorVotesQuorumFraction`, and `GovernorTimelockControl`).
4. **`CustomVault.sol`**: A secure treasury vault holding funds where ownership is strictly transferred to the `TimeLock` contract, ensuring that funds can only be withdrawn via successful governance proposals.

---

## 📊 Testing & Code Coverage

The project maintains exceptionally high code coverage (>95%) with rigorous testing for successful lifecycles, unauthorized access reverts, zero-value checks, and proposal state flows.

To run the test suite:

```bash
forge test -vvv
```

## To generate the code coverage report:

```Bash

forge coverage
```

## 🚀 Deployment & Local Anvil Simulation

The project includes an automated Foundry deployment script (DeployDAO.s.sol) that handles contract instantiation, role assignments, and decentralization setup (revoking deployer admin rights).

Steps to Deploy Locally on Anvil:
Start a Local Anvil Node (Terminal 1):

```Bash

anvil
```

Run the Deployment Script with Via-IR Optimization (Terminal 2):

```Bash

forge script script/DeployDAO.s.sol \
  --rpc-url [http://127.0.0.1:8545](http://127.0.0.1:8545) \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --broadcast \
  --via-ir
```

## 🛠️ Tech Stack

Smart Contract Framework: Foundry (forge, anvil)

Language: Solidity (^0.8.27)

Libraries: OpenZeppelin Contracts (^5.x)

---
# ModernDAO-SmartContracts
