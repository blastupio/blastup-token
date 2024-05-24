// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.25;

import {BLPStaking} from "./BLPStaking.sol";
import {IBLPBalanceOracle} from "./interfaces/IBLPBalanceOracle.sol";

contract BLPBalanceOracle is IBLPBalanceOracle {
    address public blpStaking;
    address public lockedBLPStaking;

    constructor(address _blpStaking, address _lockedBLPStaking) {
        blpStaking = _blpStaking;
        lockedBLPStaking = _lockedBLPStaking;
    }

    function balanceOf(address user) external view returns (uint256) {
        (uint256 amountOfTokens,,,) = BLPStaking(blpStaking).users(user);
        (uint256 amountOfLockedTokens,,,) = BLPStaking(lockedBLPStaking).users(user);
        return amountOfTokens + amountOfLockedTokens;
    }
}
