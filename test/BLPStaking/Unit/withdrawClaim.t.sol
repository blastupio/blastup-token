// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import {BaseBLPStaking, BLPStaking} from "../BaseBLPStaking.t.sol";

contract BLPWithdrawClaimTest is BaseBLPStaking {
    modifier stake() {
        uint256 amount = 1e18;
        uint32 percent = 10 * 1e2;

        uint256 preClaculatedReward = (amount * percent / 1e4) * lockTime / 365 days;

        blp.mint(user, amount);
        blp.mint(address(stakingBLP), preClaculatedReward);

        vm.startPrank(user);
        blp.approve(address(stakingBLP), amount);
        stakingBLP.stake(amount);
        vm.stopPrank();
        _;
    }

    modifier stakeFuzz(uint256 amount) {
        amount = bound(amount, 1e5, 1e40);

        uint256 preClaculatedReward = (amount * percent / 1e4) * lockTime / 365 days;

        blp.mint(user, amount);
        blp.mint(address(stakingBLP), preClaculatedReward);

        vm.startPrank(user);
        blp.approve(address(stakingBLP), amount);
        stakingBLP.stake(amount);
        vm.stopPrank();
        vm.warp(lockTime * 1e5);
        _;
    }

    function test_claimFuzz(uint256 amount) public stakeFuzz(amount) {
        uint256 reward = stakingBLP.getRewardOf(user);
        vm.assume(reward > 0);

        vm.prank(user);
        vm.expectEmit(address(stakingBLP));
        emit BLPStaking.Claimed(user, reward);
        stakingBLP.claim();

        assertEq(blp.balanceOf(user), reward);
    }

    function test_RevertWithdraw_UnlockTimestamp() public stake {
        vm.prank(user);
        vm.expectRevert("BlastUP: you must wait more to withdraw");
        stakingBLP.withdraw();
    }

    function test_withdrawFuzz(uint256 amount) public stakeFuzz(amount) {
        uint256 reward = stakingBLP.getRewardOf(user);
        vm.assume(reward > 0);
        (uint256 balance,,,) = stakingBLP.users(user);
        uint256 lockedBefore = stakingBLP.totalLocked();

        vm.prank(user);
        stakingBLP.withdraw();

        assertEq(lockedBefore - balance, stakingBLP.totalLocked());
        assertEq(blp.balanceOf(user), balance + reward);
    }
}
