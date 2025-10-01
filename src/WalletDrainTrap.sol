// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITrap {
  function collect() external view returns (bytes memory);
  function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory);
}

contract WalletDrainTrap is ITrap {
    address public constant WATCHED = 0xE52cA26d0db661791158549068483C379B209740; // your test address
    uint256 public constant THRESHOLD_WEI = 0.5 ether;
    string public constant ALERT_TAG = "annaastacia";

    function collect() external view override returns (bytes memory) {
        uint256 bal = WATCHED.balance;
        return abi.encode(bal, ALERT_TAG);
    }

    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        (uint256 bal, string memory tag) = abi.decode(data[0], (uint256, string));
        if (bal < THRESHOLD_WEI) {
            return (true, abi.encode(tag));
        }
        return (false, bytes(""));
    }
}

