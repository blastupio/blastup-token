// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.25;

import {BLPStaking} from "./BLPStaking.sol";
import {IBLPBalanceOracle} from "./interfaces/IBLPBalanceOracle.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract BLPBalanceOracle is IBLPBalanceOracle, Ownable {
    address public blpStaking;
    address public lockedBLPStaking;

    constructor(address _owner, address _blpStaking, address _lockedBLPStaking) Ownable(_owner) {
        blpStaking = _blpStaking;
        lockedBLPStaking = _lockedBLPStaking;
    }

    function balanceOf(address user) external view returns (uint256) {
        (uint256 amountOfTokens,,,) = BLPStaking(blpStaking).users(user);
        (uint256 amountOfLockedTokens,,,) =
            lockedBLPStaking == address(0) ? (0, 0, 0, 0) : BLPStaking(lockedBLPStaking).users(user);
        return amountOfTokens + amountOfLockedTokens;
    }

    function setBLPStaking(address _blpStaking) external onlyOwner {
        blpStaking = _blpStaking;
    }

    function setLockedBLPStaking(address _lockedBLPStaking) external onlyOwner {
        lockedBLPStaking = _lockedBLPStaking;
    }
}
