// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import {BaseBLPStaking, BLPStaking} from "../BaseBLPStaking.t.sol";

contract BLPStakeTest is BaseBLPStaking {
    function test_RevertStake_BalanceMustBeGtMin() public {
        uint256 amount = 1e8;

        blp.mint(user, amount);
        vm.prank(user);
        blp.approve(address(stakingBLP), amount);

        vm.startPrank(admin);
        stakingBLP.setMinBalance(1e10);
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert("BlastUP: you must send more to stake");
        stakingBLP.stake(amount);
    }

    function test_stake() public {
        uint256 amount = 1e18;

        blp.mint(user, amount);

        vm.startPrank(user);
        blp.approve(address(stakingBLP), amount);
        vm.expectEmit(address(stakingBLP));
        emit BLPStaking.Staked(user, amount);
        stakingBLP.stake(amount);
        assertEq(stakingBLP.totalLocked(), amount);

        vm.warp(1e5);
        assertGt(stakingBLP.getRewardOf(user), 0);
    }

    function test_stakeFuzz(uint256 amount) public {
        vm.warp(1001);
        amount = bound(amount, 1e6, 1e40);

        blp.mint(user, amount);

        vm.startPrank(user);
        blp.approve(address(stakingBLP), amount);
        vm.expectEmit(address(stakingBLP));
        emit BLPStaking.Staked(user, amount);
        stakingBLP.stake(amount);
        vm.stopPrank();
        assertEq(stakingBLP.totalLocked(), amount);
        vm.prank(admin);
        vm.expectRevert("BlastUP: insolvency");
        stakingBLP.withdrawFunds(amount);

        uint256 reward = stakingBLP.getRewardOf(user);
        assertEq(reward, 0);

        vm.warp(lockTime * 1e6);
        assertGt(stakingBLP.getRewardOf(user), 0);
    }
}
