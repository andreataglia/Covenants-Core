//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IMateriaAMM.sol";
import "../../../common/AMM.sol";

contract MateriaAMM is IMateriaAMM, AMM {

    address private _materiaOrchestratorAddress;
    address private _iethAddress;
    address private _bridgeTokenAddress;
    address private _factoryAddress;
    address private _erc20WrapperAddress;

    constructor(address materiaOrchestratorAddress) AMM(
        "Materia",
        1,
        _iethAddress = IERC20WrapperV1(IMateriaOrchestrator(_materiaOrchestratorAddress = materiaOrchestratorAddress).erc20Wrapper()).asInteroperable(IMateriaOrchestrator(materiaOrchestratorAddress).ETHEREUM_OBJECT_ID()),
        2,
        true) {
         
        _bridgeTokenAddress = IMateriaOrchestrator(materiaOrchestratorAddress).bridgeToken();
        _factoryAddress = IMateriaOrchestrator(materiaOrchestratorAddress).factory();
        _erc20WrapperAddress = IMateriaOrchestrator(materiaOrchestratorAddress).erc20Wrapper();
    }

    function materiaData() public virtual override view returns(address orchestratorAddress, address iethAddress) {
        orchestratorAddress = _materiaOrchestratorAddress;
        iethAddress = _iethAddress;
    }

    function byLiquidityPool(address liquidityPoolAddress) public override view returns(uint256 liquidityPoolAmount, uint256[] memory tokensAmounts, address[] memory tokenAddresses) {
        IMateriaPair pair = IMateriaPair(liquidityPoolAddress);

        address token0 = pair.token0();
        address token1 = pair.token1();
        if(IMateriaFactory(_factoryAddress).getPair(token0, token1) != liquidityPoolAddress) {
            return(0, new uint256[](0), new address[](0));
        }

        liquidityPoolAmount = pair.totalSupply();

        tokensAmounts = new uint256[](2);
        (uint256 amountA, uint256 amountB,) = pair.getReserves();
        tokensAmounts[0] = amountA;
        tokensAmounts[1] = amountB;

        tokenAddresses = new address[](2);
        tokenAddresses[0] = token0;
        tokenAddresses[1] = token1;
    }

    function byTokens(address[] memory tokenAddresses) public override view returns(uint256 liquidityPoolAmount, uint256[] memory tokensAmounts, address liquidityPoolAddress, address[] memory orderedTokens) {
        require(tokenAddresses[0] == _bridgeTokenAddress || tokenAddresses[1] == _bridgeTokenAddress);
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

    function _adjustAmount(address token, uint256 amount) private view returns (uint newAmount) {
        newAmount = amount * (10**(18 - IERC20Data(token).decimals()));
    }

    function _isEthItem(address token) private view returns (bool ethItem, uint256 id) {
        try IEthItemInteroperableInterface(token).mainInterface() {
            ethItem = true;
        } catch {
            ethItem = false;
            id = IERC20WrapperV1(_erc20WrapperAddress).object(token);
        }
    }

    function getSwapOutput(address tokenAddress, uint256 tokenAmount, address[] calldata, address[] calldata path) view public virtual override returns(uint256[] memory amountsOut) {
        require(path.length == 2 || path.length == 3, 'The path must be 2 or 3 long');
        if(path.length == 2)
            require(path[0] == _bridgeTokenAddress || path[1] == _bridgeTokenAddress, 'No bridge token in path');
        else
            require(path[1] == _bridgeTokenAddress, 'No bridge token in path');
        
        address[] memory realPath = new address[](path.length + 1);
        realPath[0] = tokenAddress;
        for(uint256 i = 0; i < path.length; i++) {
            realPath[i + 1] = path[i];
        }
    
        (bool ethItemIn, uint itemId) = _isEthItem(realPath[0]);
        if (!ethItemIn && realPath[0] != _bridgeTokenAddress)
            realPath[0] = address(IERC20WrapperV1(_erc20WrapperAddress).asInteroperable(itemId));
    
        bool ethItemOut;
        (ethItemOut, itemId) = _isEthItem(realPath[1]);
        if (!ethItemOut && realPath[realPath.length - 1] != _bridgeTokenAddress)
            realPath[realPath.length - 1] = address(IERC20WrapperV1(_erc20WrapperAddress).asInteroperable(itemId));
        
        amountsOut = IMateriaOrchestrator(_materiaOrchestratorAddress).getAmountsOut(tokenAmount, realPath);
        
        if (!ethItemIn && realPath[0] != _bridgeTokenAddress)
            amountsOut[0] = _adjustAmount(tokenAddress, amountsOut[0]);
            
        if (!ethItemOut && realPath[realPath.length - 1] != _bridgeTokenAddress)
            amountsOut[amountsOut.length - 1] = _adjustAmount(path[path.length - 1], amountsOut[amountsOut.length - 1]);
    }
    
    function _getLiquidityPoolOperator(address, address[] memory) internal override virtual view returns(address) {
        return _materiaOrchestratorAddress;
    }
    
    function _getLiquidityPoolCreator(address[] memory, uint256[] memory, bool) internal virtual view override returns(address) {
        return _materiaOrchestratorAddress;
    }
    
    function _addLiquidity(address token, uint tokenAmountDesired, uint bridgeAmountDesired, address to) private returns(uint bridgeAmount, uint tokenAmount, uint liquidityPoolAmount) {
        address[] memory tokens = new address[](2);
        (tokens[0], tokens[1]) = (token, _bridgeTokenAddress);
        (,,address pair,) = byTokens(tokens);
        
        liquidityPoolAmount = IERC20(pair).balanceOf(to);
        bridgeAmount = IERC20(_bridgeTokenAddress).balanceOf(msg.sender);
        tokenAmount = IERC20(token).balanceOf(msg.sender);

        
        IMateriaOrchestrator(_materiaOrchestratorAddress).addLiquidity(
            token,
            tokenAmountDesired,
            bridgeAmountDesired,
            0,
            0,
            to,
            block.timestamp
        );
        
        liquidityPoolAmount = IERC20(pair).balanceOf(to) - liquidityPoolAmount;
        bridgeAmount -= IERC20(_bridgeTokenAddress).balanceOf(msg.sender);
        tokenAmount -= IERC20(token).balanceOf(msg.sender);
    }
    
    function _createLiquidityPoolAndAddLiquidity(address[] memory tokenAddresses, uint256[] memory amounts, bool involvingETH, address, address receiver) internal virtual override returns(uint256 liquidityPoolAmount, uint256[] memory tokensAmounts, address liquidityPoolAddress, address[] memory orderedTokens) {
/*
        tokensAmounts = new uint256[](2);
        orderedTokens = new address[](2);
        if(!involvingETH) {
            (tokensAmounts[0], tokensAmounts[1], liquidityPoolAmount) = IUniswapV2Router(_uniswapV2RouterAddress).addLiquidity(
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
            (tokensAmounts[0], tokensAmounts[1], liquidityPoolAmount) = IUniswapV2Router(_uniswapV2RouterAddress).addLiquidityETH {value : amountETHDesired} (
                token,
                amountTokenDesired,
                1,
                1,
                receiver,
                block.timestamp
            );
        }
        IUniswapV2Pair pair = IUniswapV2Pair(liquidityPoolAddress = IUniswapV2Factory(factory()).getPair(tokenAddresses[0], tokenAddresses[1]));
        orderedTokens[0] = pair.token0();
        orderedTokens[1] = pair.token1();
*/
    }
    function _addLiquidity(ProcessedLiquidityPoolData memory processedLiquidityPoolData) internal override virtual returns(uint256 liquidityPoolAmount, uint256[] memory tokensAmounts) {
/*
        tokensAmounts = new uint256[](2);
        if(!processedLiquidityPoolData.involvingETH) {
            (tokensAmounts[0], tokensAmounts[1], liquidityPoolAmount) = IUniswapV2Router(_uniswapV2RouterAddress).addLiquidity(
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
            (tokensAmounts[0], tokensAmounts[1], liquidityPoolAmount) = IUniswapV2Router(_uniswapV2RouterAddress).addLiquidityETH {value : amountETHDesired} (
                token,
                amountTokenDesired,
                1,
                1,
                processedLiquidityPoolData.receiver,
                block.timestamp
            );
        }
*/
    }

    function _removeLiquidity(ProcessedLiquidityPoolData memory processedLiquidityPoolData) internal override virtual returns(uint256 liquidityPoolAmount, uint256[] memory tokensAmounts) {
/*
        liquidityPoolAmount = processedLiquidityPoolData.liquidityPoolAmount;

        tokensAmounts = new uint256[](2);
        uint256 amount0;
        uint256 amount1;
        if(!processedLiquidityPoolData.involvingETH) {
            (amount0, amount1) = IUniswapV2Router(_uniswapV2RouterAddress).removeLiquidity(processedLiquidityPoolData.liquidityPoolTokens[0], processedLiquidityPoolData.liquidityPoolTokens[1], processedLiquidityPoolData.liquidityPoolAmount, 1, 1, processedLiquidityPoolData.receiver, block.timestamp);
        } else {
            (amount0, amount1) = IUniswapV2Router(_uniswapV2RouterAddress).removeLiquidityETH(processedLiquidityPoolData.liquidityPoolTokens[0] != _wethAddress ? processedLiquidityPoolData.liquidityPoolTokens[0] : processedLiquidityPoolData.liquidityPoolTokens[1], processedLiquidityPoolData.liquidityPoolAmount, 1, 1, processedLiquidityPoolData.receiver, block.timestamp);
        }
        tokensAmounts[0] = amount0;
        tokensAmounts[1] = amount1;
*/
    }

    function _swapLiquidity(ProcessedSwapData memory data) internal override virtual returns(uint256 outputAmount) {
/*
        address[] memory path = new address[](data.path.length + 1);
        path[0] = data.enterInETH ? _wethAddress : data.inputToken;
        for(uint256 i = 0; i < data.path.length; i++) {
            path[i + 1] = data.path[i];
        }
        if(data.exitInETH) {
            path[path.length - 1] = _wethAddress;
        }
        if(!data.enterInETH && !data.exitInETH) {
            return IUniswapV2Router(_uniswapV2RouterAddress).swapExactTokensForTokens(data.amount, 1, path, data.receiver, block.timestamp)[path.length - 1];
        }
        if(data.enterInETH) {
            return IUniswapV2Router(_uniswapV2RouterAddress).swapExactETHForTokens{value : data.amount}(1, path, data.receiver, block.timestamp)[path.length - 1];
        }
        if(data.exitInETH) {
            return IUniswapV2Router(_uniswapV2RouterAddress).swapExactTokensForETH(data.amount, 1, path, data.receiver, block.timestamp)[path.length - 1];
        }
        return 0;
*/
    }
}