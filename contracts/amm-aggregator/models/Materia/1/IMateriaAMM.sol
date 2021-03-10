//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "../../../common/IAMM.sol";
import "../../../util/IERC20.sol";
interface IMateriaAMM is IAMM {
    function materiaData() external view returns(address orchestratorAddress, address iethAddress);
}


interface IERC20WrapperV1 {
    function asInteroperable(uint itemId) external view returns (address);
    function object(address erc20TokenAddress) external view returns (uint256 objectId);
}

interface IEthItemInteroperableInterface {
    function mainInterface() external view returns (address);
}


interface IERC20Data {
    function decimals() external view returns (uint256);
}

interface IMateriaOrchestrator {
    function bridgeToken() external view returns (address);
    function erc20Wrapper() external view returns (address);
    function factory() external view returns (address);
    function erc20TokenAddress() external view returns (address);
    function ETHEREUM_OBJECT_ID() external view returns(uint);
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    function isEthItem(address token) external view returns (address collection, bool ethItem, uint itemId);
    function addLiquidity(address token, uint tokenAmountDesired, uint bridgeAmountDesired, uint tokenAmountMin, uint bridgeAmountMin, address to, uint deadline) external;
}

interface IMateriaPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function totalSupply() external view returns (uint);
}

interface IMateriaFactory {
    function getPair(address token0, address token1) external view returns (address);
}