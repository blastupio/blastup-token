// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.25;

import {Script, console2} from "forge-std/Script.sol";
import {BlastUpOFTAdapter} from "../src/BLASTUPAdapter.sol";
import {BlastUPOFT} from "../src/BLASTUPOFT.sol";
import {IMessagingChannel} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessagingChannel.sol";

contract OFTScript is Script {
    /// @notice Struct to store input data for deploying OFTs
    /// @param name The name of the token
    /// @param symbol The symbol of the token
    /// @param endpoint The address of the layerzero endpoint
    /// @param rpc The RPC URL of the network
    struct OFTDeployInput {
        string name;
        string symbol;
        address endpoint;
        string rpc;
    }

    /// @notice Struct to set peers for deployed OFTs
    /// @param oft The address of the OFT
    /// @param rpc The RPC URL of the network
    struct SetPeers {
        address oft;
        string rpc;
    }

    function _addressToBytes32(address input) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(input)));
    }

    function deploy_testnet() public {
        (, address deployer,) = vm.readCallers();
        uint256 optimismForkId = vm.createFork(vm.rpcUrl("optimism_sepolia"));
        uint256 blastForkId = vm.createSelectFork(vm.rpcUrl("blast_sepolia"));

        address blp = address(0x1cc0034324c405Bb092fEFa0B732970D4b6D81D5);
        address layerZeroEndpoint = address(0x6EDCE65403992e310A62460808c4b910D972f10f);
        vm.startBroadcast();
        BlastUpOFTAdapter adapter = new BlastUpOFTAdapter(blp, layerZeroEndpoint, deployer);
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

    /// @notice Deploys BlastUpOFTAdapter on the Blast mainnet
    function deploy_adapter() public {
        (, address deployer,) = vm.readCallers();
        uint256 blastMainnetForkId = vm.createFork(vm.rpcUrl("blast"));

        vm.selectFork(blastMainnetForkId);
        address blp = address(0x33C62f70B14C438075be70defb77626b1aC3b503);
        address layerZeroEndpoint = address(0x1a44076050125825900e736c501f859c50fE728c);
        vm.startBroadcast();
        BlastUpOFTAdapter adapter = new BlastUpOFTAdapter(blp, layerZeroEndpoint, deployer);
        vm.stopBroadcast();

        console2.log("adapter", address(adapter));
    }

    /// @notice Deploys multiple OFTs and sets their peers
    /// @param ofts The array of OFTDeployInput structs
    function deploy_ofts(OFTDeployInput[] calldata ofts) public {
        (, address deployer,) = vm.readCallers();
        BlastUPOFT oft;
        // Deploy and setPeers for deployed oft and adapter
        for (uint256 i = 0; i < ofts.length; i++) {
            vm.createSelectFork(ofts[i].rpc);
            vm.startBroadcast();

            oft = new BlastUPOFT(ofts[i].name, ofts[i].symbol, ofts[i].endpoint, deployer);

            console2.log("chain", ofts[i].rpc, "OFT addr", address(oft));
            vm.stopBroadcast();
        }
    }

    /// @notice Sets peers for already deployed OFTs
    /// @param peers The array of SetPeers structs
    function set_peers(SetPeers[] calldata peers) public {
        uint256[] memory forkIds = new uint256[](peers.length);
        // Create forks
        for (uint256 i = 0; i < peers.length; i++) {
            forkIds[i] = vm.createFork(peers[i].rpc);
        }
        for (uint256 i = 0; i < peers.length; i++) {
            vm.selectFork(forkIds[i]);
            uint32 currentEid = IMessagingChannel(BlastUPOFT(peers[i].oft).endpoint()).eid();
            for (uint256 j = 0; j < peers.length; j++) {
                vm.selectFork(forkIds[j]);
                if (i != j) {
                    vm.startBroadcast();
                    if (BlastUPOFT(peers[j].oft).peers(currentEid) == "") {
                        BlastUPOFT(peers[j].oft).setPeer(currentEid, _addressToBytes32(peers[i].oft));
                    }
                    vm.stopBroadcast();
                }
            }
        }
        console2.log("Succesfully set peers for all OFTs");
    }
}
