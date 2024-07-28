// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.25;

import {BLPStaking} from "./BLPStaking.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {LockedBLASTUP} from "./LockedBLASTUP.sol";

contract LockedBLPStaking is Ownable, BLPStaking {
    constructor(
        address _owner,
        address _stakeToken,
        address _points,
        address _pointsOperator,
        uint256 _lockTime,
        uint32 _percent
    ) BLPStaking(_owner, _stakeToken, _points, _pointsOperator, _lockTime, _percent) {}

    function claim() public virtual override returns (uint256 reward) {
        UserState storage user = users[msg.sender];
        reward = getRewardOf(msg.sender);
        user.lastClaimTimestamp = block.timestamp;
        if (reward > 0) {
            address[] memory to = new address[](1);
            uint256[] memory amount = new uint256[](1);
            to[0] = msg.sender;
            amount[0] = reward;
            LockedBLASTUP(address(stakeToken)).mint(to, amount);
            emit Claimed(msg.sender, reward);
        }
    }
}
