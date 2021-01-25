//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IMateriaAMMV1.sol";
import "../../../common/AMM.sol";

contract MateriaAMMV1 is IMateriaAMMV1, AMM {

    address private _materiaOrchestratorAddress;

    address private _wethAddress;

    address private immutable _factoryAddress;

    constructor(address materiaOrchestratorAddress)
        AMM(
            "MateriaAMM",
            1,
            _wethAddress = IMateriaOrchestrator(materiaOrchestratorAddress).erc20Wrapper().asInteroperable(IMateriaOrchestrator(materiaOrchestratorAddress).ETHEREUM_OBJECT_ID()),
            2,
            true
        ) {
        _factoryAddress = address(IMateriaOrchestrator(materiaOrchestratorAddress).factory());
    }

    function MateriaData() public virtual override view returns(address routerAddress, address factoryAddress, address wethAddress) {
        routerAddress = _materiaOrchestratorAddress;
        factoryAddress = _factoryAddress;
        wethAddress = _wethAddress;
    }

    function byLiquidityPool(address liquidityPoolAddress) public override view returns(uint256 liquidityPoolAmount, uint256[] memory tokensAmounts, address[] memory tokenAddresses) {
        IMateriaPair pair = IMateriaPair(liquidityPoolAddress);

        liquidityPoolAmount = pair.totalSupply();

        tokensAmounts = new uint256[](2);
        (uint256 amountA, uint256 amountB,) = pair.getReserves();
        tokensAmounts[0] = amountA;
        tokensAmounts[1] = amountB;

        tokenAddresses = new address[](2);
        tokenAddresses[0] = pair.token0();
        tokenAddresses[1] = pair.token1();
    }

    function byTokens(address[] memory tokenAddresses) public override view returns(uint256 liquidityPoolAmount, uint256[] memory tokensAmounts, address liquidityPoolAddress, address[] memory orderedTokens) {
        IMateriaPair pair = IMateriaPair(liquidityPoolAddress = IMateriaFactory(_factoryAddress).getPair(tokenAddresses[0], tokenAddresses[1]));

        if(address(pair) == address(0)) {
            return (liquidityPoolAmount, tokensAmounts, liquidityPoolAddress, orderedTokens);
        }

        liquidityPoolAmount = pair.totalSupply();

        tokensAmounts = new uint256[](2);
        (uint256 amountA, uint256 amountB,) = pair.getReserves();
        tokensAmounts[0] = amountA;
        tokensAmounts[1] = amountB;

        orderedTokens = new address[](2);
        orderedTokens[0] = pair.token0();
        orderedTokens[1] = pair.token1();
    }

    function _getLiquidityPoolOperator(address, address[] memory) internal override virtual view returns(address) {
        return _materiaOrchestratorAddress;
    }

    function _getLiquidityPoolCreator(address[] memory, uint256[] memory, bool) internal virtual view override returns(address) {
        return _materiaOrchestratorAddress;
    }

    function _createLiquidityPoolAndAddLiquidity(address[] memory tokenAddresses, uint256[] memory amounts, bool involvingETH, address, address receiver) internal virtual override returns(uint256 liquidityPoolAmount, uint256[] memory tokensAmounts, address liquidityPoolAddress, address[] memory orderedTokens) {
        tokensAmounts = new uint256[](2);
        orderedTokens = new address[](2);
        if(!involvingETH) {
            (tokensAmounts[0], tokensAmounts[1], liquidityPoolAmount) = IMateriaOrchestrator(_materiaOrchestratorAddress).addLiquidity(
                tokenAddresses[0],
                tokenAddresses[1],
                amounts[0],
                amounts[1],
                1,
                1,
                receiver,
                block.timestamp
            );
        } else {
            address token = tokenAddresses[0] != _wethAddress ? tokenAddresses[0] : tokenAddresses[1];
            uint256 amountTokenDesired = tokenAddresses[0] != _wethAddress ? amounts[0] : amounts[1];
            uint256 amountETHDesired = tokenAddresses[0] == _wethAddress ? amounts[0] : amounts[1];
            (tokensAmounts[0], tokensAmounts[1], liquidityPoolAmount) = IMateriaOrchestrator(_materiaOrchestratorAddress).addLiquidityETH {value : amountETHDesired} (
                token,
                amountTokenDesired,
                1,
                1,
                receiver,
                block.timestamp
            );
        }
        IMateriaPair pair = IMateriaPair(liquidityPoolAddress = IMateriaFactory(_factoryAddress).getPair(tokenAddresses[0], tokenAddresses[1]));
        orderedTokens[0] = pair.token0();
        orderedTokens[1] = pair.token1();
    }

    function _addLiquidity(ProcessedLiquidityPoolData memory processedLiquidityPoolData) internal override virtual returns(uint256 liquidityPoolAmount, uint256[] memory tokensAmounts) {
        tokensAmounts = new uint256[](2);
        if(!processedLiquidityPoolData.involvingETH) {
            (tokensAmounts[0], tokensAmounts[1], liquidityPoolAmount) = IMateriaOrchestrator(_materiaOrchestratorAddress).addLiquidity(
                processedLiquidityPoolData.liquidityPoolTokens[0],
                processedLiquidityPoolData.liquidityPoolTokens[1],
                processedLiquidityPoolData.tokensAmounts[0],
                processedLiquidityPoolData.tokensAmounts[1],
                1,
                1,
                processedLiquidityPoolData.receiver,
                block.timestamp
            );
        } else {
            address token = processedLiquidityPoolData.liquidityPoolTokens[0] != _wethAddress ? processedLiquidityPoolData.liquidityPoolTokens[0] : processedLiquidityPoolData.liquidityPoolTokens[1];
            uint256 amountTokenDesired = processedLiquidityPoolData.liquidityPoolTokens[0] != _wethAddress ? processedLiquidityPoolData.tokensAmounts[0] : processedLiquidityPoolData.tokensAmounts[1];
            uint256 amountETHDesired = processedLiquidityPoolData.liquidityPoolTokens[0] == _wethAddress ? processedLiquidityPoolData.tokensAmounts[0] : processedLiquidityPoolData.tokensAmounts[1];
            (tokensAmounts[0], tokensAmounts[1], liquidityPoolAmount) = IMateriaOrchestrator(_materiaOrchestratorAddress).addLiquidityETH {value : amountETHDesired} (
                token,
                amountTokenDesired,
                1,
                1,
                processedLiquidityPoolData.receiver,
                block.timestamp
            );
        }
    }

    function _removeLiquidity(ProcessedLiquidityPoolData memory processedLiquidityPoolData) internal override virtual returns(uint256 liquidityPoolAmount, uint256[] memory tokensAmounts) {
        liquidityPoolAmount = processedLiquidityPoolData.liquidityPoolAmount;

        address token = 
        tokensAmounts = new uint256[](2);
        tokensAmounts[0] = IERC20(processedLiquidityPoolData.liquidityPoolTokens[0]).balanceOf(processedLiquidityPoolData.receiver);
        tokensAmounts[1] = IERC20(processedLiquidityPoolData.liquidityPoolTokens[0]).balanceOf(processedLiquidityPoolData.receiver);
        uint256 amount1;
        if(!processedLiquidityPoolData.involvingETH) {
            IMateriaOrchestrator(_materiaOrchestratorAddress).removeLiquidity(
                processedLiquidityPoolData.liquidityPoolTokens[0],
                processedLiquidityPoolData.liquidityPoolTokens[1],
                processedLiquidityPoolData.liquidityPoolAmount,
                1,
                1,
                processedLiquidityPoolData.receiver,
                block.timestamp
            );
        } else {
            IMateriaOrchestrator(_materiaOrchestratorAddress).removeLiquidityETH(
                processedLiquidityPoolData.liquidityPoolTokens[0] != _wethAddress ? processedLiquidityPoolData.liquidityPoolTokens[0] : processedLiquidityPoolData.liquidityPoolTokens[1],
                processedLiquidityPoolData.liquidityPoolAmount,
                1,
                1,
                processedLiquidityPoolData.receiver,
                block.timestamp
            );
        }
        tokensAmounts[0] -= IERC20(processedLiquidityPoolData.liquidityPoolTokens[0]).balanceOf(processedLiquidityPoolData.receiver);
        tokensAmounts[1] -= IERC20(processedLiquidityPoolData.liquidityPoolTokens[1]).balanceOf(processedLiquidityPoolData.receiver);
    }

    function _swapLiquidity(ProcessedSwapData memory data) internal override virtual returns(uint256 outputAmount) {
        address[] memory path = new address[](data.paths.length + 1);
        path[0] = data.enterInETH ? _wethAddress : data.inputToken;
        for(uint256 i = 0; i < data.paths.length; i++) {
            path[i + 1] = data.paths[i];
        }
        if(data.exitInETH) {
            path[path.length - 1] = _wethAddress;
        }
        
        uint receiverInitialBalance = IERC20(path[path.length - 1]).balanceOf(data.receiver);
        
        if(!data.enterInETH && !data.exitInETH) {
            IMateriaOrchestrator(_materiaOrchestratorAddress).swapExactTokensForTokens(data.amount, 1, path, data.receiver, block.timestamp);
            return IERC20(path[path.length - 1]).balanceOf(data.receiver) - receiverInitialBalance;
        }
        if(data.enterInETH) {
            IMateriaOrchestrator(_materiaOrchestratorAddress).swapExactETHForTokens{value : data.amount}(1, path, data.receiver, block.timestamp);
            return IERC20(path[path.length - 1]).balanceOf(data.receiver) - receiverInitialBalance;
        }
        if(data.exitInETH) {
            IMateriaOrchestrator(_materiaOrchestratorAddress).swapExactTokensForETH(data.amount, 1, path, data.receiver, block.timestamp);
            return IERC20(path[path.length - 1]).balanceOf(data.receiver) - receiverInitialBalance;
        }
        return 0;
    }
}