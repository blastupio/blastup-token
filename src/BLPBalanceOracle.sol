// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.25;

import {BLPStaking} from "./BLPStaking.sol";
import {IBLPBalanceOracle} from "./interfaces/IBLPBalanceOracle.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract BLPBalanceOracle is IBLPBalanceOracle, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet blpStaking;

    constructor(address _owner, address[] memory _blpStaking) Ownable(_owner) {
        for (uint256 i = 0; i < _blpStaking.length; i++) {
            blpStaking.add(_blpStaking[i]);
        }
    }

    function balanceOf(address user) external view returns (uint256) {
        uint256 balance;
        for (uint256 i = 0; i < blpStaking.length(); i++) {
            (uint256 amountOfTokens,,,) = BLPStaking(blpStaking.at(i)).users(user);
            balance += amountOfTokens;
        }
        return balance;
    }

    function contains(address addr) external view returns (bool) {
        return blpStaking.contains(addr);
    }

    function values() external view returns (address[] memory) {
        return blpStaking.values();
    }

    function addBLPStaking(address _blpStaking) external onlyOwner {
        blpStaking.add(_blpStaking);
    }

    function removeBLPStaking(address _blpStaking) external onlyOwner {
        blpStaking.remove(_blpStaking);
    }
}
