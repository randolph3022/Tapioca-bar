// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {Rebase} from "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";

// Tapioca
import {SGLLiquidation, SGLCollateral, Singularity, SGLLeverage, SGLCommon, SGLBorrow} from "./Singularity.sol";
import {IMarketLiquidatorReceiver} from "tapioca-periph/interfaces/bar/IMarketLiquidatorReceiver.sol";
import {IYieldBox} from "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";

contract MarketHelper {
    error ExchangeRateNotValid();

    /// @notice transforms amount to shares for a market's permit operation
    /// @param amount the amount to transform
    /// @param tokenId the YieldBox asset id
    /// @return share amount transformed into shares
    function computeAllowedLendShare(Singularity sgl, uint256 amount, uint256 tokenId)
        external
        view
        returns (uint256 share)
    {
        IYieldBox yieldBox = sgl.yieldBox();
        (uint128 totalAssetElastic, uint128 totalAssetBase) = sgl.totalAsset();
        (uint128 totalBorrowElastic,) = sgl.totalBorrow();

        uint256 allShare = totalAssetElastic + yieldBox.toShare(tokenId, totalBorrowElastic, true);
        share = (amount * allShare) / totalAssetBase;
    }

    /// @notice returns the collateral amount used in a liquidation
    /// @dev useful to compute minAmountOut for collateral to asset swap
    /// @param user the user to liquidate
    /// @param maxBorrowPart max borrow part for user
    /// @param minLiquidationBonus minimum liquidation bonus to accept
    function viewLiquidationCollateralAmount(
        Singularity sgl,
        address user,
        uint256 maxBorrowPart,
        uint256 minLiquidationBonus,
        uint256 exchangeRatePrecision,
        uint256 feeDecimalsPrecision
    ) external view returns (bytes memory) {
        (bool updated, uint256 _exchangeRate) = sgl.oracle().peek(sgl.oracleData());
        if (!updated || _exchangeRate == 0) {
            _exchangeRate = sgl.exchangeRate(); //use stored rate
        }
        if (_exchangeRate == 0) revert ExchangeRateNotValid();

        (uint128 totalBorrowElastic, uint128 totalBorrowBase) = sgl.totalBorrow();

        SGLCommon._ViewLiquidationStruct memory data;
        {
            data.user = user;
            data.maxBorrowPart = maxBorrowPart;
            data.minLiquidationBonus = minLiquidationBonus;
            data.exchangeRate = _exchangeRate;
            data.yieldBox = sgl.yieldBox();
            data.collateralId = sgl.collateralId();
            data.userCollateralShare = sgl.userCollateralShare(user);
            data.userBorrowPart = sgl.userBorrowPart(user);
            data.totalBorrow = Rebase({elastic: totalBorrowElastic, base: totalBorrowBase});
            data.liquidationBonusAmount = sgl.liquidationBonusAmount();
            data.liquidationCollateralizationRate = sgl.liquidationCollateralizationRate();
            data.liquidationMultiplier = sgl.liquidationMultiplier();
            data.exchangeRatePrecision = exchangeRatePrecision;
            data.feeDecimalsPrecision = feeDecimalsPrecision;
        }
        (bool success, bytes memory returnData) = address(sgl.liquidationModule()).staticcall(
            abi.encodeWithSelector(SGLLiquidation.viewLiquidationCollateralAmount.selector, data)
        );
        if (!success) {
            revert(_getRevertMsg(returnData));
        }

        return returnData;
    }

    /// @notice Adds `collateral` from msg.sender to the account `to`.
    /// @param from Account to transfer shares from.
    /// @param to The receiver of the tokens.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
    /// False if tokens from msg.sender in `yieldBox` should be transferred.
    /// @param share The amount of shares to add for `to`.
    function addCollateral(Singularity sgl, address from, address to, bool skim, uint256 amount, uint256 share)
        external
        returns (Singularity.Module[] memory modules, bytes[] memory calls)
    {
        modules = new Singularity.Module[](1);
        calls = new bytes[](1);
        modules[0] = Singularity.Module.Collateral;
        calls[0] = abi.encodeWithSelector(SGLCollateral.addCollateral.selector, from, to, skim, amount, share);
    }

    /// @notice Removes `share` amount of collateral and transfers it to `to`.
    /// @param from Account to debit collateral from.
    /// @param to The receiver of the shares.
    /// @param share Amount of shares to remove.
    function removeCollateral(Singularity sgl, address from, address to, uint256 share)
        external
        returns (Singularity.Module[] memory modules, bytes[] memory calls)
    {
        Singularity.Module[] memory modules = new Singularity.Module[](1);
        bytes[] memory calls = new bytes[](1);
        modules[0] = Singularity.Module.Collateral;
        calls[0] = abi.encodeWithSelector(SGLCollateral.removeCollateral.selector, from, to, share);
    }

    /// @notice Sender borrows `amount` and transfers it to `to`.
    /// @param from Account to borrow for.
    /// @param to The receiver of borrowed tokens.
    /// @param amount Amount to borrow.
    function borrow(Singularity sgl, address from, address to, uint256 amount)
        external
        returns (Singularity.Module[] memory modules, bytes[] memory calls)
    {
        Singularity.Module[] memory modules = new Singularity.Module[](1);
        bytes[] memory calls = new bytes[](1);
        modules[0] = Singularity.Module.Borrow;
        calls[0] = abi.encodeWithSelector(SGLBorrow.borrow.selector, from, to, amount);

        (, bytes[] memory results) = sgl.execute(modules, calls, true);
    }

    /// @notice View the result of a borrow operation.
    function borrowView(bytes calldata result) external pure returns (uint256 part, uint256 share) {
        (part, share) = abi.decode(result, (uint256, uint256));
    }

    /// @notice Repays a loan.
    /// @param from Address to repay from.
    /// @param to Address of the user this payment should go.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
    /// False if tokens from msg.sender in `yieldBox` should be transferred.
    /// @param part The amount to repay. See `userBorrowPart`.
    function repay(Singularity sgl, address from, address to, bool skim, uint256 part)
        external
        returns (Singularity.Module[] memory modules, bytes[] memory calls)
    {
        Singularity.Module[] memory modules = new Singularity.Module[](1);
        bytes[] memory calls = new bytes[](1);
        modules[0] = Singularity.Module.Borrow;
        calls[0] = abi.encodeWithSelector(SGLBorrow.repay.selector, from, to, skim, part);
    }

    /// @notice view the result of a repay operation.
    function repayView(bytes calldata result) external pure returns (uint256 amount) {
        amount = abi.decode(result, (uint256));
    }

    /// @notice Lever down: Sell collateral to repay debt; excess goes to YB
    /// @param from The user who sells
    /// @param share Collateral YieldBox-shares to sell
    /// @param data LeverageExecutor data
    function sellCollateral(Singularity sgl, address from, uint256 share, bytes calldata data)
        external
        returns (Singularity.Module[] memory modules, bytes[] memory calls)
    {
        Singularity.Module[] memory modules = new Singularity.Module[](1);
        bytes[] memory calls = new bytes[](1);
        modules[0] = Singularity.Module.Leverage;
        calls[0] = abi.encodeWithSelector(SGLLeverage.sellCollateral.selector, from, share, data);
    }

    /// @notice view the result of a sellCollateral operation.
    function sellCollateralView(bytes calldata result) external pure returns (uint256 amountOut) {
        amountOut = abi.decode(result, (uint256));
    }

    /// @notice Lever up: Borrow more and buy collateral with it.
    /// @param from The user who buys
    /// @param borrowAmount Amount of extra asset borrowed
    /// @param supplyAmount Amount of asset supplied (down payment)
    /// @param data LeverageExecutor data
    function buyCollateral(
        Singularity sgl,
        address from,
        uint256 borrowAmount,
        uint256 supplyAmount,
        bytes calldata data
    ) external returns (Singularity.Module[] memory modules, bytes[] memory calls) {
        Singularity.Module[] memory modules = new Singularity.Module[](1);
        bytes[] memory calls = new bytes[](1);
        modules[0] = Singularity.Module.Leverage;
        calls[0] = abi.encodeWithSelector(SGLLeverage.buyCollateral.selector, from, borrowAmount, supplyAmount, data);
    }

    /// @notice view the result of a buyCollateral operation.
    function buyCollateralView(bytes calldata result) external pure returns (uint256 amountOut) {
        amountOut = abi.decode(result, (uint256));
    }

    /// @notice liquidates a position for which the collateral's value is less than the borrowed value
    /// @dev liquidation bonus is included in the computation
    /// @param user the address to liquidate
    /// @param user the address to extract from
    /// @param receiver the address which receives the output
    /// @param liquidatorReceiver the IMarketLiquidatorReceiver executor
    /// @param liquidatorReceiverData the IMarketLiquidatorReceiver executor data
    /// @param swapCollateral true/false
    function liquidateBadDebt(
        Singularity sgl,
        address user,
        address from,
        address receiver,
        IMarketLiquidatorReceiver liquidatorReceiver,
        bytes calldata liquidatorReceiverData,
        bool swapCollateral
    ) external returns (Singularity.Module[] memory modules, bytes[] memory calls) {
        Singularity.Module[] memory modules = new Singularity.Module[](1);
        bytes[] memory calls = new bytes[](1);
        modules[0] = Singularity.Module.Liquidation;
        calls[0] = abi.encodeWithSelector(
            SGLLiquidation.liquidateBadDebt.selector,
            user,
            from,
            receiver,
            liquidatorReceiver,
            liquidatorReceiverData,
            swapCollateral
        );
    }

    /// @notice Entry point for liquidations.
    /// @dev Will call `closedLiquidation()` if not LQ exists or no LQ bid avail exists. Otherwise use LQ.
    /// @param users An array of user addresses.
    /// @param maxBorrowParts A one-to-one mapping to `users`, contains maximum (partial) borrow amounts (to liquidate) of the respective user
    /// @param minLiquidationBonuses minimum liquidation bonus acceptable
    /// @param liquidatorReceivers IMarketLiquidatorReceiver array
    /// @param liquidatorReceiverDatas IMarketLiquidatorReceiver datas
    function liquidate(
        Singularity sgl,
        address[] calldata users,
        uint256[] calldata maxBorrowParts,
        uint256[] calldata minLiquidationBonuses,
        IMarketLiquidatorReceiver[] calldata liquidatorReceivers,
        bytes[] calldata liquidatorReceiverDatas
    ) external returns (Singularity.Module[] memory modules, bytes[] memory calls) {
        Singularity.Module[] memory modules = new Singularity.Module[](1);
        bytes[] memory calls = new bytes[](1);
        modules[0] = Singularity.Module.Liquidation;
        calls[0] = abi.encodeWithSelector(
            SGLLiquidation.liquidate.selector,
            users,
            maxBorrowParts,
            minLiquidationBonuses,
            liquidatorReceivers,
            liquidatorReceiverDatas
        );
    }

    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        if (_returnData.length > 1000) return "Market: reason too long";
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Market: no return data";
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}
