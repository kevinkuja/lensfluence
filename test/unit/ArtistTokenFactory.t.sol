// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../src/contracts/ArtistToken.sol';
import '../../src/contracts/ArtistTokenFactory.sol';

import '../../src/contracts/MockYieldPlatform.sol';
import '../../src/contracts/PriceEngine.sol';
import 'forge-std/Test.sol';

/**
 * @title ArtistTokenFactoryTest
 * @dev Test suite for the ArtistTokenFactory contract.
 */
contract ArtistTokenFactoryTest is Test {
  ArtistTokenFactory factory;
  PriceEngine priceEngine;
  MockYieldPlatform yieldPlatform;

  address owner = address(0x1);
  address artist = address(0x2);

  /**
   * @dev Sets up the test environment.
   */
  function setUp() public {
    vm.deal(owner, 1000 ether);
    vm.deal(artist, 1000 ether);

    yieldPlatform = new MockYieldPlatform(owner);
    priceEngine = new PriceEngine(address(yieldPlatform), owner);
    factory = new ArtistTokenFactory(owner);

    vm.prank(owner);
    priceEngine.setFactory(address(factory));

    vm.prank(owner);
    priceEngine.deposit(100 ether);
  }

  /**
   * @dev Tests creating an ArtistToken.
   */
  function testCreateArtistToken() public {
    vm.prank(owner);
    address tokenAddr = factory.createArtistToken('Test Token', 'TST', 1_000_000, address(priceEngine), artist);

    assertEq(factory.artistToToken(artist), tokenAddr);

    ArtistToken token = ArtistToken(tokenAddr);
    assertEq(token.name(), 'Test Token');
    assertEq(token.symbol(), 'TST');
    assertEq(token.maxSupply(), 1_000_000);
    assertEq(token.artist(), artist);
  }

  /**
   * @dev Tests creating a token with invalid supply.
   */
  function testCreateArtistTokenInvalidSupply() public {
    vm.prank(owner);
    vm.expectRevert('Supply too high');
    factory.createArtistToken('Test Token', 'TST', 2_000_000, address(priceEngine), artist);
  }

  /**
   * @dev Tests creating a token for an artist that already has one.
   */
  function testCreateArtistTokenAlreadyExists() public {
    vm.prank(owner);
    factory.createArtistToken('Test Token', 'TST', 1_000_000, address(priceEngine), artist);

    vm.prank(owner);
    vm.expectRevert('Token already exists');
    factory.createArtistToken('Test Token 2', 'TST2', 1_000_000, address(priceEngine), artist);
  }

  /**
   * @dev Tests creating a token with an invalid artist address.
   */
  function testCreateArtistTokenInvalidArtist() public {
    vm.prank(owner);
    vm.expectRevert('Invalid artist address');
    factory.createArtistToken('Test Token', 'TST', 1_000_000, address(priceEngine), address(0));
  }
}
