// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IAccrueNFT {
    
    function isApprovedOrOwner(
        address _spender,
        uint256 _tokenId
    ) external view returns (bool);

    function mint(address _to) external payable returns (uint256 tokenId);

    function burn(uint256 _tokenId) external payable;
}
