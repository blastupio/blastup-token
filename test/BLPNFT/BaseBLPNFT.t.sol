// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Mock} from "../../src/mocks/ERC20Mock.sol";
import {BLPStaking} from "../../src/BLPStaking.sol";
import {BlastPointsMock} from "../../src/mocks/BlastPointsMock.sol";
import {BlastUPNFT} from "../../src/BLPNFT.sol";
import {OracleMock} from "../../src/mocks/OracleMock.sol";
import {WETHRebasingMock} from "../../src/mocks/WETHRebasingMock.sol";
import {ERC20RebasingMock} from "../../src/mocks/ERC20RebasingMock.sol";
import {LockedBLP, LockedBLPStaking} from "../../src/LockedBLPStaking.sol";

contract BaseBlastUPNFT is Test {
    ERC20Mock blp;

    address internal admin;
    uint256 internal adminPrivateKey;

    BlastUPNFT blastBox;
    BlastPointsMock points;
    OracleMock oracle;
    uint256 mintPrice;
    uint256 lockedBLPMintAmount;
    LockedBLP lockedBLP;
    LockedBLPStaking lockedBLPStaking;
    address[] lockedBLPStakingAddresses;

    uint256 lockTime;
    uint32 percent;

    address user;
    address user2;
    address user3;

    ERC20RebasingMock constant USDB = ERC20RebasingMock(0x4300000000000000000000000000000000000003);
    WETHRebasingMock constant WETH = WETHRebasingMock(0x4300000000000000000000000000000000000004);

    function setUp() public virtual {
        adminPrivateKey = 0xa11ce;
        admin = vm.addr(adminPrivateKey);
        user = address(10);
        user2 = address(11);
        user3 = address(12);
        mintPrice = 130e8;
        lockedBLPMintAmount = 2000 * 1e18;
        lockTime = 1000;
        percent = 10 * 1e2;

        vm.startPrank(admin);
        blp = new ERC20Mock("BlastUp", "BLP", 18);
        points = new BlastPointsMock();
        oracle = new OracleMock();

        ERC20RebasingMock usdb = new ERC20RebasingMock("USDB", "USDB", 18);
        bytes memory code = address(usdb).code;
        vm.etch(0x4300000000000000000000000000000000000003, code);

        WETHRebasingMock weth = new WETHRebasingMock("WETH", "WETH", 18);
        bytes memory code2 = address(weth).code;
        vm.etch(0x4300000000000000000000000000000000000004, code2);

        lockedBLPStakingAddresses.push(vm.computeCreateAddress(address(admin), vm.getNonce(admin) + 1));
        address blastBoxAddress = vm.computeCreateAddress(address(admin), vm.getNonce(admin) + 2);
        lockedBLP = new LockedBLP(
            lockedBLPStakingAddresses,
            address(blp),
            address(points),
            admin,
            admin,
            1000,
            10,
            2000,
            10000,
            blastBoxAddress
        );
        lockedBLPStaking = new LockedBLPStaking(admin, address(lockedBLP), address(points), admin, lockTime, percent);

        blastBox = new BlastUPNFT(
            address(WETH),
            address(USDB),
            address(points),
            admin,
            admin,
            address(oracle),
            address(admin),
            mintPrice,
            address(lockedBLP)
        );
        vm.stopPrank();
    }
}
