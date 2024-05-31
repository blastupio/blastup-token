// // SPDX-License-Identifier: UNLICENSED

// pragma solidity ^0.8.1;

// import {Script, console} from "forge-std/Script.sol";
// // import {
// //     TransparentUpgradeableProxy,
// //     ProxyAdmin,
// //     ITransparentUpgradeableProxy,
// //     ERC1967Utils
// // } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
// // import {YieldStaking} from "../src/YieldStaking.sol";
// // import {Launchpad, MessageHashUtils, ECDSA} from "../src/Launchpad.sol";
// // import {ILaunchpad} from "../src/interfaces/ILaunchpad.sol";
// // import {LaunchpadV2} from "../src/LaunchpadV2.sol";
// // import {BLPStaking} from "../src/BLPStaking.sol";

// import {ERC20Mock} from "../src/mocks/ERC20Mock.sol";
// // import {OracleMock} from "../src/mocks/OracleMock.sol";

// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// // import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// // import {WETHRebasingMock} from "../src/mocks/WETHRebasingMock.sol";
// // import {ERC20RebasingMock} from "../src/mocks/ERC20RebasingMock.sol";
// // import {ERC20RebasingTestnetMock} from "../src/mocks/ERC20RebasingTestnetMock.sol";
// // import {WETHRebasingTestnetMock} from "../src/mocks/WETHRebasingTestnetMock.sol";
// import {LockedBLP, LockedBLPStaking, BLPStaking} from "../src/LockedBLPStaking.sol";
// import {BLPBalanceOracle} from "../src/BLPBalanceOracle.sol";

// contract DeployScript is Script {
//     using SafeERC20 for IERC20;

//     struct DeployStruct {
//         address blp;
//         address dao;
//         address points;
//         address pointsOperator;
//         uint256 tgeTimestamp;
//         uint8 tgePercent;
//         uint256 vestingStart;
//         uint256 vestingDuration;
//         address deployer;
//     }

//     function _deploy(DeployStruct memory input) internal {
//         BLPStaking blpStaking = new BLPStaking(input.dao, input.blp, input.blp, input.points, input.pointsOperator);
//         address lockedBLPStakingAddress = vm.computeCreateAddress(input.deployer, vm.getNonce(input.deployer) + 1);
//         LockedBLP lockedBLP = new LockedBLP(
//             lockedBLPStakingAddress,
//             input.blp,
//             input.points,
//             input.pointsOperator,
//             input.dao,
//             input.tgeTimestamp,
//             input.tgePercent,
//             input.vestingStart,
//             input.vestingDuration
//         );
//         LockedBLPStaking lockedBLPStaking =
//             new LockedBLPStaking(input.dao, address(lockedBLP), input.blp, input.points, input.pointsOperator);
//         BLPBalanceOracle oracle = new BLPBalanceOracle(input.dao, address(blpStaking), address(lockedBLPStaking));

//         console.log("BLP", input.blp);
//         console.log("LockedBLP", address(lockedBLP));
//         console.log("BLPStaking", address(blpStaking));
//         console.log("LockedBLPStaking:", address(lockedBLPStaking));
//         console.log("BLPBalanceOracle", address(oracle));
//     }

//     function deploySepolia() public {
//         vm.startBroadcast();
//         (, address deployer,) = vm.readCallers();

//         address points = 0x2fc95838c71e76ec69ff817983BFf17c710F34E0;
//         ERC20Mock blp = new ERC20Mock("BlastUp", "BLP", 18);

//         _deploy(
//             DeployStruct(
//                 address(blp),
//                 deployer,
//                 points,
//                 deployer,
//                 block.timestamp + 1200,
//                 25,
//                 block.timestamp + 3600,
//                 24000,
//                 deployer
//             )
//         );
//     }
// }
