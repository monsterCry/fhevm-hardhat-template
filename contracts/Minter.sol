// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {FHE, euint64, externalEuint32} from "@fhevm/solidity/lib/FHE.sol";
import {SepoliaConfig} from "@fhevm/solidity/config/ZamaConfig.sol";

import {EvolvingMonster} from './EvolvingMonster.sol';
import {GeneMarketplace} from './GeneMarketplace.sol';
import {Inventory,ItemInfo} from './Inventory.sol';

contract Minter is SepoliaConfig {
    EvolvingMonster private monster;
    Inventory private inventory;
    address private market;
    address private fight;

    constructor(address _monster, address _market,address _fight,address _inventory) {
        monster = EvolvingMonster(_monster);
        inventory = Inventory(inventory);
        market = _market;
        fight = _fight;
    }

    function mintMonsterEgg(string memory _name) public {
        monster.mintMonsterEgg(_name, msg.sender);
    }

    function gm() public {
        euint64 erand = FHE.randEuint64();
        uint64 rand = monster.random(erand) % 100000;
        if(rand < 10) {
            inventory.internalMint(msg.sender,1);
        } else if(rand >= 10 && rand < 1010) {
            inventory.internalMint(msg.sender,2);
        }
    }

    function makeMutation(uint256 _tokenId) public {
        if(inventory.ownerOf(_tokenId) != msg.sender) {
            return;
        }
        ItemInfo memory iinfo = inventory.getItemInfo(_tokenId);
        if(iinfo.itemType != 1) {
            return;
        }
        monster.makeMutation(msg.sender);
        inventory.burn(_tokenId);
    }

    function makeRecovery(uint256 _tokenId) public {
        if(inventory.ownerOf(_tokenId) != msg.sender) {
            return;
        }
        ItemInfo memory iinfo = inventory.getItemInfo(_tokenId);
        if(iinfo.itemType != 2) {
            return;
        }
        monster.recoverEnergy(msg.sender);
        inventory.burn(_tokenId);
    }
}