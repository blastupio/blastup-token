// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {CommonBase} from "forge-std/Base.sol";
import {StdAssertions} from "forge-std/StdAssertions.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {console} from "forge-std/console.sol";
import {AddressSet, LibAddressSet} from "../Helpers/AddressSet.sol";
import {BaseBLPStaking, BLPStaking, ERC20Mock} from "../../BaseBLPStaking.t.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract BLPStakingHandler is CommonBase, StdCheats, StdUtils, StdAssertions {
    using LibAddressSet for AddressSet;
    using Math for uint256;

    BLPStaking public staking;
    ERC20Mock blp;

    uint256 public ghost_stakedSum;
    uint256 public ghost_rewardsClaimed;
    uint256 public ghost_balanceForRewards;
    mapping(address => uint256) public ghost_userPreCalculatedRewards;
    mapping(address => uint256) public ghost_userRealClaimedRewards;
    uint256 lockTime = 1000;
    uint32 percent = 10 * 1e2;

    mapping(bytes32 => uint256) public calls;

    AddressSet internal _actors;
    address internal currentActor;

    modifier useActor(uint256 actorIndexSeed) {
        currentActor = _actors.rand(actorIndexSeed);
        _;
    }

    modifier countCall(bytes32 key) {
        calls[key]++;
        _;
    }

    function forEachActor(function(address) external view func) public {
        return _actors.forEach(func);
    }

    constructor(BLPStaking _staking, ERC20Mock _blp) {
        staking = _staking;
        blp = _blp;
    }

    function stake(uint256 actorSeed, uint256 amount)
        public
        useActor(actorSeed)
        countCall("stake")
    {
        (uint256 balance,,,) = staking.users(currentActor);
        amount = bound(amount, 1e6, 1e30);

        blp.mint(currentActor, amount);

        if (balance > 0) {
            uint256 reward = staking.getRewardOf(currentActor);
            ghost_rewardsClaimed += reward;
            ghost_userRealClaimedRewards[currentActor] += reward;
        }

        uint256 yearlyReward = (balance + amount) * percent / 1e4;
        uint256 preCalculatedReward = yearlyReward * lockTime / 365 days;
        console.log("yearlyReward", yearlyReward, "preCalculatedReward", preCalculatedReward);

        ghost_userPreCalculatedRewards[currentActor] += preCalculatedReward;
        blp.mint(address(staking), preCalculatedReward);
        ghost_balanceForRewards += preCalculatedReward;

        vm.startPrank(currentActor);
        blp.approve(address(staking), amount);
        staking.stake(amount);
        vm.stopPrank();

        ghost_stakedSum += amount;
    }

    function withdraw(uint256 actorSeed) public useActor(actorSeed) countCall("withdraw") {
        uint256 reward = staking.getRewardOf(currentActor);
        (uint256 balance,, uint256 unlockTimestamp,) = staking.users(currentActor);

        vm.assume(unlockTimestamp <= block.timestamp);
        vm.assume(balance > 0);
        console.log("preCalculatedRewards", ghost_userPreCalculatedRewards[currentActor]);

        vm.prank(currentActor);
        staking.withdraw();

        ghost_stakedSum -= balance;
        ghost_rewardsClaimed += reward;
        ghost_userRealClaimedRewards[currentActor] += reward;
    }

    function claim(uint256 actorSeed) public useActor(actorSeed) countCall("claim") {
        uint256 reward = staking.getRewardOf(currentActor);
        console.log("preCalculatedRewards", ghost_userPreCalculatedRewards[currentActor]);
        vm.prank(currentActor);
        staking.claim();
        ghost_rewardsClaimed += reward;
        ghost_userRealClaimedRewards[currentActor] += reward;
    }

    function forceWithdrawAll(uint256 actorSeed) public useActor(actorSeed) countCall("forceWithdrawAll") {
        (uint256 balance,, uint256 unlockTimestamp,) = staking.users(currentActor);
        vm.assume(balance > 0);
        if (block.timestamp < unlockTimestamp) {
            vm.warp(unlockTimestamp);
        }

        ghost_stakedSum -= balance;

        vm.prank(currentActor);
        staking.withdraw(true);
    }

    function warp(uint256 secs) public {
        secs = _bound(secs, 0, 20 days);
        vm.warp(block.timestamp + secs);
    }

    function updateLockTimePercent() public {
        percent = uint32(bound(percent, 100, 20_000));
        lockTime = bound(lockTime, 1e4, 1e10);
        vm.prank(staking.owner());
        staking.setLockTimeAndPercent(lockTime, percent);
    }
}
