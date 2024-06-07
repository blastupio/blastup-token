// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {BaseBlastUPNFT} from "../BaseBLPNFT.t.sol";

contract BlastUPNFTTest is BaseBlastUPNFT {
    uint16 quantity = 1;
    uint256 bonusForOneBox = 60 * 1e18;

    function test_settersConstants() public {
        vm.assertEq(blastBox.name(), "BlastUP Box");
        vm.assertEq(blastBox.symbol(), "BLPBOX");
        vm.assertEq(address(blastBox.USDB()), address(0x4300000000000000000000000000000000000003));
        vm.assertEq(address(blastBox.WETH()), address(0x4300000000000000000000000000000000000004));
        vm.assertEq(blastBox.decimalsUSDB(), 18);
        vm.assertEq(blastBox.oracleDecimals(), 8);
        vm.assertEq(blastBox.addressForCollected(), admin);

        vm.assertEq(blastBox.mintPrice(), mintPrice);
        vm.startPrank(user);
        vm.expectRevert();
        blastBox.setMintPrice(1e19);
        vm.stopPrank();
        vm.prank(admin);
        blastBox.setMintPrice(1e19);
        vm.assertEq(blastBox.mintPrice(), 1e19);
    }

    function test_transfers() public {
        vm.assertEq(blastBox.transferWhitelist(address(0)), true);
        vm.startPrank(user);
        vm.expectRevert();
        blastBox.addWhitelistedAddress(user);
        vm.stopPrank();

        vm.startPrank(admin);
        blastBox.addWhitelistedAddress(user2);
        blastBox.mint(user2, address(0), quantity);
        vm.stopPrank();

        vm.prank(user2);
        blastBox.transferFrom(user2, user, 0);
        vm.assertEq(blastBox.ownerOf(0), user);
        vm.prank(admin);
        blastBox.removeWhitelistedAddress(user2);
        vm.startPrank(user);
        vm.expectRevert("BlastUP: not whitelisted");
        blastBox.transferFrom(user, user2, 0);
        vm.stopPrank();
    }

    function test_RevertMint_whenPaused() public {
        vm.expectRevert();
        blastBox.pause();

        vm.prank(admin);
        blastBox.pause();

        vm.startPrank(user);
        vm.expectRevert();
        blastBox.mint(user, address(USDB), quantity);
        vm.stopPrank();
        vm.startPrank(admin);
        vm.expectRevert();
        blastBox.mint(user, address(USDB), quantity);
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert();
        blastBox.unpause();
        vm.stopPrank();

        vm.startPrank(admin);
        blastBox.unpause();
        blastBox.mint(user, address(0), quantity);
    }

    function test_mint() public {
        // mint by owner
        vm.startPrank(admin);
        blastBox.mint(user, address(0), quantity);
        vm.assertEq(blastBox.balanceOf(user), 1);
        vm.assertEq(blastBox.ownerOf(0), user);
        vm.assertEq(lockedBLP.balanceOf(user), lockedBLPMintAmount + bonusForOneBox);
        //mint by other users
        USDB.mint(user2, mintPrice * 2 * 1e10);
        vm.startPrank(user2);
        USDB.approve(address(blastBox), mintPrice * 2 * 1e10);
        blastBox.mint(user2, address(USDB), quantity);
        vm.assertEq(blastBox.balanceOf(user2), 1);
        vm.assertEq(blastBox.ownerOf(1), user2);
        vm.assertEq(lockedBLP.balanceOf(user2), lockedBLPMintAmount + bonusForOneBox);

        WETH.mint(user2, 1e20);
        WETH.approve(address(blastBox), 1e20);
        blastBox.mint(user, address(WETH), quantity);
        vm.assertEq(blastBox.balanceOf(user), 2);
        vm.assertEq(blastBox.ownerOf(2), user);
        vm.assertEq(lockedBLP.balanceOf(user), lockedBLPMintAmount * 2 + bonusForOneBox * 2);

        vm.deal(user2, 1e20);
        blastBox.mint{value: 1e20}(user3, address(0), quantity);
        vm.assertGt(user2.balance, 0);
        vm.assertEq(blastBox.balanceOf(user3), 1);
        vm.assertEq(blastBox.ownerOf(3), user3);
        vm.assertEq(lockedBLP.balanceOf(user3), lockedBLPMintAmount + bonusForOneBox);
    }

    function test_gas() public {
        vm.startPrank(admin);
        blastBox.mint(user, address(0), 61);
        blastBox.mint(user, address(0), 61);
        vm.assertEq(blastBox.balanceOf(user), 122);
        vm.assertEq(blastBox.ownerOf(60), user);
        vm.assertGt(lockedBLP.balanceOf(user), lockedBLPMintAmount * 122);
    }
}
