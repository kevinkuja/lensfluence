// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../src/contracts/ArtistToken.sol';
import '../../src/contracts/ArtistTokenFactory.sol';

import '../../src/contracts/MockYieldPlatform.sol';
import '../../src/contracts/PriceEngine.sol';
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';
import {Test} from 'forge-std/Test.sol';
import {console} from 'forge-std/console.sol';

contract ArtistTokenTest is Test {
  using Math for uint256;

  ArtistToken token;
  PriceEngine priceEngine;
  ArtistTokenFactory factory;
  MockYieldPlatform yieldPlatform;

  address owner = address(0x1);
  address user = address(0x2);
  uint256 maxSupply = 1_000_000;

  function setUp() public {
    vm.deal(owner, 1000 ether);
    vm.deal(user, 1000 ether);

    yieldPlatform = new MockYieldPlatform(owner);
    priceEngine = new PriceEngine(address(yieldPlatform), owner);
    factory = new ArtistTokenFactory(owner);

    vm.prank(owner);
    priceEngine.setFactory(address(factory));

    vm.prank(owner);
    priceEngine.depositGHO{value: 100 ether}();

    vm.prank(owner);
    token = ArtistToken(factory.createArtistToken('Test Token', 'TST', maxSupply, address(priceEngine), owner));

    // Set initial metrics to ensure getPrice returns a valid value
    vm.prank(owner);
    priceEngine.setMetrics(owner, 100);
  }

  function testConstructor() public view {
    assertEq(token.name(), 'Test Token');
    assertEq(token.symbol(), 'TST');
    assertEq(token.maxSupply(), maxSupply);
    assertEq(token.owner(), owner);
    assertEq(address(token.priceEngine()), address(priceEngine));
    assertEq(token.artist(), owner);
  }

  function testMint() public {
    uint256 amount = 100;
    uint256 pricePerToken = priceEngine.getPrice(owner);
    uint256 cost = amount.mulDiv(pricePerToken, 1e18);

    vm.deal(user, cost);
    vm.prank(user);
    token.mint{value: cost}(user, amount);

    assertEq(token.balanceOf(user), amount);
    assertEq(token.totalSupply(), amount);
    assertEq(address(token).balance, 0); // GHO sent to priceEngine
    assertEq(priceEngine.getTreasury(), 100 ether + cost); // Deposited GHO
  }

  function testMintInsufficientGHO() public {
    uint256 amount = 100;
    uint256 pricePerToken = priceEngine.getPrice(owner);
    uint256 cost = amount.mulDiv(pricePerToken, 1e18);

    vm.prank(user);
    vm.expectRevert('Insufficient GHO');
    token.mint{value: cost / 2}(user, amount);
  }

  function testMintExceedsMaxSupply() public {
    uint256 amount = maxSupply + 1;
    uint256 pricePerToken = priceEngine.getPrice(owner);
    uint256 cost = amount.mulDiv(pricePerToken, 1e18);

    vm.deal(user, cost);
    vm.prank(user);
    vm.expectRevert('Exceeds max supply');
    token.mint{value: cost}(user, amount);
  }

  function testBurn() public {
    uint256 amount = 100;
    uint256 pricePerToken = priceEngine.getPrice(owner);
    uint256 cost = amount.mulDiv(pricePerToken, 1e18);

    vm.deal(user, cost);
    vm.prank(user);
    token.mint{value: cost}(user, amount);

    uint256 userBalanceBefore = user.balance;
    vm.prank(user);
    token.burn(user, amount);

    assertEq(token.balanceOf(user), 0);
    assertEq(token.totalSupply(), 0);
    assertApproxEqAbs(user.balance, userBalanceBefore + cost, 1 wei);
    assertEq(priceEngine.getTreasury(), 100 ether); // GHO withdrawn
    assertEq(address(token).balance, 0); // No GHO left in token contract
  }

  function testBurnInsufficientBalance() public {
    uint256 amount = 100;
    vm.prank(user);
    vm.expectRevert('Insufficient balance');
    token.burn(user, amount);
  }

  function testBurnInsufficientGHOInContract() public {
    uint256 amount = 100;
    uint256 pricePerToken = priceEngine.getPrice(owner);
    uint256 cost = amount.mulDiv(pricePerToken, 1e18);

    vm.deal(user, cost);
    vm.prank(user);
    token.mint{value: cost}(user, amount);

    // Withdraw all GHO from PriceEngine to cause burn failure
    vm.prank(owner);
    priceEngine.withdrawGHO(100 ether + cost);

    vm.prank(user);
    vm.expectRevert('Insufficient GHO in contract');
    token.burn(user, amount);
  }

  function testSetMaxSupply() public {
    uint256 newMaxSupply = 2_000_000;
    vm.prank(owner);
    token.setMaxSupply(newMaxSupply);

    assertEq(token.maxSupply(), newMaxSupply);
  }

  function testSetMaxSupplyBelowTotalSupply() public {
    uint256 amount = 100;
    uint256 pricePerToken = priceEngine.getPrice(owner);
    uint256 cost = amount.mulDiv(pricePerToken, 1e18);

    vm.deal(user, cost);
    vm.prank(user);
    token.mint{value: cost}(user, amount);

    vm.prank(owner);
    vm.expectRevert('Cannot reduce below current supply');
    token.setMaxSupply(amount - 1);
  }

  function testSetMaxSupplyTooHigh() public {
    vm.prank(owner);
    vm.expectRevert('New supply too high');
    token.setMaxSupply(10_000_001);
  }
}
