// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {BaseLockedBLP, LockedBLPStaking, BLPStaking, LockedBLP, IERC20} from "../BaseLockedBLP.t.sol";

contract LockedBLPStakingTest is BaseLockedBLP {
    function test_RevertStake_BalanceMustBeGtMin() public {
        uint256 amount = 1e8;

        address[] memory to = new address[](1);
        uint256[] memory amountMint = new uint256[](1);
        amountMint[0] = amount;
        to[0] = user;

        vm.prank(admin);
        lockedBLP.mint(to, amountMint);
        vm.prank(user);
        lockedBLP.approve(address(lockedBLPStaking), amount);

        vm.startPrank(admin);
        lockedBLPStaking.setMinBalance(1e5);
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert("BlastUP: you must send more to stake");
        lockedBLPStaking.stake(1);
    }

    function test_stake() public {
        uint256 amount = 2e18;

        address[] memory to = new address[](1);
        uint256[] memory amountMint = new uint256[](1);
        amountMint[0] = amount;
        to[0] = user;

        vm.prank(admin);
        lockedBLP.mint(to, amountMint);

        vm.startPrank(user);
        lockedBLP.approve(address(lockedBLPStaking3), amount);
        vm.expectEmit(address(lockedBLPStaking3));
        emit BLPStaking.Staked(user, amount);
        lockedBLPStaking3.stake(amount);

        vm.warp(block.timestamp + 900);
        lockedBLPStaking3.claim();

        vm.warp(1e5);
        assertGt(lockedBLPStaking3.getRewardOf(user), 0);
    }

    function test_stakeFuzz(uint256 amount) public {
        vm.warp(1001);
        amount = bound(amount, 1e6, 1e40);

        address[] memory to = new address[](1);
        uint256[] memory amountMint = new uint256[](1);
        amountMint[0] = amount;
        to[0] = user;

        vm.prank(admin);
        lockedBLP.mint(to, amountMint);

        vm.startPrank(user);
        lockedBLP.approve(address(lockedBLPStaking), amount);
        vm.expectEmit(address(lockedBLPStaking));
        emit BLPStaking.Staked(user, amount);
        lockedBLPStaking.stake(amount);
        vm.stopPrank();
        vm.prank(admin);
        vm.expectRevert();
        lockedBLPStaking.withdrawFunds(address(lockedBLP), amount);

        uint256 reward = lockedBLPStaking.getRewardOf(user);
        assertEq(reward, 0);

        vm.warp(lockTimes[0] * 1e6);
        assertGt(lockedBLPStaking.getRewardOf(user), 0);
    }

    modifier stake() {
        uint256 amount = 1e18;

        uint256 preCalculatedReward = (amount * percents[0] / 1e4) * lockTimes[0] / 365 days;
        address[] memory to = new address[](1);
        uint256[] memory amountMint = new uint256[](1);
        amountMint[0] = amount;
        to[0] = user;
        vm.prank(admin);
        lockedBLP.mint(to, amountMint);

        vm.startPrank(user);
        lockedBLP.approve(address(lockedBLPStaking), amount);
        lockedBLPStaking.stake(amount);
        vm.stopPrank();
        _;
    }

    modifier stakeFuzz(uint256 amount) {
        amount = bound(amount, 1e5, 1e40);

        address[] memory to = new address[](1);
        uint256[] memory amountMint = new uint256[](1);
        amountMint[0] = amount;
        to[0] = user;

        uint256 preCalculatedReward = (amount * percents[0] / 1e4) * lockTimes[0] / 365 days;
        vm.prank(admin);
        lockedBLP.mint(to, amountMint);

        vm.startPrank(user);
        lockedBLP.approve(address(lockedBLPStaking), amount);
        lockedBLPStaking.stake(amount);
        vm.stopPrank();
        vm.warp(lockTimes[0] * 1e5);
        _;
    }

    function test_claimFuzz(uint256 amount) public stakeFuzz(amount) {
        uint256 reward = lockedBLPStaking.getRewardOf(user);
        vm.assume(reward > 0);

        vm.startPrank(user);
        uint256 lockedBLPBalanceOfUserBefore = lockedBLP.balanceOf(user);
        vm.expectEmit(address(lockedBLP));
        emit IERC20.Transfer(address(0), user, reward);
        vm.expectEmit(address(lockedBLPStaking));
        emit BLPStaking.Claimed(user, reward);
        lockedBLPStaking.claim();
        assertEq(lockedBLP.balanceOf(user), lockedBLPBalanceOfUserBefore + reward);
        vm.stopPrank();
    }

    function test_RevertWithdraw_UnlockTimestamp() public stake {
        vm.prank(user);
        vm.expectRevert("BlastUP: you must wait more to withdraw");
        lockedBLPStaking.withdraw();
    }

    function test_withdrawFuzz(uint256 amount) public stakeFuzz(amount) {
        uint256 reward = lockedBLPStaking.getRewardOf(user);
        vm.assume(reward > 0);
        uint256 lockedBLPBalanceOfUserBefore = lockedBLP.balanceOf(user);
        (uint256 balance,,,) = lockedBLPStaking.users(user);

        vm.prank(user);
        lockedBLPStaking.withdraw();

        assertEq(lockedBLP.balanceOf(user), lockedBLPBalanceOfUserBefore + balance + reward);
    }
}
