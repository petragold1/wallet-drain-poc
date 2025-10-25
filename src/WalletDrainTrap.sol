// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// Minimal ITrap interface
interface ITrap {
    function collect() external view returns (bytes memory);
    function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory);
}

/**
 * WalletDrainTrap
 *
 * Fixes Instructor's points:
 *  - collect() only returns the ETH balance (lean)
 *  - shouldRespond() returns bytes("") when response_function is respond()
 *  - Adds hysteresis (trigger / clear band)
 *  - Uses recent-history (data[]) to require N consecutive below-threshold samples
 */
contract WalletDrainTrap is ITrap {
    // The wallet we are watching (replace if needed)
    address public constant WATCHED = 0xE52cA26d0db661791158549068483C379B209740;

    // Balance thresholds: implement a hysteresis band to avoid chattering
    uint256 public constant TRIGGER_WEI = 490000000000000000; // 0.49 ETH -> trigger to respond
    uint256 public constant CLEAR_WEI   = 510000000000000000; // 0.51 ETH -> clear response

    // How many consecutive samples below TRIGGER_WEI we require before responding
    // This uses the block_sample_size set in drosera.toml: prefer <= that number.
    uint256 public constant REQUIRED_CONSECUTIVE = 3;

    /// Collect only the current balance (lean)
    function collect() external view override returns (bytes memory) {
        uint256 bal = WATCHED.balance;
        return abi.encode(bal);
    }

    /**
     * shouldRespond
     *
     * data[0] is most recent sample. data may include up to block_sample_size entries.
     * Return (true, bytes("")) to match response_function = "respond()".
     */
    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        // If there are no samples, don't respond
        if (data.length == 0) {
            return (false, bytes(""));
        }

        // decode latest sample
        (uint256 latest) = abi.decode(data[0], (uint256));

        // 1) Quick clear if latest is above CLEAR_WEI -- no response needed
        if (latest > CLEAR_WEI) {
            return (false, bytes(""));
        }

        // 2) If latest is below TRIGGER_WEI, check history for REQUIRED_CONSECUTIVE
        if (latest < TRIGGER_WEI) {
            uint256 consecutive = 1; // latest counts
            // iterate next samples (if exist) up to required count
            for (uint256 i = 1; i < data.length && consecutive < REQUIRED_CONSECUTIVE; i++) {
                (uint256 v) = abi.decode(data[i], (uint256));
                if (v < TRIGGER_WEI) {
                    consecutive++;
                } else {
                    break;
                }
            }
            if (consecutive >= REQUIRED_CONSECUTIVE) {
                // Enough consecutive low readings — signal response (empty bytes)
                return (true, bytes(""));
            }
            // Not enough consecutive low readings yet
            return (false, bytes(""));
        }

        // 3) If latest in hysteresis band [TRIGGER_WEI, CLEAR_WEI], do nothing
        return (false, bytes(""));
    }
}
