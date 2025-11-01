// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {FHE, euint128, externalEuint32} from "@fhevm/solidity/lib/FHE.sol";
import {SepoliaConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
import {ERC721URIStorage, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

struct ItemInfo {
    uint16 itemType;
}

contract Inventory is ERC721URIStorage, SepoliaConfig, Ownable {
    uint256 private _nextTokenId;

    mapping(uint256 id => ItemInfo info) private _itemsInfo;

    mapping(address user => mapping(uint16 => uint16)) private typeBalance;

    constructor() ERC721("Evol Inventory", "Inventory") Ownable(msg.sender) {}

    event InventoryBurned(uint256 tokenId);

    event InventoryMinted(address indexed player, uint256 tokenId, uint16 itemType);

    function internalMint(address player, uint16 itemType) public {
        uint256 tokenId = _nextTokenId++;
        _mint(player, tokenId);
        string memory url = "";
        string memory name = "";
        if (itemType == 1) {
            name = "Mutaion";
            url = "https://ipfs.io/ipfs/bafkreiar3cnbumzr6gzbomxbmmt5htv4dgqaz6c4lgm3rxem5m5htuywke";
        } else if (itemType == 2) {
            name = "Recovery";
            url = "https://ipfs.io/ipfs/bafkreiao6g4jvqxjjwwuof32svbekiutulgv3ynrfbeochmlqodqcfhnfi";
        }
        _itemsInfo[tokenId] = ItemInfo({itemType: itemType});
        typeBalance[player][itemType] = typeBalance[player][itemType] + 1;
        string memory uri = string(
            abi.encodePacked(
                '{"name":"',
                name,
                '",',
                '"image":"',
                url,
                '"',
                ',"attributes":[{"type":',
                Strings.toString(itemType),
                "}]}"
            )
        );
        _setTokenURI(tokenId, uri);
        emit InventoryMinted(player, tokenId, itemType);
    }

    function getItemInfo(uint256 _tokenId) public view returns (ItemInfo memory) {
        return _itemsInfo[_tokenId];
    }

    function burn(uint256 _tokenId) public {
        _burn(_tokenId);
        emit InventoryBurned(_tokenId);
    }

    function balanceOfType(address _sender, uint16 _type) public view returns (uint16) {
        return typeBalance[_sender][_type];
    }
}
