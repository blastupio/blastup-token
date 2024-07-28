// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.25;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IBlastPoints} from "./interfaces/IBlastPoints.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IChainlinkOracle} from "./interfaces/IChainlinkOracle.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {LockedBLASTUP} from "./LockedBLASTUP.sol";

contract BlastUPNFT is ERC721, Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable USDB;
    IERC20 public immutable WETH;
    uint8 public immutable decimalsUSDB;
    IChainlinkOracle public immutable oracle;
    uint8 public immutable oracleDecimals;
    LockedBLASTUP public immutable lockedBLP;

    address public addressForCollected;
    /// @notice mintPrice in USDB.
    uint256 public mintPrice;
    /// @notice BLP price in USDB.
    uint256 public blpPrice = 0.065e18;
    uint256 public maxTokenId = 9999;
    uint256 public nextTokenId;

    string metadataUrl;

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
        string memory _metadataUrl
    ) ERC721("BlastUP Box", "BLPBOX") Ownable(dao) {
        mintPrice = _mintPrice;
        WETH = IERC20(_weth);
        USDB = IERC20(_usdb);
        lockedBLP = LockedBLASTUP(_lockedBLP);
        oracle = IChainlinkOracle(_oracle);
        oracleDecimals = oracle.decimals();
        decimalsUSDB = IERC20Metadata(_usdb).decimals();
        addressForCollected = _addressForCollected;
        IBlastPoints(_points).configurePointsOperator(_pointsOperator);

        transferWhitelist[address(0)] = true;
        metadataUrl = _metadataUrl;
    }

    function _baseURI() internal view override returns (string memory) {
        return metadataUrl;
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

    function _getK(uint16 q) internal pure returns (uint256) {
        if (q < 3) return 300;
        if (q < 5) return 350;
        if (q < 10) return 400;
        if (q < 20) return 450;
        if (q < 30) return 500;
        if (q < 50) return 550;
        return 600;
    }

    function _getBLPReward(uint16 quantity) internal view returns (uint256) {
        uint256 usdbValue = (1e4 + _getK(quantity)) * quantity * mintPrice / 1e4;
        return usdbValue * (10 ** lockedBLP.decimals()) / blpPrice;
    }

    /// @notice Converts given amount of USDB to ETH, using oracle price
    function _convertUSDBToETH(uint256 volume) private view returns (uint256) {
        return volume * 1e18 * (10 ** oracleDecimals) / (_getETHPrice() * (10 ** decimalsUSDB));
    }

    function addWhitelistedAddress(address addr) external onlyOwner {
        transferWhitelist[addr] = true;
    }

    function removeWhitelistedAddress(address addr) external onlyOwner {
        transferWhitelist[addr] = false;
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

    function _mintLockedBLP(address to, uint256 amount) internal {
        address[] memory users = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        users[0] = to;
        amounts[0] = amount;
        lockedBLP.mint(users, amounts);
    }

    function mint(address to, address paymentContract, uint16 quantity) public payable whenNotPaused nonReentrant {
        require(nextTokenId + quantity <= maxTokenId, "BlastUP: max token id reached");

        if (msg.sender != owner()) {
            uint256 usdbCost = quantity * mintPrice;
            if (paymentContract == address(USDB)) {
                USDB.safeTransferFrom(msg.sender, addressForCollected, usdbCost);
            } else {
                require(paymentContract == address(WETH), "BlastUP: invalid payment contract");
                uint256 wethCost = _convertUSDBToETH(usdbCost);
                if (msg.value > 0) {
                    (bool success,) = payable(addressForCollected).call{value: wethCost}("");
                    require(success, "BlastUP: failed to send ETH");
                    (success,) = payable(msg.sender).call{value: msg.value - wethCost}("");
                    require(success, "BlastUP: failed to send ETH");
                } else {
                    WETH.safeTransferFrom(msg.sender, addressForCollected, wethCost);
                }
            }
        }

        _mintLockedBLP(to, _getBLPReward(quantity));

        for (uint256 i = 0; i < quantity; i++) {
            _mint(to, nextTokenId++);
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

    function setMetadataUrl(string memory _metadataUrl) external onlyOwner {
        metadataUrl = _metadataUrl;
    }
}
