// SPDX-License-Identifier: UNLICENSED
// Copyright (C) 2024 Lens Labs. All Rights Reserved.
pragma solidity ^0.8.26;

import {ACTION_HUB_ADDRESS_MAINNET} from '../../constants.sol';
import {ArtistToken} from '../ArtistToken.sol';
import {BaseAccountAction} from 'lib/lens-v3/contracts/actions/account/base/BaseAccountAction.sol';
import {KeyValue} from 'lib/lens-v3/contracts/core/types/Types.sol';

import {Errors} from 'lib/lens-v3/contracts/core/types/Errors.sol';

contract BuyArtistTokenAction is BaseAccountAction {
  constructor() BaseAccountAction(ACTION_HUB_ADDRESS_MAINNET) {}

  function _configure(
    address originalMsgSender,
    address account,
    KeyValue[] calldata params
  ) internal override returns (bytes memory) {
    return '';
  }

  function _execute(
    address originalMsgSender,
    address account,
    KeyValue[] calldata params
  ) internal override returns (bytes memory) {
    address artistToken = abi.decode(params[0].value, (address));
    uint256 amount = abi.decode(params[1].value, (uint256));

    ArtistToken(artistToken).mint(originalMsgSender, amount);
    return '';
  }

  function _setDisabled(
    address originalMsgSender,
    address account,
    bool isDisabled,
    KeyValue[] calldata params
  ) internal override returns (bytes memory) {
    revert Errors.NotImplemented();
  }
}
