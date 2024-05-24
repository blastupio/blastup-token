// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {BLPToken} from "../../src/BLPToken.sol";

contract BLPTokenTest is Test {
    address internal admin;
    uint256 internal adminPrivateKey;

    BLPToken blp;

    address user;
    address user2;
    address user3;

    function setUp() public virtual {
        adminPrivateKey = 0xa11ce;
        admin = vm.addr(adminPrivateKey);
        user = address(10);
        user2 = address(11);
        user3 = address(12);

        blp = new BLPToken(admin);
    }

    function test() public {
        vm.assertEq(blp.totalSupply(), 1_000_000_000 * (10 ** 18));
        vm.assertEq(blp.decimals(), 18);
        vm.assertEq(blp.name(), "BlastUP Token");
        vm.assertEq(blp.symbol(), "BLP");
        vm.assertEq(blp.balanceOf(admin), blp.totalSupply());
        vm.prank(admin);
        blp.transfer(user, 1e18);
        vm.assertEq(blp.balanceOf(user), 1e18);
        vm.assertEq(blp.balanceOf(admin), blp.totalSupply() - 1e18);
    }
}
