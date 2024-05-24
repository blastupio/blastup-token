// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {BaseLockedBLP, LockedBLPStaking, BLPStaking} from "../BaseLockedBLP.t.sol";

contract LockedBLPStakingTest is BaseLockedBLP {
    function test_RevertStake_invalidLockTime() public {
        uint256 amount = 1e18;
        address[] memory to = new address[](1);
        uint256[] memory amountMint = new uint256[](1);
        amountMint[0] = amount;
        to[0] = user;

        vm.prank(admin);
        lockedBLP.mint(to, amountMint);
        vm.prank(user);
        lockedBLP.approve(address(lockedBLPStaking), amount);

        vm.prank(user);
        vm.expectRevert("BlastUP: invalid lockTime");
        lockedBLPStaking.stake(amount, 1);

        vm.prank(admin);
        lockedBLPStaking.setLockTimeToPercent(1e10, 15);

        vm.prank(user);
        vm.expectRevert("BlastUP: invalid lockTime");
        lockedBLPStaking.stake(amount, 10);
    }

    function test_RevertStake_BalanceMustBeGtMin() public {
        uint256 amount = 1e8;
        uint256 lockTime = 10;

        address[] memory to = new address[](1);
        uint256[] memory amountMint = new uint256[](1);
        amountMint[0] = amount;
        to[0] = user;

        vm.prank(admin);
        lockedBLP.mint(to, amountMint);
        vm.prank(user);
        lockedBLP.approve(address(lockedBLPStaking), amount);

        vm.startPrank(admin);
        lockedBLPStaking.setLockTimeToPercent(lockTime, 10);
        lockedBLPStaking.setMinBalance(1e5);
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert("BlastUP: you must send more to stake");
        lockedBLPStaking.stake(1, lockTime);
    }

    function test_stake() public {
        uint256 amount = 1e18;
        uint256 lockTime = 100;

        address[] memory to = new address[](1);
        uint256[] memory amountMint = new uint256[](1);
        amountMint[0] = amount;
        to[0] = user;

        vm.prank(admin);
        lockedBLP.mint(to, amountMint);

        vm.prank(admin);
        lockedBLPStaking.setLockTimeToPercent(lockTime, 10);

        vm.startPrank(user);
        lockedBLP.approve(address(lockedBLPStaking), amount);
        vm.expectEmit(address(lockedBLPStaking));
        emit BLPStaking.Staked(user, amount);
        lockedBLPStaking.stake(amount, lockTime);

        vm.warp(1e5);
        assertGt(lockedBLPStaking.getRewardOf(user), 0);
    }

    function test_stakeFuzz(uint256 amount, uint256 lockTime, uint32 percent) public {
        vm.warp(1001);
        amount = bound(amount, 1e6, 1e40);
        percent = uint32(bound(percent, 100, 20_000));
        lockTime = bound(lockTime, 1e4, 1e15);

        address[] memory to = new address[](1);
        uint256[] memory amountMint = new uint256[](1);
        amountMint[0] = amount;
        to[0] = user;

        vm.prank(admin);
        lockedBLP.mint(to, amountMint);

        vm.prank(admin);
        lockedBLPStaking.setLockTimeToPercent(lockTime, percent);

        vm.startPrank(user);
        lockedBLP.approve(address(lockedBLPStaking), amount);
        vm.expectEmit(address(lockedBLPStaking));
        emit BLPStaking.Staked(user, amount);
        lockedBLPStaking.stake(amount, lockTime);
        vm.stopPrank();
        vm.prank(admin);
        vm.expectRevert();
        lockedBLPStaking.withdrawFunds(amount);

        uint256 reward = lockedBLPStaking.getRewardOf(user);
        assertEq(reward, 0);

        vm.warp(lockTime * 1e6);
        assertGt(lockedBLPStaking.getRewardOf(user), 0);
    }

    modifier stake() {
        uint256 amount = 1e18;
        uint256 lockTime = 100;
        uint32 percent = 10 * 1e2;

        uint256 preCalculatedReward = (amount * percent / 1e4) * lockTime / 365 days;
        address[] memory to = new address[](1);
        uint256[] memory amountMint = new uint256[](1);
        amountMint[0] = amount;
        to[0] = user;
        vm.prank(admin);
        lockedBLP.mint(to, amountMint);
        blp.mint(address(lockedBLPStaking), preCalculatedReward);

        vm.prank(admin);
        lockedBLPStaking.setLockTimeToPercent(lockTime, percent);

        vm.startPrank(user);
        lockedBLP.approve(address(lockedBLPStaking), amount);
        lockedBLPStaking.stake(amount, lockTime);
        vm.stopPrank();
        _;
    }

    modifier stakeFuzz(uint256 amount, uint256 lockTime, uint32 percent) {
        amount = bound(amount, 1e5, 1e40);
        percent = uint32(bound(percent, 100, 20_000));
        lockTime = bound(lockTime, 1e4, 1e15);

        address[] memory to = new address[](1);
        uint256[] memory amountMint = new uint256[](1);
        amountMint[0] = amount;
        to[0] = user;

        uint256 preCalculatedReward = (amount * percent / 1e4) * lockTime / 365 days;
        vm.prank(admin);
        lockedBLP.mint(to, amountMint);
        blp.mint(address(lockedBLPStaking), preCalculatedReward);

        vm.prank(admin);
        lockedBLPStaking.setLockTimeToPercent(lockTime, percent);

        vm.startPrank(user);
        lockedBLP.approve(address(lockedBLPStaking), amount);
        lockedBLPStaking.stake(amount, lockTime);
        vm.stopPrank();
        vm.warp(lockTime * 1e5);
        _;
    }

    function test_claimFuzz(uint256 amount, uint256 lockTime, uint32 percent)
        public
        stakeFuzz(amount, lockTime, percent)
    {
        uint256 reward = lockedBLPStaking.getRewardOf(user);
        vm.assume(reward > 0);

        vm.prank(user);
        vm.expectEmit(address(lockedBLPStaking));
        emit BLPStaking.Claimed(user, reward);
        lockedBLPStaking.claim();

        assertEq(blp.balanceOf(user), reward);
    }

    function test_RevertWithdraw_UnlockTimestamp() public stake {
        vm.prank(user);
        vm.expectRevert("BlastUP: you must wait more to withdraw");
        lockedBLPStaking.withdraw();
    }

    function test_withdrawFuzz(uint256 amount, uint256 lockTime, uint32 percent)
        public
        stakeFuzz(amount, lockTime, percent)
    {
        uint256 reward = lockedBLPStaking.getRewardOf(user);
        vm.assume(reward > 0);
        (uint256 balance,,,) = lockedBLPStaking.users(user);

        vm.prank(user);
        lockedBLPStaking.withdraw();

        assertEq(blp.balanceOf(user), reward);
        assertEq(lockedBLP.balanceOf(user), balance);
    }
}
