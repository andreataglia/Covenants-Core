//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

struct FarmingPositionRequest {
    uint256 setupIndex; // index of the chosen setup.
    uint256 amount; // amount of main token or liquidity pool token.
    bool amountIsLiquidityPool; //true if user wants to directly share the liquidity pool token amount, false to add liquidity to AMM
    address positionOwner; // position extension or address(0) [msg.sender].
}

struct FarmingSetupConfiguration {
    bool add; // true if we're adding a new setup, false we're updating it.
    bool disable;
    uint256 index; // index of the setup we're updating.
    FarmingSetupInfo info; // data of the new or updated setup
}

struct FarmingSetupInfo {
    uint256 blockDuration; // duration of setup
    uint256 startBlock; // optional start block used for the delayed activation of the first setup
    uint256 originalRewardPerBlock;
    uint256 minStakeable; // minimum amount of staking tokens.
    uint256 renewTimes; // if the setup is renewable or if it's one time.
    address ammPlugin; // amm plugin address used for this setup (eg. uniswap amm plugin address).
    address liquidityPoolTokenAddress; // address of the liquidity pool token
    address mainTokenAddress; // eg. buidl address.
    address ethereumAddress; // amm ethereum address.
    bool involvingETH; // if the setup involves ETH or not.
    uint256 setupsCount; // number of setups created by this info.
    uint256 lastSetupIndex; // index of last setup;
    uint8 generation; // setup generation. Currently available on gen 1 and 2.
    // TODO: extra info needed by the NFT
}

struct FarmingSetup {
    uint256 infoIndex; // setup info
    bool active; // if the setup is active or not.
    uint256 startBlock; // farming setup start block.
    uint256 endBlock; // farming setup end block.
    uint256 lastUpdateBlock; // number of the block where an update was triggered.
    uint256 rewardPerBlock; // farming setup reward per single block.
    uint256 totalSupply; // If free it's the LP amount, if locked is currentlyStaked.
}

struct FarmingPosition {
    address uniqueOwner; // address representing the owner of the position.
    uint256 setupIndex; // the setup index related to this position.
    uint256 creationBlock; // block when this position was created.
    uint256 liquidityPoolTokenAmount; // amount of liquidity pool token in the position.
    uint256 mainTokenAmount; // amount of main token in the position (used only if free is false).
    uint256 reward; // position reward.
}