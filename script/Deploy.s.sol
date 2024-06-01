// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {ERC20Mock} from "../src/mocks/ERC20Mock.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {LockedBLP, LockedBLPStaking, BLPStaking} from "../src/LockedBLPStaking.sol";
import {BLPBalanceOracle} from "../src/BLPBalanceOracle.sol";
import {BlastUPNFT} from "../src/BLPNFT.sol";
import {OracleMock} from "../src/mocks/OracleMock.sol";
import {ERC20RebasingMock, ERC20RebasingTestnetMock} from "../src/mocks/ERC20RebasingTestnetMock.sol";
import {WETHRebasingTestnetMock} from "../src/mocks/WETHRebasingTestnetMock.sol";

contract DeployScript is Script {
    using SafeERC20 for IERC20;

    struct DeployStruct {
        address blp;
        address dao;
        address points;
        address pointsOperator;
        uint256 tgeTimestamp;
        uint8 tgePercent;
        uint256 vestingStart;
        uint256 vestingDuration;
        address deployer;
        address oracle;
        address addressForCollected;
        uint256 mintPrice;
        uint256 lockedBLPMintAmount;
        address usdb;
        address weth;
        uint256[] lockTimes;
        uint32[] percents;
    }

    function _deploy(DeployStruct memory input) internal {
        address[] memory lockedBLPStakingAddresses = new address[](input.lockTimes.length);
        address[] memory stakingAddresses = new address[](input.lockTimes.length * 2);
        for (uint256 i = 0; i < input.lockTimes.length; i++) {
            stakingAddresses[i] = lockedBLPStakingAddresses[i] =
                (vm.computeCreateAddress(input.deployer, vm.getNonce(input.deployer) + i + 2));
            console.log("LockedBLPStaking", lockedBLPStakingAddresses[i], "with percent:", input.percents[i]);
        }
        address blastBoxAddress = vm.computeCreateAddress(address(input.dao), vm.getNonce(input.dao) + 1);
        LockedBLP lockedBLP = new LockedBLP(
            lockedBLPStakingAddresses,
            input.blp,
            input.points,
            input.pointsOperator,
            input.dao,
            input.tgeTimestamp,
            input.tgePercent,
            input.vestingStart,
            input.vestingDuration,
            blastBoxAddress
        );

        BlastUPNFT blastBox = new BlastUPNFT(
            input.weth,
            input.usdb,
            input.points,
            input.pointsOperator,
            input.dao,
            input.oracle,
            input.addressForCollected,
            input.mintPrice,
            address(lockedBLP),
            input.lockedBLPMintAmount
        );

        for (uint256 i = 0; i < input.lockTimes.length; i++) {
            new LockedBLPStaking(
                input.dao,
                address(lockedBLP),
                input.blp,
                input.points,
                input.pointsOperator,
                input.lockTimes[i],
                input.percents[i]
            );
        }

        for (uint256 i = input.lockTimes.length; i < input.lockTimes.length * 2; i++) {
            stakingAddresses[i] = address(
                new BLPStaking(
                    input.dao,
                    input.blp,
                    input.blp,
                    input.points,
                    input.pointsOperator,
                    input.lockTimes[i - input.lockTimes.length],
                    input.percents[i - input.lockTimes.length]
                )
            );
            console.log(
                "BLPStaking",
                stakingAddresses[i - input.lockTimes.length],
                "with percent:",
                input.percents[i - input.lockTimes.length]
            );
        }

        BLPBalanceOracle oracle = new BLPBalanceOracle(input.dao, stakingAddresses);

        console.log("BLP", input.blp);
        console.log("LockedBLP", address(lockedBLP));
        console.log("BLPBalanceOracle", address(oracle));
        console.log("BlastUP NFT", address(blastBox));
    }

    function deploySepolia() public {
        vm.startBroadcast();
        (, address deployer,) = vm.readCallers();

        ERC20RebasingMock USDB = ERC20RebasingTestnetMock(0x66Ed1EEB6CEF5D4aCE858890704Af9c339266276);
        ERC20RebasingMock WETH = WETHRebasingTestnetMock(0x3470769fBA0Aa949ecdAF83CAD069Fa2DC677389);
        address oracle = 0xc447B8cAd2db7a8B0fDde540B038C9e06179c0f7;
        address points = 0x2fc95838c71e76ec69ff817983BFf17c710F34E0;
        ERC20Mock blp = new ERC20Mock("BlastUp", "BLP", 18);

        console.log("usdb: ", address(USDB));
        console.log("weth: ", address(WETH));

        address addressForCollected = deployer;
        uint256 mintPrice = 120 * 1e18;
        uint256 lockedBLPMintAmount = 1000 * 1e18;
        uint256[] memory lockTimes = new uint256[](3);
        uint32[] memory percents = new uint32[](3);
        lockTimes[0] = 2000;
        percents[0] = 10 * 1e2;
        lockTimes[1] = 4000;
        percents[1] = 20 * 1e2;
        lockTimes[2] = 6000;
        percents[2] = 30 * 1e2;

        _deploy(
            DeployStruct(
                address(blp),
                deployer,
                points,
                deployer,
                block.timestamp + 1200,
                25,
                block.timestamp + 3600,
                24000,
                deployer,
                oracle,
                addressForCollected,
                mintPrice,
                lockedBLPMintAmount,
                address(USDB),
                address(WETH),
                lockTimes,
                percents
            )
        );
    }
}
