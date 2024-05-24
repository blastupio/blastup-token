// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.25;

import {LockedBLP} from "./LockedBLP.sol";
import {BLPStaking} from "./BLPStaking.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract LockedBLPStaking is Ownable, BLPStaking {
    constructor(address _owner, address _stakeToken, address _rewardToken, address _points, address _pointsOperator)
        BLPStaking(_owner, _stakeToken, _rewardToken, _points, _pointsOperator)
    {}

    function getRewardOf(address addr) public view override returns (uint256) {
        if (block.timestamp < LockedBLP(address(stakeToken)).tgeTimestamp()) return 0;
        return super.getRewardOf(addr);
    }
}
