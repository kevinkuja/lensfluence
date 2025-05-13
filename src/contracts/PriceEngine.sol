// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IArtistToken} from '../interfaces/IArtistToken.sol';
import {IArtistTokenFactory} from '../interfaces/IArtistTokenFactory.sol';

import {IMockYieldPlatform} from '../interfaces/IMockYieldPlatform.sol';
import {IPriceEngine} from '../interfaces/IPriceEngine.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

import {console} from 'forge-std/console.sol';

/**
 * @title PriceEngine
 * @dev Manages token prices based on artist metrics, with GHO investments in a yield platform.
 */
contract PriceEngine is Ownable, IPriceEngine {
  using Math for uint256;

  IArtistTokenFactory public factory; // ArtistTokenFactory contract
  IMockYieldPlatform public yieldPlatform; // Yield platform for GHO investments
  uint256 public treasuryGHO; // Total GHO in the treasury (wei)
  uint256 public releasedLiquidity; // Total released liquidity (wei)

  mapping(address => uint256) public prevRawValues; // Previous raw value for each artist
  mapping(address => uint256) public prevMetrics; // Previous metric value for each artist
  mapping(address => uint256) public artistPrices; // Stored price per token for each artist (wei)

  uint256 public constant MAX_SI = 10e18; // Maximum Success Index (10x)

  /**
   * @dev Constructor to initialize the contract.
   * @param _yieldPlatform Address of the MockYieldPlatform contract.
   * @param initialOwner The initial owner of the contract.
   */
  constructor(address _yieldPlatform, address initialOwner) Ownable(initialOwner) {
    yieldPlatform = IMockYieldPlatform(_yieldPlatform);
    treasuryGHO = 0;
    releasedLiquidity = 0;
  }

  /**
   * @dev Sets the ArtistTokenFactory contract address.
   * @param _factory The factory contract address.
   */
  function setFactory(address _factory) external onlyOwner {
    require(_factory != address(0), 'Invalid factory address');
    factory = IArtistTokenFactory(_factory);
  }

  /**
   * @dev Deposits GHO into the yield platform and updates the treasury.
   */
  function depositGHO() external payable override {
    yieldPlatform.depositGHO{value: msg.value}();
    treasuryGHO += msg.value;
  }

  /**
   * @dev Withdraws GHO from the yield platform and updates the treasury.
   * @param amount The amount to withdraw (wei).
   */
  function withdrawGHO(uint256 amount) external override onlyOwner {
    yieldPlatform.withdrawGHO(amount);
    treasuryGHO -= amount;
  }

  /**
   * @dev Returns the total released liquidity.
   * @return The released liquidity (wei).
   */
  function getReleasedLiquidity() external view override returns (uint256) {
    return releasedLiquidity;
  }

  /**
   * @dev Returns the total GHO in the treasury.
   * @return The treasury GHO balance (wei).
   */
  function getTreasury() external view returns (uint256) {
    return treasuryGHO;
  }

  /**
   * @dev Retrieves the pre-calculated price for an artist's token.
   * @param artist The artist's wallet address.
   * @return The price per token (wei).
   */
  function getPrice(address artist) external view override returns (uint256) {
    return artistPrices[artist];
  }

  /**
   * @dev Updates prices and metrics for all artists, only callable by the owner.
   * @param artists Array of artist wallet addresses.
   * @param newMetrics Array of new metric values.
   */
  function updateAllArtists(address[] calldata artists, uint256[] calldata newMetrics) external onlyOwner {
    require(artists.length == newMetrics.length, 'Arrays length mismatch');
    require(artists.length > 0, 'Empty arrays');

    uint256 totalRequiredGHO = 0;
    uint256[] memory successIndexes = new uint256[](artists.length);
    uint256[] memory newPrices = new uint256[](artists.length);

    // Step 1: Calculate liquidity released by artists with decreasing metrics
    for (uint256 i = 0; i < artists.length; i++) {
      address artist = artists[i];
      uint256 newMetric = newMetrics[i];
      require(newMetric <= 1_000_000_000, 'Metric too high');
      require(factory.artistToToken(artist) != address(0), 'Token does not exist');

      address token = factory.artistToToken(artist);
      uint256 supply = IERC20(token).totalSupply();
      uint256 prevMetric = prevMetrics[artist] == 0 ? 1 : prevMetrics[artist];
      uint256 prevPrice = artistPrices[artist] == 0 ? 1e18 : artistPrices[artist];

      // Calculate Success Index (percentage change in metric)
      successIndexes[i] = newMetric.mulDiv(1e18, prevMetric);
      successIndexes[i] = successIndexes[i] > MAX_SI ? MAX_SI : successIndexes[i];

      // Handle decreasing metrics (release liquidity)
      if (successIndexes[i] < 1e18 && newMetric < prevMetric) {
        // Percentage drop in metric
        uint256 metricDropPercent = ((prevMetric - newMetric) * 1e18) / prevMetric;
        // Liquidity released is proportional to the metric drop
        uint256 tokenValue = prevPrice.mulDiv(supply, 1e18);
        uint256 liquidityReleased = tokenValue.mulDiv(metricDropPercent, 1e18);
        releasedLiquidity += liquidityReleased;
        newPrices[i] = prevPrice.mulDiv(successIndexes[i], 1e18); // Unscaled price drop
      }
    }

    // Step 2: Calculate total required GHO for increasing metrics
    for (uint256 i = 0; i < artists.length; i++) {
      address artist = artists[i];
      uint256 newMetric = newMetrics[i];
      uint256 prevMetric = prevMetrics[artist] == 0 ? 1 : prevMetrics[artist];
      uint256 prevPrice = artistPrices[artist] == 0 ? 1e18 : artistPrices[artist];

      if (successIndexes[i] > 1e18 && newMetric > prevMetric) {
        address token = factory.artistToToken(artist);
        uint256 supply = IERC20(token).totalSupply();
        newPrices[i] = prevPrice.mulDiv(successIndexes[i], 1e18); // Tentative price
        totalRequiredGHO += (newPrices[i] - prevPrice).mulDiv(supply, 1e18);
      } else if (successIndexes[i] >= 1e18) {
        // For no change or increasing metrics without prior price set
        newPrices[i] = successIndexes[i] < 1e18 ? newPrices[i] : prevPrice;
      }
    }

    // Step 3: Calculate scaling factor based on available liquidity
    uint256 availableLiquidity = releasedLiquidity;
    uint256 scalingFactor = 1e18;

    if (totalRequiredGHO > availableLiquidity) {
      scalingFactor = availableLiquidity > 0 ? availableLiquidity.mulDiv(1e18, totalRequiredGHO) : 0;
      treasuryGHO -= availableLiquidity; // Deduct available liquidity
    } else {
      treasuryGHO -= totalRequiredGHO; // Deduct only required liquidity
    }

    // Step 4: Apply price updates for increasing metrics
    for (uint256 i = 0; i < artists.length; i++) {
      address artist = artists[i];
      uint256 newMetric = newMetrics[i];
      uint256 prevMetric = prevMetrics[artist] == 0 ? 1 : prevMetrics[artist];
      uint256 prevPrice = artistPrices[artist] == 0 ? 1e18 : artistPrices[artist];

      // Apply scaling for increasing metrics
      if (successIndexes[i] > 1e18 && newMetric > prevMetric) {
        if (scalingFactor == 0) {
          newPrices[i] = prevPrice; // No liquidity, no price increase
        } else {
          newPrices[i] = prevPrice.mulDiv(successIndexes[i].mulDiv(scalingFactor, 1e18), 1e18);
        }
      }

      // Update storage
      console.log('artist', artist);
      prevMetrics[artist] = newMetric;
      console.log('artistPrices[artist]', artistPrices[artist]);
      artistPrices[artist] = newPrices[i];
      console.log('newPrices[i]', newPrices[i]);
      releasedLiquidity = availableLiquidity;
      console.log('releasedLiquidity', releasedLiquidity);
    }
  }
  /**
   * @dev Sets initial metrics for an artist.
   * @param artist The artist's wallet address.
   * @param metric The initial metric value.
   */

  function setMetrics(address artist, uint256 metric) external onlyOwner {
    require(metric <= 1_000_000_000, 'Metric too high');
    prevRawValues[artist] = 1e18;
    prevMetrics[artist] = metric;
    artistPrices[artist] = 1e18; // Initial price
  }
}
