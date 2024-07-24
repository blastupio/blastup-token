// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.25;

import {Script, console2} from "forge-std/Script.sol";
import {BlastUPAdapter} from "../src/BLASTUPAdapter.sol";
import {BlastUPOFT} from "../src/BLASTUPOFT.sol";

contract OFTScript is Script {
    /// @notice Struct to store input data for deploying OFTs
    struct OFTDeployInput {
        string name;
        /// @notice The name of the token
        string symbol;
        /// @notice The symbol of the token
        address endpoint;
        /// @notice The address of the layerzero endpoint
        string rpc;
        /// @notice The RPC URL of the network
        uint32 eid;
    }
    /// @notice The environment ID

    /// @notice Struct to set peers for deployed OFTs
    struct SetPeers {
        uint32 eid;
        /// @notice The environment ID
        address oft;
        /// @notice The address of the OFT
        string rpc;
    }
    /// @notice The RPC URL of the network

    struct OftsAndForks {
        address deployedOFT;
        uint256 forkId;
    }

    function _addressToBytes32(address input) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(input)));
    }

    function deploy_testnet() public {
        (, address deployer,) = vm.readCallers();
        uint256 optimismForkId = vm.createFork(vm.rpcUrl("optimism_sepolia"));
        uint256 blastForkId = vm.createFork(vm.rpcUrl("blast_sepolia"));

        vm.selectFork(blastForkId);
        address blp = address(0x1cc0034324c405Bb092fEFa0B732970D4b6D81D5);
        address layerZeroEndpoint = address(0x6EDCE65403992e310A62460808c4b910D972f10f);
        vm.startBroadcast();
        BlastUPAdapter adapter = new BlastUPAdapter(blp, layerZeroEndpoint, deployer);
        vm.stopBroadcast();

        console2.log("adapter", address(adapter));

        vm.selectFork(optimismForkId);
        vm.startBroadcast();
        BlastUPOFT optimism_oft = new BlastUPOFT("Optimism BLP", "OBLP", layerZeroEndpoint, deployer);

        console2.log("optimism OFT", address(optimism_oft));
        optimism_oft.setPeer(40243, _addressToBytes32(address(adapter)));
        vm.stopBroadcast();

        vm.selectFork(blastForkId);
        vm.startBroadcast();
        adapter.setPeer(40232, _addressToBytes32(address(optimism_oft)));
    }

    /// @notice Deploys BlastUPAdapter on the Blast mainnet
    function deploy_adapter() public {
        (, address deployer,) = vm.readCallers();
        uint256 blastMainnetForkId = vm.createFork(vm.rpcUrl("blast"));

        vm.selectFork(blastMainnetForkId);
        address blp = address(0x33C62f70B14C438075be70defb77626b1aC3b503);
        address layerZeroEndpoint = address(0x1a44076050125825900e736c501f859c50fE728c);
        vm.startBroadcast();
        BlastUPAdapter adapter = new BlastUPAdapter(blp, layerZeroEndpoint, deployer);
        vm.stopBroadcast();

        console2.log("adapter", address(adapter));
    }

    /// @notice Deploys multiple OFTs and sets their peers
    /// @param ofts The array of OFTDeployInput structs
    function deploy_ofts(OFTDeployInput[] calldata ofts) public {
        (, address deployer,) = vm.readCallers();
        OftsAndForks[] memory deployedOFTs = new OftsAndForks[](ofts.length);
        BlastUPAdapter adapter;
        uint32 BLAST_EID = 30243;
        BlastUPOFT oft;
        uint256 blastMainnetForkId = vm.createFork(vm.rpcUrl("blast"));
        // Deploy and setPeers for deployed oft and adapter
        for (uint256 i = 0; i < ofts.length; i++) {
            deployedOFTs[i].forkId = vm.createSelectFork(ofts[i].rpc);
            vm.startBroadcast();

            oft = new BlastUPOFT(ofts[i].name, ofts[i].symbol, ofts[i].endpoint, deployer);
            deployedOFTs[i].deployedOFT = address(oft);

            console2.log("chain", ofts[i].rpc, "OFT addr", deployedOFTs[i].deployedOFT);
            oft.setPeer(BLAST_EID, _addressToBytes32(address(adapter)));
            vm.stopBroadcast();
            vm.selectFork(blastMainnetForkId);
            vm.startBroadcast();
            adapter.setPeer(ofts[i].eid, _addressToBytes32(address(oft)));
            vm.stopBroadcast();
        }

        // Set peers between all deployed OFTs
        for (uint256 i = 0; i < ofts.length; i++) {
            vm.selectFork(deployedOFTs[i].forkId);
            vm.startBroadcast();
            for (uint256 j = 0; j < i; j++) {
                BlastUPOFT(deployedOFTs[j].deployedOFT).setPeer(
                    ofts[i].eid, _addressToBytes32(deployedOFTs[i].deployedOFT)
                );
            }
            for (uint256 j = i + 1; j < ofts.length; j++) {
                BlastUPOFT(deployedOFTs[j].deployedOFT).setPeer(
                    ofts[i].eid, _addressToBytes32(deployedOFTs[i].deployedOFT)
                );
            }
            vm.stopBroadcast();
        }
    }

    /// @notice Sets peers for already deployed OFTs
    /// @param peers The array of SetPeers structs
    function setPeers(SetPeers[] calldata peers) public {
        for (uint256 i = 0; i < peers.length; i++) {
            vm.createSelectFork(peers[i].rpc);
            vm.startBroadcast();
            for (uint256 j = 0; j < i; j++) {
                BlastUPOFT(peers[j].oft).setPeer(peers[i].eid, _addressToBytes32(peers[i].oft));
            }
            for (uint256 j = i + 1; j < peers.length; j++) {
                BlastUPOFT(peers[j].oft).setPeer(peers[i].eid, _addressToBytes32(peers[i].oft));
            }
            vm.stopBroadcast();
        }
    }
}
