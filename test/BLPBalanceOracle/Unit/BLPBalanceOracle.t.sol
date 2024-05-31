// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {BaseBLPBalanceOracle} from "../BaseBLPBalanceOracle.t.sol";

contract BLPBalanceOracleTest is BaseBLPBalanceOracle {
    function test_settersConstants() public {
        vm.assertEq(blpOracle.contains(address(lockedBLPStaking)), true);
        vm.assertEq(blpOracle.contains(address(stakingBLP)), true);
        address[] memory stakingAddresses = blpOracle.values();
        vm.assertEq(stakingAddresses.length, 2);

        vm.startPrank(admin);
        vm.assertEq(blpOracle.contains(address(100)), false);
        blpOracle.addBLPStaking(address(100));
        vm.assertEq(blpOracle.contains(address(100)), true);
        blpOracle.removeBLPStaking(address(100));
        vm.assertEq(blpOracle.contains(address(100)), false);
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert();
        blpOracle.addBLPStaking(address(100));
        vm.expectRevert();
        blpOracle.removeBLPStaking(address(lockedBLPStaking));
        vm.stopPrank();
    }

    function test_checkBalances() public {
        uint256 amount = 1e18;

        blp.mint(user, amount);
        address[] memory toLockedBLP = new address[](1);
        uint256[] memory amountLockedBLP = new uint256[](1);
        toLockedBLP[0] = user;
        amountLockedBLP[0] = 100 * 1e18;
        vm.prank(admin);
        lockedBLP.mint(toLockedBLP, amountLockedBLP);

        vm.startPrank(user);
        vm.assertEq(blpOracle.balanceOf(user), 0);
        blp.approve(address(stakingBLP), amount);
        stakingBLP.stake(amount);
        vm.assertEq(blpOracle.balanceOf(user), amount);

        lockedBLP.approve(address(lockedBLPStaking), amountLockedBLP[0]);
        lockedBLPStaking.stake(amountLockedBLP[0]);
        vm.assertEq(blpOracle.balanceOf(user), amount + amountLockedBLP[0]);
        vm.stopPrank();
    }
}
