// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract ProposalCode {

    string private _metadataLink;

    constructor(string memory metadataLink) {
        _metadataLink = metadataLink;
    }

    function getMetadataLink() public view returns(string memory) {
        return _metadataLink;
    }

    function onStart(address, address) public {
    }

    function onStop(address) public {
    }

    function callOneTime(address) public {
        ILiquidityMiningFactory({0}).updateFeePercentage({1});
    }
}

interface ILiquidityMiningFactory {
    function updateFeePercentage(uint256 newExitFee) external;
}