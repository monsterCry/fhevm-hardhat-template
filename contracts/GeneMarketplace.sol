// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {FHE, euint128, externalEuint32} from "@fhevm/solidity/lib/FHE.sol";
import {SepoliaConfig} from "@fhevm/solidity/config/ZamaConfig.sol";

import {Property,EvolvingMonster} from "./EvolvingMonster.sol";

contract GeneMarketplace is SepoliaConfig {

    EvolvingMonster private cat;

    struct Auction {
        address owner;
        address requster;
        uint256 tokenId;
        uint256 price;
        uint8 state;
        uint256 id;
    }

    mapping (uint256=>Auction[]) auctions;

    mapping (address=>mapping (uint256=>uint256[])) offers;

    mapping (address=>mapping (uint256=>uint256[])) ownerOffers;

    uint256 index;

    constructor() {
        index = 0;
    }

    function makeCrossOverRequest(address _to,uint256 _tokenId) public payable {
        Auction memory _auc = Auction({
            owner: _to,
            requster: msg.sender,
            tokenId: _tokenId,
            price: msg.value,
            state: 0,
            id: auctions[index].length
        });
        offers[_to][index].push(auctions[index].length);
        ownerOffers[msg.sender][index].push(auctions[index].length);
        auctions[index].push(_auc);
    }

    function acceptCrossOverRequest(uint256 _acuId) public payable {
        Auction memory _auc = auctions[index][_acuId];
        auctions[index][_acuId].state = 1;
        Property[2] memory res = cat.makeCrossover(msg.sender, _auc.requster);
        cat.updateAttribute(msg.sender, res[0]);
        cat.updateAttribute(_auc.requster, res[1]);
    }

    function palyerOffers(uint256 _idx) public view returns(Auction[] memory) {
        Auction[] memory res = new Auction[](offers[msg.sender][_idx].length);
        for(uint256 i = 0; i < offers[msg.sender][_idx].length; i++) {
            res[i] = auctions[_idx][offers[msg.sender][_idx][i]];
        }
        return res;
    }

    function palyerOwnerOffers(uint256 _idx) public view returns(Auction[] memory) {
        Auction[] memory res = new Auction[](ownerOffers[msg.sender][_idx].length);
        for(uint256 i = 0; i < ownerOffers[msg.sender][_idx].length; i++) {
            res[i] = auctions[_idx][ownerOffers[msg.sender][_idx][i]];
        }
        return res;
    }

    function cancleCrossOverRequest(uint256 _acuId) public {

    }

    function nextRound() public {
        index = index + 1;
    }
}
