// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./LiquidCanto.sol";

contract AccrueNFT is ERC721, ERC721Enumerable, Ownable {
    LiquidCanto public liquidCanto;
    uint256 public nextTokenId;

    modifier onlyLiquidCanto() {
        require(
            msg.sender == address(liquidCanto),
            "Caller is not LiquidCanto"
        );
        _;
    }

    constructor(address _liquidCantoAddr) ERC721("Accrue NFT", "ACNFT") {
        require(
            address(_liquidCantoAddr) != address(0),
            "LiquidCanto address can not be zero"
        );
        liquidCanto = LiquidCanto(_liquidCantoAddr);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function mint(
        address _to
    ) external payable onlyLiquidCanto returns (uint256 tokenId) {
        tokenId = nextTokenId;
        nextTokenId++;
        _safeMint(_to, tokenId);
    }

    function burn(uint256 _tokenId) external payable onlyLiquidCanto {
        _burn(_tokenId);
    }

    // Todo
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {}

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function isApprovedOrOwner(
        address _spender,
        uint256 _tokenId
    ) external view virtual returns (bool) {
        return _isApprovedOrOwner(_spender, _tokenId);
    }
}
