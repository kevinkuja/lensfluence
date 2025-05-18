// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../src/contracts/ArtistToken.sol';
import '../../src/contracts/ArtistTokenFactory.sol';

import '../../src/contracts/MockYieldPlatform.sol';
import '../../src/contracts/PriceEngine.sol';
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';
import {Test} from 'forge-std/Test.sol';
import {console} from 'forge-std/console.sol';

contract RealTest is Test {
  using Math for uint256;

  uint256 maxSupply = 1_000_000;

  function setUp() public {
    // vm.rollFork(1797176);
  }

  function testMint() public {
    uint256 mainnetFork = vm.createFork(vm.rpcUrl('lens'));
    vm.selectFork(mainnetFork);
    address token = 0x74625EB1A1766B40cd8006C569aAdb0D2D5bD065;
    ArtistToken artistToken = ArtistToken(payable(token));
    address user = 0x7B744748Dd77eE149346D5FcA226A6276EfDDAeA;
    deal(user, 1_000_000_000_000_000_000_000);
    uint256 totalSupply = artistToken.totalSupply();
    console.log('Total supply:', totalSupply);
    vm.prank(user);
    artistToken.mint{value: 1000}(user, 1);
  }
}
