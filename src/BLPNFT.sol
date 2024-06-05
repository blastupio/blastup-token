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
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract BlastUPNFT is ERC721, Ownable, Pausable {
    using SafeERC20 for IERC20;

    IERC20 public immutable USDB;
    IERC20 public immutable WETH;
    uint8 public immutable decimalsUSDB;
    IChainlinkOracle public immutable oracle;
    uint8 public immutable oracleDecimals;
    LockedBLP public immutable lockedBLP;

    address public addressForCollected;
    uint256 public lockedBLPMintAmount;
    uint256 public mintPrice; // in USDT
    uint256 public nextTokenId;

    /// @notice Whitelist of addresses which can receive BlastUPNFT.
    mapping(address account => bool) public transferWhitelist;

    constructor(
        address _weth,
        address _usdb,
        address _points,
        address _pointsOperator,
        address dao,
        address _oracle,
        address _addressForCollected,
        uint256 _mintPrice,
        address _lockedBLP,
        uint256 _lockedBLPMintAmount
    ) ERC721("BlastUP Box", "BLPBOX") Ownable(dao) {
        mintPrice = _mintPrice;
        WETH = IERC20(_weth);
        USDB = IERC20(_usdb);
        lockedBLP = LockedBLP(_lockedBLP);
        lockedBLPMintAmount = _lockedBLPMintAmount;
        oracle = IChainlinkOracle(_oracle);
        oracleDecimals = oracle.decimals();
        decimalsUSDB = IERC20Metadata(_usdb).decimals();
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

    function setLockedBLPMintAmount(uint256 _lockedBLPMintAmount) external onlyOwner {
        lockedBLPMintAmount = _lockedBLPMintAmount;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function mint(address to, address paymentContract) public payable whenNotPaused {
        address[] memory toLockedBLP = new address[](1);
        uint256[] memory amountLockedBLP = new uint256[](1);
        toLockedBLP[0] = to;
        amountLockedBLP[0] = lockedBLPMintAmount;
        if (msg.sender == owner()) {
            _mint(to, nextTokenId++);
            lockedBLP.mint(toLockedBLP, amountLockedBLP);
        } else {
            uint256 volume = mintPrice;
            if (msg.value > 0 || paymentContract == address(WETH)) {
                volume = _convertUSDBToETH(volume);
            } else {
                require(paymentContract == address(USDB), "BlastUP: invalid payment contract");
            }

            _mint(to, nextTokenId++);
            lockedBLP.mint(toLockedBLP, amountLockedBLP);

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

    /// @notice It is function only used to withdraw funds accidentally sent to the contract.
    function withdrawFunds(address token) external onlyOwner {
        if (token == address(0)) {
            (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
            require(success, "BlastUP: failed to send ETH");
        } else {
            IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
        }
    }
}
