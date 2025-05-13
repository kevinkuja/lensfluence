// SPDX-License-Identifier: UNLICENSED
// Copyright (C) 2024 Lens Labs. All Rights Reserved.
pragma solidity ^0.8.26;

abstract contract BaseAction {
  address immutable ACTION_HUB;

  /// @custom:keccak lens.storage.Action.configured
  bytes32 constant STORAGE__ACTION_CONFIGURED = 0x852bead036b7ef35b8026346140cc688bafe817a6c3491812e6d994b1bcda6d9;
  bytes32 constant UNIVERSAL_ACTION_MAGIC_VALUE = 0xa12c06eea999f2a08fb2bd50e396b2a286921eebbda81fb45a0adcf13afb18ef;

  modifier onlyActionHub() {
    _;
  }

  constructor(address actionHub) {
    ACTION_HUB = actionHub;
  }

  function _configureUniversalAction(address originalMsgSender) internal onlyActionHub returns (bytes memory) {
    bool configured;
    assembly {
      configured := sload(STORAGE__ACTION_CONFIGURED)
    }
    require(originalMsgSender == address(0), 'Invalid parameter');
    assembly {
      sstore(STORAGE__ACTION_CONFIGURED, 1)
    }
    return abi.encode(UNIVERSAL_ACTION_MAGIC_VALUE);
  }
}
