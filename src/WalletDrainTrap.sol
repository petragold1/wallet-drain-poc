// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITrap {
    function collect() external view returns (bytes memory);
    function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory);
}

contract WalletDrainTrap is ITrap {
    // 👇 Replace this address if you want to monitor a different wallet
    address public constant WATCHED = 0xE52cA26d0db661791158549068483C379B209740;

    // 👇 Balance threshold (0.5 ETH)
    uint256 public constant THRESHOLD_WEI = 0.5 ether;

    /// Collects only the watched wallet's ETH balance (keeps data small)
    function collect() external view override returns (bytes memory) {
        uint256 bal = WATCHED.balance;
        return abi.encode(bal);
    }

    /// Checks if balance is below threshold and signals response (empty payload)
    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        if (data.length == 0) {
            return (false, bytes(""));
        }
        uint256 bal = abi.decode(data[0], (uint256));
        if (bal < THRESHOLD_WEI) {
            return (true, bytes(""));
        }
        return (false, bytes(""));
    }
}
