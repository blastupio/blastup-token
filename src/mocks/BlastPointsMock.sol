// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.25;

import {IBlastPoints} from "../interfaces/IBlastPoints.sol";

contract BlastPointsMock is IBlastPoints {
    function configurePointsOperator(address operator) external {}
    function configurePointsOperatorOnBehalf(address contractAddress, address operator) external {}
}
