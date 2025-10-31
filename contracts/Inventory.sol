// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {FHE, euint128, externalEuint32} from "@fhevm/solidity/lib/FHE.sol";
import {SepoliaConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
import {ERC721URIStorage, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

struct ItemInfo {
    uint8 itemType;
}


contract Inventory is ERC721URIStorage,SepoliaConfig,Ownable {
    uint256 private _nextTokenId;
    mapping(uint256=>ItemInfo) _itemsInfo;

    constructor() ERC721("Evol Inventory", "Inventory") Ownable(msg.sender) {
        
    }

    function internalMint(address player,uint8 itemType) public {
        uint256 tokenId = _nextTokenId++;
        _mint(player, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked("{\"type\":",itemType,"\"image\":\"","12233","\"}")));
        _itemsInfo[tokenId] = ItemInfo({
            itemType:itemType
        });
    }

    function getItemInfo(uint256 _tokenId) public view returns(ItemInfo memory) {
        return _itemsInfo[_tokenId];
    }

    function burn(uint256 _tokenId) public {
        _burn(_tokenId);
    }
}