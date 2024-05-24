// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.25;

interface IBLPBalanceOracle {
    function balanceOf(address user) external view returns (uint256);
}
