// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IMockYieldPlatform} from '../interfaces/IMockYieldPlatform.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title MockYieldPlatform
 * @dev Mock contract simulating a yield-generating platform for GHO.
 */
contract MockYieldPlatform is Ownable, IMockYieldPlatform {
  mapping(address => uint256) public balances; // Deposited balances
  mapping(address => uint256) public depositedGHO; // Initial deposits

  /**
   * @dev Constructor to initialize the contract.
   * @param initialOwner The initial owner of the contract.
   */
  constructor(address initialOwner) Ownable(initialOwner) {}

  /**
   * @dev Deposits GHO into the platform.
   */
  function depositGHO() external payable override {
    depositedGHO[msg.sender] = depositedGHO[msg.sender] + msg.value;
    balances[msg.sender] = balances[msg.sender] + msg.value;
  }

  /**
   * @dev Withdraws GHO from the platform.
   * @param amount The amount to withdraw (wei).
   */
  function withdrawGHO(uint256 amount) external override {
    require(balances[msg.sender] >= amount, 'Insufficient balance');
    balances[msg.sender] = balances[msg.sender] - amount;
    payable(msg.sender).transfer(amount);
  }

  /**
   * @dev Returns the deposited balance for an account.
   * @param account The account's address.
   * @return The balance (wei).
   */
  function getBalance(address account) external view override returns (uint256) {
    return balances[account];
  }

  /**
   * @dev Returns the yield for an account (balance minus initial deposit).
   * @param account The account's address.
   * @return The yield (wei).
   */
  function getYield(address account) external view override returns (uint256) {
    return balances[account] > depositedGHO[account] ? balances[account] - depositedGHO[account] : 0;
  }

  /**
   * @dev Simulates yield by increasing an account's balance (for testing).
   * @param account The account's address.
   * @param amount The yield amount to add (wei).
   */
  function simulateYield(address account, uint256 amount) external onlyOwner {
    balances[account] = balances[account] + amount;
  }
}
