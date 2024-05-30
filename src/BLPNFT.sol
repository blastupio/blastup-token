// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.25;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IBlastPoints} from "./interfaces/IBlastPoints.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IChainlinkOracle} from "./interfaces/IChainlinkOracle.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {LockedBLP} from "./LockedBLP.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

contract BlastUPNFT is ERC721, Ownable, Pausable {
    using SafeERC20 for IERC20;

    IERC20 public immutable USDB;
    IERC20 public immutable WETH;
    uint8 public immutable decimalsUSDB;
    IChainlinkOracle public immutable oracle;
    uint8 public immutable oracleDecimals;
    address addressForCollected;

    uint256 public mintPrice; // in USDT
    uint256 public nextTokenId;

    address lockedBLP;

    /// @notice Whitelist of addresses which can receive BlastUPNFT.
    mapping(address account => bool) public transferWhitelist;

    constructor(
        string memory name_,
        string memory symbol_,
        address _weth, 
        address _usdb,
        address _points,
        address _pointsOperator,
        address admin,
        address _oracle,
        address _addressForCollected,
        uint256 _mintPrice
    ) ERC721(name_, symbol_) Ownable(admin) {
        mintPrice = _mintPrice;
        WETH = IERC20(_weth);
        USDB = IERC20(_usdb);
        oracle = IChainlinkOracle(_oracle);
        oracleDecimals = oracle.decimals();
        addressForCollected = _addressForCollected;
        IBlastPoints(_points).configurePointsOperator(_pointsOperator);

        transferWhitelist[address(0)] = true;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _update(address to, uint256 id, address auth) internal override returns (address) {
        if (!transferWhitelist[auth] && !transferWhitelist[to]) {
            revert("BlastUP: not whitelisted");
        }
        return super._update(to, id, auth);
    }

    /// @notice Fetches ETH price from oracle, performing additional safety checks to ensure the oracle is healthy.
    function _getETHPrice() private view returns (uint256) {
        (uint80 roundID, int256 price,, uint256 timestamp, uint80 answeredInRound) = oracle.latestRoundData();
        require(answeredInRound >= roundID, "Stale price");
        require(timestamp != 0, "Round not complete");
        require(price > 0, "Chainlink price reporting 0");

        return uint256(price);
    }

    /// @notice Converts given amount of USDB to ETH, using oracle price
    function _convertUSDBToETH(uint256 volume) private view returns (uint256) {
        return volume * (10 ** 18) * (10 ** oracleDecimals) / (10 ** decimalsUSDB) / _getETHPrice();
    }

    function addWhitelistedAddress(address addr) external onlyOwner {
        transferWhitelist[addr] = true;
    }

    function removeWhitelistedAddress(address addr) external onlyOwner {
        transferWhitelist[addr] = false;
    }

    function setLockedBLP(address _lockedBLP) external onlyOwner {
        lockedBLP = _lockedBLP;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function mint(address to, address paymentContract) public payable whenNotPaused {
        if (msg.sender == owner()) {
            _mint(to, nextTokenId++);
        } else {
            uint256 volume = mintPrice;
            if (msg.value > 0 || paymentContract == address(WETH)) {
                volume = _convertUSDBToETH(volume);
            } else {
                require(paymentContract == address(USDB), "BlastUP: invalid payment contract");
            }

            _mint(to, nextTokenId++);

            if (msg.value > 0) {
                bool success;
                (success,) = payable(addressForCollected).call{value: volume}("");
                require(success, "BlastUP: failed to send ETH");
                (success,) = payable(msg.sender).call{value: msg.value - volume}("");
                require(success, "BlastUP: failed to send ETH");
            } else {
                IERC20(paymentContract).safeTransferFrom(msg.sender, addressForCollected, volume);
            }
        }
    }
}
