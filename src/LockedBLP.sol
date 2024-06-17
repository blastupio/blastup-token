// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IBlastPoints} from "./interfaces/IBlastPoints.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract LockedBLP is ERC20, Ownable {
    using SafeERC20 for IERC20Metadata;

    uint256 public tgeTimestamp;
    uint256 public vestingStart;
    uint256 public vestingDuration;
    uint8 public tgePercent;
    address public blp;

    mapping(address account => uint256) public allocations;
    mapping(address account => uint256) _claimedAmount;

    /// @notice Whitelist of addresses which can receive LockedBLP.
    mapping(address account => bool) public transferWhitelist;
    mapping(address minter => bool) public mintersWhitelist;

    constructor(
        address[] memory _lockedBLPStakings,
        address _blp,
        address _points,
        address _pointsOperator,
        address admin,
        uint256 _tgeTimestamp,
        uint8 _tgePercent,
        uint256 _vestingStart,
        uint256 _vestingDuration,
        address blpNFT
    ) ERC20("BlastUP Locked Token", "LBLP") Ownable(admin) {
        blp = _blp;
        tgeTimestamp = _tgeTimestamp;
        tgePercent = _tgePercent;
        vestingStart = _vestingStart;
        vestingDuration = _vestingDuration;
        IBlastPoints(_points).configurePointsOperator(_pointsOperator);

        for (uint256 i = 0; i < _lockedBLPStakings.length; i++) {
            transferWhitelist[_lockedBLPStakings[i]] = true;
            mintersWhitelist[_lockedBLPStakings[i]] = true;
        }

        transferWhitelist[address(0)] = true;
        mintersWhitelist[admin] = true;
        mintersWhitelist[blpNFT] = true;
    }

    /// @notice Returns amount of tokens which is unlocked for the given user with respect
    /// to TGE and vesting schedule.
    function getUnlockedAmount(address user) public view returns (uint256) {
        if (block.timestamp < tgeTimestamp) return 0;

        uint256 tgeAmount = allocations[user] * tgePercent / 100;
        if (block.timestamp < vestingStart) return tgeAmount;

        uint256 totalVestedAmount = allocations[user] - tgeAmount;
        uint256 elapsed = Math.min(block.timestamp - vestingStart, vestingDuration);
        uint256 vestedAmount = elapsed * totalVestedAmount / vestingDuration;

        return tgeAmount + vestedAmount;
    }

    /// @notice Returns amount which can be immidiately claimed by the user. Accounts for
    /// already claimed tokens and for tokens which were transferred away (to staking, for example).
    function getClaimableAmount(address user) public view returns (uint256) {
        return Math.min(getUnlockedAmount(user) - _claimedAmount[user], balanceOf(user));
    }

    function _update(address from, address to, uint256 value) internal override {
        if (!transferWhitelist[from] && !transferWhitelist[to]) {
            revert("BlastUP: not whitelisted");
        }
        super._update(from, to, value);
    }

    function setTgeTimestamp(uint256 newTgeTimestamp) external onlyOwner {
        require(newTgeTimestamp > block.timestamp, "BlastUP: invalid tge timestamp");
        require(tgeTimestamp > block.timestamp, "BlastUP: can't change TGE after TGE start");
        tgeTimestamp = newTgeTimestamp;
    }

    function setVestingStart(uint256 newVestingStart) external onlyOwner {
        require(newVestingStart > block.timestamp, "BlastUP: invalid vesting start");
        require(vestingStart > block.timestamp, "BlastUP: vesting already started");
        vestingStart = newVestingStart;
    }

    function setVestingDuration(uint256 _vestingDuration) external onlyOwner {
        require(vestingStart > block.timestamp, "BlastUP: vesting already started");
        vestingDuration = _vestingDuration;
    }

    function setTgePercent(uint8 _tgePercent) external onlyOwner {
        require(tgeTimestamp > block.timestamp, "BlastUP: can't change TGE after TGE start");
        tgePercent = _tgePercent;
    }

    function addWhitelistedAddress(address addr) external onlyOwner {
        transferWhitelist[addr] = true;
    }

    function removeWhitelistedAddress(address addr) external onlyOwner {
        transferWhitelist[addr] = false;
    }

    function addMinter(address addr) external onlyOwner {
        mintersWhitelist[addr] = true;
    }

    function removeMinter(address addr) external onlyOwner {
        mintersWhitelist[addr] = false;
    }

    function mint(address[] memory users, uint256[] memory amounts) external {
        require(mintersWhitelist[msg.sender], "BlastUP: you are not in the whitelist");
        for (uint256 i = 0; i < users.length; i++) {
            allocations[users[i]] += amounts[i];
            _mint(users[i], amounts[i]);
        }
    }

    function claim() external {
        uint256 amount = getClaimableAmount(msg.sender);
        require(amount > 0, "BlastUP: amount must be gt zero");
        _claimedAmount[msg.sender] += amount;
        _burn(msg.sender, amount);
        IERC20Metadata(blp).safeTransfer(msg.sender, amount);
    }
}
