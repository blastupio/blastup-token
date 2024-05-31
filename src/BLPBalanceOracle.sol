// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.25;

import {BLPStaking} from "./BLPStaking.sol";
import {IBLPBalanceOracle} from "./interfaces/IBLPBalanceOracle.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract BLPBalanceOracle is IBLPBalanceOracle, Ownable {
    struct AddressSet {
        address[] addrs;
        mapping(address => bool) saved;
    }

    AddressSet blpStaking;
    AddressSet lockedBLPStaking;

    constructor(address _owner, address[] memory _blpStaking, address[] memory _lockedBLPStaking) Ownable(_owner) {
        for (uint256 i = 0; i < _blpStaking.length; i++) {
            blpStaking.addrs.push(_blpStaking[i]);
            blpStaking.saved[_blpStaking[i]] = true;
        }
        for (uint256 i = 0; i < _lockedBLPStaking.length; i++) {
            lockedBLPStaking.addrs.push(_lockedBLPStaking[i]);
            lockedBLPStaking.saved[_lockedBLPStaking[i]] = true;
        }
    }

    function balanceOf(address user) external view returns (uint256) {
        uint256 balance;
        for (uint256 i = 0; i < blpStaking.addrs.length; i++) {
            if (blpStaking.saved[blpStaking.addrs[i]]) {
                (uint256 amountOfTokens,,,) = BLPStaking(blpStaking.addrs[i]).users(user);
                balance += amountOfTokens;
            }
        }
        for (uint256 i = 0; i < lockedBLPStaking.addrs.length; i++) {
            if (lockedBLPStaking.saved[lockedBLPStaking.addrs[i]]) {
                (uint256 amountOfLockedTokens,,,) = BLPStaking(lockedBLPStaking.addrs[i]).users(user);
                balance += amountOfLockedTokens;
            }
        }
        return balance;
    }

    function contains(address addr) external view returns (bool) {
        return blpStaking.saved[addr] || lockedBLPStaking.saved[addr];
    }

    function addBLPStaking(address _blpStaking) external onlyOwner {
        blpStaking.addrs.push(_blpStaking);
        blpStaking.saved[_blpStaking] = true;
    }

    function addLockedBLPStaking(address _lockedBLPStaking) external onlyOwner {
        lockedBLPStaking.addrs.push(_lockedBLPStaking);
        lockedBLPStaking.saved[_lockedBLPStaking] = true;
    }

    function removeBLPStaking(address _blpStaking) external onlyOwner {
        blpStaking.saved[_blpStaking] = false;
    }

    function removeLockedBLPStaking(address _lockedBLPStaking) external onlyOwner {
        lockedBLPStaking.saved[_lockedBLPStaking] = false;
    }
}
