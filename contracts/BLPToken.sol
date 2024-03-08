// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BLPToken is ERC20 {
    // Initial supply of token 1B, precision is 18
    uint256 constant INITIAL_SUPPLY = 1_000_000_000;
    address public daoAddress;

    constructor(address _daoAddress) ERC20("BlastUP", "BLP") {
        daoAddress = _daoAddress;
        _mint(daoAddress, INITIAL_SUPPLY);
    }
}