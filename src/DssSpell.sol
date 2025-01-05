// SPDX-FileCopyrightText: © 2020 Dai Foundation <www.daifoundation.org>
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.16;

// Enable ABIEncoderV2 when onboarding collateral through `DssExecLib.addNewCollateral()`
pragma experimental ABIEncoderV2;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

interface GemLike {
    function transfer(address, uint256) external returns (bool);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/PulseMakerWin/community/refs/heads/master/governance/votes/Executive%20Vote%20-%20December%2030%2C%202024.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2024-12-30 MakerDAO Executive Spell | Hash: 0x66d8a56968c541c7993447f710f7db006eabbc824c370ba8fc9e21128a0ea388";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return false;
    }

    uint256 internal constant FOUR_PCT_RATE = 1000000001243680656318820312;

    // --- DEPLOYED COLLATERAL ADDRESSES ---
    address internal constant WPLS = 0xA1077a294dDE1B09bB078844df40758a5D0f9a27;
    address internal constant PIP_WPLS = 0x664689268c42BE9fEBfdc4652ceC401E81FD8954;
    address internal constant MCD_JOIN_WPLS_A = 0x65771De4Be7FCA135fce1824e6d2d4AB9C20827B;
    address internal constant MCD_CLIP_WPLS_A = 0x5b9E9Cb1c538658F0D57B6Ccb318E9c6AAc4C06A;
    address internal constant MCD_CLIP_CALC_WPLS_A = 0x9Df44932AE85586b7f9B709a82571bcab4e8bd23;

    function actions() public override {
        // DSR Adjustment
        // Increase the DSR to 4%
        DssExecLib.setDSR(FOUR_PCT_RATE, true);

        // ----------------------------- Collateral onboarding -----------------------------
        //  Add WPLS-A as a new Vault Type
        //  Poll Link:   https://pulsemaker.win/polling/Qmaa3Vbd#poll-detail

        DssExecLib.addNewCollateral(
            CollateralOpts({
                ilk:                  "WPLS-A",
                gem:                  WPLS,
                join:                 MCD_JOIN_WPLS_A,
                clip:                 MCD_CLIP_WPLS_A,
                calc:                 MCD_CLIP_CALC_WPLS_A,
                pip:                  PIP_WPLS,
                isLiquidatable:       true,
                isOSM:                true,
                whitelistOSM:         true,
                ilkDebtCeiling:       1_000_000,        // line starts at 0
                minVaultAmount:       0,                // debt floor - dust in DAI
                maxLiquidationAmount: 2_000_000,
                liquidationPenalty:   15_00,            // 15% penalty on liquidation
                ilkStabilityFee:      10_00,            // 10% stability fee
                startingPriceFactor:  115_00,           // Auction price begins at 120% of oracle price
                breakerTolerance:     20_00,            // Allows for a 20% hourly price drop before disabling liquidation
                auctionDuration:      8400,
                permittedDrop:        15_00,            // 15% price drop before reset
                liquidationRatio:     150_00,           // 175% collateralization
                kprFlatReward:        0,
                kprPctReward:         0
            })
        );

        DssExecLib.setStairstepExponentialDecrease(MCD_CLIP_CALC_WPLS_A, 60 seconds, 99_00);
        DssExecLib.setIlkAutoLineParameters("WPLS-A", 5_000_000, 3_000_000, 8 hours);

        // -------------------- Changelog Update ---------------------
        DssExecLib.setChangelogAddress("WPLS",                 WPLS);
        DssExecLib.setChangelogAddress("PIP_WPLS",             PIP_WPLS);
        DssExecLib.setChangelogAddress("MCD_JOIN_WPLS_A",      MCD_JOIN_WPLS_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_WPLS_A",      MCD_CLIP_WPLS_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_WPLS_A", MCD_CLIP_CALC_WPLS_A);

        // Bump changelog
        DssExecLib.setChangelogVersion("1.15.0");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 14 days, address(new DssSpellAction())) {}
}
