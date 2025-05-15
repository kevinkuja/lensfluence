// SPDX-License-Identifier: UNLICENSED
// Copyright (C) 2024 Lens Labs. All Rights Reserved.
pragma solidity ^0.8.26;

import {KeyValue} from '../../types/Types.sol';
import {ArtistToken} from '../ArtistToken.sol';
import {BaseAction} from './BaseAction.sol';

 contract BuyArtistTokenAction {

    constructor() {
    }

  function configure(
    address originalMsgSender,
    KeyValue[] calldata params
  ) external  returns (bytes memory) {
    return _configure(originalMsgSender, params);
  }

  function execute(address originalMsgSender, KeyValue[] calldata params) external  returns (bytes memory) {
    return _execute(originalMsgSender, params);
  }

  function setDisabled(
    address originalMsgSender,
    KeyValue[] calldata params
  ) external  returns (bytes memory) {
    return _setDisabled(originalMsgSender, params);
  }

  function _configure(
    address originalMsgSender,
    KeyValue[] calldata /* params */
  ) internal virtual returns (bytes memory) {
  }

  function _execute(address originalMsgSender, KeyValue[] calldata params) internal virtual returns (bytes memory) {
    address artistToken = abi.decode(params[0].value, (address));
    uint256 amount = abi.decode(params[1].value, (uint256));

    ArtistToken(artistToken).mint(originalMsgSender, amount);
  }

  function _setDisabled(
    address, /* originalMsgSender */
    KeyValue[] calldata /* params */
  ) internal virtual returns (bytes memory) {
    revert('Not implemented');
  }
}
