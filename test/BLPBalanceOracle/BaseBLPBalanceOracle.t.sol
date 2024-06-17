// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Mock} from "../../src/mocks/ERC20Mock.sol";
import {LockedBLP} from "../../src/LockedBLP.sol";
import {BlastPointsMock} from "../../src/mocks/BlastPointsMock.sol";
import {LockedBLPStaking, BLPStaking} from "../../src/LockedBLPStaking.sol";
import {BLPBalanceOracle} from "../../src/BLPBalanceOracle.sol";

contract BaseBLPBalanceOracle is Test {
    ERC20Mock blp;

    address internal admin;
    uint256 internal adminPrivateKey;

    LockedBLP lockedBLP;
    BlastPointsMock points;
    LockedBLPStaking lockedBLPStaking;
    LockedBLPStaking lockedBLPStaking2;
    LockedBLPStaking lockedBLPStaking3;
    address[] lockedBLPStakingAddresses;
    uint256[] lockTimes;
    uint32[] percents;
    BLPStaking stakingBLP;
    BLPStaking stakingBLP2;
    BLPStaking stakingBLP3;
    address[] stakingBLPAddresses;

    BLPBalanceOracle blpOracle;
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
        lockTimes.push(1000);
        percents.push(10 * 1e2);
        lockTimes.push(2000);
        percents.push(20 * 1e2);
        lockTimes.push(3000);
        percents.push(30 * 1e2);
        lockTime = 1000;
        percent = 10 * 1e2;

        vm.startPrank(admin);
        points = new BlastPointsMock();
        blp = new ERC20Mock("BlastUp", "BLP", 18);
        lockedBLPStakingAddresses.push(vm.computeCreateAddress(address(admin), vm.getNonce(admin) + 1));
        lockedBLPStakingAddresses.push(vm.computeCreateAddress(address(admin), vm.getNonce(admin) + 2));
        lockedBLPStakingAddresses.push(vm.computeCreateAddress(address(admin), vm.getNonce(admin) + 3));
        lockedBLP = new LockedBLP(
            lockedBLPStakingAddresses, address(blp), address(points), admin, admin, 1000, 10, 2000, 10000, address(0)
        );
        lockedBLPStaking =
            new LockedBLPStaking(admin, address(lockedBLP), address(points), admin, lockTimes[0], percents[0]);
        lockedBLPStaking2 =
            new LockedBLPStaking(admin, address(lockedBLP), address(points), admin, lockTimes[1], percents[1]);
        lockedBLPStaking3 =
            new LockedBLPStaking(admin, address(lockedBLP), address(points), admin, lockTimes[2], percents[2]);

        stakingBLP = new BLPStaking(admin, address(blp), address(points), admin, lockTime, percent);
        stakingBLP2 = new BLPStaking(admin, address(blp), address(points), admin, lockTimes[1], percents[1]);
        stakingBLP3 = new BLPStaking(admin, address(blp), address(points), admin, lockTimes[2], percents[2]);
        stakingBLPAddresses.push(address(stakingBLP));
        stakingBLPAddresses.push(address(stakingBLP2));
        stakingBLPAddresses.push(address(stakingBLP3));

        address[] memory stakings = new address[](lockedBLPStakingAddresses.length + stakingBLPAddresses.length);
        for (uint256 i = 0; i < lockedBLPStakingAddresses.length; i++) {
            stakings[i] = lockedBLPStakingAddresses[i];
        }
        for (uint256 i = lockedBLPStakingAddresses.length; i < stakings.length; i++) {
            stakings[i] = stakingBLPAddresses[i - lockedBLPStakingAddresses.length];
        }
        blpOracle = new BLPBalanceOracle(admin, stakings);
        vm.stopPrank();
        vm.assertEq(lockedBLP.transferWhitelist(address(lockedBLPStakingAddresses[0])), true);
        vm.assertEq(address(blp), lockedBLP.blp());
    }
}
