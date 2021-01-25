//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "../../../common/IAMM.sol";
import "../../../util/IERC20.sol";

interface IMateriaAMMV1 is IAMM {
    function MateriaData() external returns(address routerAddress, address factoryAddress, address wethAddress);
}


interface IMateriaOrchestrator  {
    function factory() external returns(IMateriaFactory);
    function bridgeToken() external returns(IERC20);
    function erc20Wrapper() external returns(IERC20WrapperV1);
    function ETHEREUM_OBJECT_ID() external returns(uint);
    
    //Liquidity adding
    
    function addLiquidity(
        address token,
        uint tokenAmountDesired,
        uint bridgeAmountDesired,
        uint tokenAmountMin,
        uint bridgeAmountMin,
        address to,
        uint deadline
    ) external;
    
    function addLiquidityETH(
        uint bridgeAmountDesired,
        uint EthAmountMin,
        uint bridgeAmountMin,
        address to,
        uint deadline
    ) external payable;
    
    //Liquidity removing
    
     function removeLiquidity(
        address token,
        uint liquidity,
        uint tokenAmountMin,
        uint bridgeAmountMin,
        address to,
        uint deadline
    ) external;
    
    function removeLiquidityETH(
        uint liquidity,
        uint bridgeAmountMin,
        uint EthAmountMin,
        address to,
        uint deadline
    ) external;
    
    //Swapping
    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address to,
        uint deadline
    ) external;
    
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] memory path,
        address to,
        uint deadline
    ) external payable;
    
    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address to,
        uint deadline
    ) external;
    
}

interface IMateriaFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IMateriaPair is IERC20 {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IERC20WrapperV1 {
    function asInteroperable(uint256 objectId) external view returns (address);
}