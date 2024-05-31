// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Mock} from "../../src/mocks/ERC20Mock.sol";
import {LockedBLP} from "../../src/LockedBLP.sol";
import {BlastPointsMock} from "../../src/mocks/BlastPointsMock.sol";
import {LockedBLPStaking, BLPStaking} from "../../src/LockedBLPStaking.sol";

contract BaseLockedBLP is Test {
    ERC20Mock blp;

    address internal admin;
    uint256 internal adminPrivateKey;

    LockedBLP lockedBLP;
    BlastPointsMock points;
    LockedBLPStaking lockedBLPStaking;
    uint256 lockTime;
    uint32 percent;

    address user;
    address user2;
    address user3;

    function setUp() public virtual {
        adminPrivateKey = 0xa11ce;
        admin = vm.addr(adminPrivateKey);
        user = address(10);
        user2 = address(11);
        user3 = address(12);
        lockTime = 1000;
        percent = 10 * 1e2;

        vm.startPrank(admin);
        points = new BlastPointsMock();
        blp = new ERC20Mock("BlastUp", "BLP", 18);
        address lockedBLPStakingAddress = vm.computeCreateAddress(address(admin), vm.getNonce(admin) + 1);
        lockedBLP =
            new LockedBLP(lockedBLPStakingAddress, address(blp), address(points), admin, admin, 1000, 10, 2000, 10000);
        lockedBLPStaking =
            new LockedBLPStaking(admin, address(lockedBLP), address(blp), address(points), admin, lockTime, percent);
        vm.stopPrank();
        vm.assertEq(lockedBLP.transferWhitelist(address(lockedBLPStaking)), true);
        vm.assertEq(address(blp), lockedBLP.blp());
    }
}
