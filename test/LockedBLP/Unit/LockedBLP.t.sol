// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {BaseLockedBLP} from "../BaseLockedBLP.t.sol";

contract LockedBLPTest is BaseLockedBLP {
    function test_settersConstants() public {
        vm.assertEq(lockedBLP.name(), "BlastUP Locked Token");
        vm.assertEq(lockedBLP.symbol(), "LBLASTUP");

        vm.startPrank(admin);
        lockedBLP.setTgePercent(20);
        vm.assertEq(lockedBLP.tgePercent(), 20);

        vm.warp(100);
        vm.expectRevert("BlastUP: invalid tge timestamp");
        lockedBLP.setTgeTimestamp(block.timestamp - 10);
        vm.expectRevert("BlastUP: invalid vesting start");
        lockedBLP.setVestingStart(block.timestamp - 20);

        lockedBLP.setTgeTimestamp(1100);
        vm.assertEq(lockedBLP.tgeTimestamp(), 1100);
        lockedBLP.setVestingStart(2200);
        vm.assertEq(lockedBLP.vestingStart(), 2200);
        lockedBLP.setVestingDuration(15000);
        vm.assertEq(lockedBLP.vestingDuration(), 15000);

        vm.assertEq(lockedBLP.transferWhitelist(user2), false);
        lockedBLP.addWhitelistedAddress(user2);
        vm.assertEq(lockedBLP.transferWhitelist(user2), true);
        vm.stopPrank();
    }

    function test_RevertTransfers() public {
        address[] memory to = new address[](1);
        uint256[] memory amount = new uint256[](1);
        to[0] = user;
        amount[0] = 100 * 1e18;
        vm.prank(admin);
        lockedBLP.mint(to, amount);

        vm.startPrank(user);
        vm.expectRevert("BlastUP: not whitelisted");
        lockedBLP.transfer(user2, 1e18);
        vm.stopPrank();
    }

    function test_claim() public {
        address[] memory to = new address[](1);
        uint256[] memory amount = new uint256[](1);
        to[0] = user;
        amount[0] = 100 * 1e18;
        uint256 tgeAmount = amount[0] * lockedBLP.tgePercent() / 100;
        vm.prank(admin);
        lockedBLP.mint(to, amount);
        blp.mint(address(lockedBLP), amount[0]);

        vm.assertEq(lockedBLP.getClaimableAmount(user), 0);
        vm.warp(lockedBLP.tgeTimestamp());
        vm.assertEq(lockedBLP.getUnlockedAmount(user), tgeAmount);
        vm.prank(user);
        lockedBLP.claim();
        vm.assertEq(blp.balanceOf(user), tgeAmount);
        vm.warp(lockedBLP.vestingStart() + lockedBLP.vestingDuration());
        vm.prank(user);
        lockedBLP.claim();
        vm.assertEq(blp.balanceOf(user), amount[0]);
    }
}
