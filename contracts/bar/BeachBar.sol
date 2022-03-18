// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

import './YieldBox.sol';
import './interfaces/IWrappedNative.sol';
import './interfaces/IStrategy.sol';
import './enums/YieldBoxTokenType.sol';
import '@boringcrypto/boring-solidity/contracts/BoringOwnable.sol';

enum ContractType {
    lowRisk,
    mediumRisk,
    highRisk
}

struct MasterContract {
    address location;
    ContractType risk;
}

contract BeachBar is BoringOwnable, YieldBox {
    IERC20 private immutable tapToken;
    uint96 private immutable tapAssetId;

    MasterContract[] masterContracts;
    mapping(address => bool) isMasterContractRegistered;

    address feeTo; // Protocol
    address feeVeTap; // TAP distributors

    constructor(
        IWrappedNative wrappedNative_,
        YieldBoxURIBuilder uriBuilder_,
        IERC20 tapToken_
    ) YieldBox(wrappedNative_, uriBuilder_) {
        tapToken = tapToken_;
        tapAssetId = uint96(registerAsset(TokenType.ERC20, address(tapToken_), IStrategy(address(0)), 0));
    }

    /// @notice Register a master contract
    /// @param masterContract_ The address of the contract
    /// @param contractType_ The risk type of the contract
    function registerMasterContract(address masterContract_, ContractType contractType_) external onlyOwner {
        MasterContract memory mc;
        mc.location = masterContract_;
        mc.risk = contractType_;
        masterContracts.push(mc);
        isMasterContractRegistered[masterContract_] = true;
    }

    /// @notice Register a Mixologist
    /// @param masterContract_ The address of the master contract which must be already registered
    /// @param data The init data of the Mixologist
    /// @param useCreate2 Whether to use create2 or not
    function registerMixologist(
        address masterContract_,
        bytes calldata data,
        bool useCreate2
    ) external payable onlyOwner {
        require(isMasterContractRegistered[masterContract_] == true, 'BeachBar: MC not registered');

        deploy(masterContract_, data, useCreate2);
    }

    /// @inheritdoc AssetRegister
    function registerAsset(
        TokenType tokenType,
        address contractAddress,
        IStrategy strategy,
        uint256 tokenId
    ) public override onlyOwner returns (uint256 assetId) {
        assetId = super.registerAsset(tokenType, contractAddress, strategy, tokenId);
    }

    function setFeeTo(address feeTo_) external onlyOwner {
        feeTo = feeTo_;
    }

    function setFeeVeTap(address feeVeTap_) external onlyOwner {
        feeVeTap = feeVeTap_;
    }
}
