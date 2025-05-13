// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../src/contracts/ArtistToken.sol';
import '../../src/contracts/ArtistTokenFactory.sol';
import '../../src/contracts/MockYieldPlatform.sol';
import '../../src/contracts/PriceEngine.sol';
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';
import {Test} from 'forge-std/Test.sol';
import {console} from 'forge-std/console.sol';

/**
 * @title PriceEngineTest
 * @dev Test suite for the PriceEngine contract.
 */
contract PriceEngineTest is Test {
  using Math for uint256;

  PriceEngine priceEngine;
  ArtistTokenFactory factory;
  MockYieldPlatform yieldPlatform;

  address owner = address(0x1);
  address user = address(0x2);
  address artist1 = address(0x3);
  address artist2 = address(0x4);

  /**
   * @dev Sets up the test environment.
   */
  function setUp() public {
    vm.deal(owner, 1000 ether);
    vm.deal(user, 1000 ether);
    vm.deal(artist1, 1000 ether);
    vm.deal(artist2, 1000 ether);

    yieldPlatform = new MockYieldPlatform(owner);
    priceEngine = new PriceEngine(address(yieldPlatform), owner);
    factory = new ArtistTokenFactory(owner);

    vm.prank(owner);
    priceEngine.setFactory(address(factory));

    vm.prank(owner);
    priceEngine.depositGHO{value: 100 ether}();

    vm.startPrank(owner);
    factory.createArtistToken('Test Token 1', 'TST1', 1_000_000, address(priceEngine), artist1);
    factory.createArtistToken('Test Token 2', 'TST2', 1_000_000, address(priceEngine), artist2);
    vm.stopPrank();

    vm.prank(owner);
    yieldPlatform.simulateYield(address(priceEngine), 10 ether);

    // Set initial metrics
    address[] memory artists = new address[](2);
    artists[0] = artist1;
    artists[1] = artist2;
    uint256[] memory metrics = new uint256[](2);
    metrics[0] = 100;
    metrics[1] = 100;

    vm.prank(owner);
    priceEngine.updateAllArtists(artists, metrics);
  }

  /**
   * @dev Tests retrieving the yield from the platform.
   */
  function testGetYield() public {
    uint256 yield = yieldPlatform.getYield(address(priceEngine));
    assertEq(yield, 10 ether);
  }

  /**
   * @dev Tests mint price when metrics decrease for one artist.
   */
  function testgetPriceMetricsDown() public {
    address token = factory.artistToToken(artist1);

    vm.prank(owner);
    priceEngine.setMetrics(artist1, 100);
    uint256 amount = 100;
    uint256 initialPrice = priceEngine.getPrice(artist1);
    uint256 cost = amount.mulDiv(initialPrice, 1e18);

    vm.prank(user);
    ArtistToken(token).mint{value: cost}(user, amount);

    address[] memory artists = new address[](1);
    artists[0] = artist1;
    uint256[] memory metrics = new uint256[](1);
    metrics[0] = 80;

    vm.prank(owner);
    priceEngine.updateAllArtists(artists, metrics);

    uint256 newPrice = priceEngine.getPrice(artist1);

    assertApproxEqRel(newPrice, initialPrice * 80 / 100, 1e16);

    uint256 expectedLiquidity = ((initialPrice - newPrice) * amount) / 1e18;
    assertEq(priceEngine.getReleasedLiquidity(), expectedLiquidity);
  }

  /**
   * @dev Tests mint price when metrics increase, limited by yield.
   */
  function testgetPriceMetricsUpYieldOnly() public {
    vm.startPrank(owner);
    address token1 = factory.artistToToken(artist1);
    priceEngine.setMetrics(artist1, 100);
    address token2 = factory.artistToToken(artist2);
    priceEngine.setMetrics(artist2, 100);
    vm.stopPrank();
    uint256 amount = 1000;
    uint256 initialPrice = priceEngine.getPrice(artist1);
    uint256 cost = (amount * initialPrice) / 1e18;

    console.log('cost', cost);
    console.log('treasury', priceEngine.getTreasury());
    deal(address(this), cost * 10);
    ArtistToken(token1).mint{value: cost}(user, amount);
    ArtistToken(token2).mint{value: cost}(user, amount);
    console.log('treasury after mint', priceEngine.getTreasury());
    console.log('releasedLiquidity after mint', priceEngine.getReleasedLiquidity());

    address[] memory artists = new address[](2);
    artists[0] = artist1;
    artists[1] = artist2;
    uint256[] memory metrics = new uint256[](2);
    metrics[0] = 120;
    metrics[1] = 120;

    vm.prank(owner);
    priceEngine.updateAllArtists(artists, metrics);
    console.log('releasedLiquidity', priceEngine.getReleasedLiquidity());

    uint256 newPrice = priceEngine.getPrice(artist1);

    console.log('initialPrice', initialPrice);
    console.log('newPrice', newPrice);
    console.log('amount', amount);

    uint256 yieldAmount = yieldPlatform.getYield(address(priceEngine));
    uint256 requiredGHO = (initialPrice.mulDiv(120, 100).mulDiv(amount, 1e18)).mulDiv(2, 1e18);
    uint256 scalingFactor = yieldAmount.mulDiv(1e18, requiredGHO);
    uint256 expectedPrice = initialPrice.mulDiv(120, 100).mulDiv(scalingFactor, 1e18);
    assertApproxEqRel(newPrice, expectedPrice, 1e16);
  }

  /**
   * @dev Tests mint price when metrics increase with released liquidity.
   */
  function testgetPriceMetricsUpWithLiquidity() public {
    address token1 = factory.artistToToken(artist1);
    address token2 = factory.artistToToken(artist2);
    uint256 amount = 1000;
    uint256 pricePerToken = priceEngine.getPrice(artist1);
    uint256 cost = amount.mulDiv(pricePerToken, 1e18);
    vm.prank(user);
    ArtistToken(token1).mint{value: cost}(user, amount);
    ArtistToken(token2).mint{value: cost}(user, amount);

    uint256 initialPrice1 = priceEngine.getPrice(artist1);
    uint256 initialPrice2 = priceEngine.getPrice(artist2);

    address[] memory artists = new address[](2);
    artists[0] = artist1;
    artists[1] = artist2;
    uint256[] memory metrics = new uint256[](2);
    metrics[0] = 80;
    metrics[1] = 80;

    vm.prank(owner);
    priceEngine.updateAllArtists(artists, metrics);

    uint256 newPrice1 = priceEngine.getPrice(artist1);
    //uint256 expectedLiquidity = (initialPrice1 - newPrice1).mulDiv(amount, 1e18);
    assertEq(priceEngine.getReleasedLiquidity(), 0);

    uint256 newPrice2 = priceEngine.getPrice(artist2);
    assertApproxEqRel(newPrice2, initialPrice2 * 120 / 100, 1e16);
  }

  /**
   * @dev Tests updating all artists with invalid input.
   */
  function testUpdateAllArtistsInvalidInput() public {
    address[] memory artists = new address[](2);
    artists[0] = artist1;
    artists[1] = artist2;
    uint256[] memory metrics = new uint256[](1);
    metrics[0] = 120;

    vm.prank(owner);
    vm.expectRevert('Arrays length mismatch');
    priceEngine.updateAllArtists(artists, metrics);

    artists = new address[](0);
    metrics = new uint256[](0);

    vm.prank(owner);
    vm.expectRevert('Empty arrays');
    priceEngine.updateAllArtists(artists, metrics);
  }

  /**
   * @dev Tests updating all artists with non-owner account.
   */
  function testUpdateAllArtistsNonOwner() public {
    address[] memory artists = new address[](2);
    artists[0] = artist1;
    artists[1] = artist2;
    uint256[] memory metrics = new uint256[](2);
    metrics[0] = 120;
    metrics[1] = 120;

    vm.prank(user);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user, owner));
    priceEngine.updateAllArtists(artists, metrics);
  }
}
