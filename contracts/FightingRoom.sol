// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {FHE, euint64, ebool} from "@fhevm/solidity/lib/FHE.sol";
import {SepoliaConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
import {Property,EvolvingMonster} from "./EvolvingMonster.sol";
import {Inventory,ItemInfo} from "./Inventory.sol";

struct FightInfo {
    uint64 score;
    uint64 win;
    uint64 total;
}

struct AttackRequest {
    address sender;
    address to;
    bool decrypt;
}

contract FightingRoom is SepoliaConfig {

    EvolvingMonster private cat;
    Inventory private item;

    mapping(address=>FightInfo) userScore;
    mapping(uint256=>AttackRequest) attacks;


    constructor(address _cat,address _item) {
        cat = EvolvingMonster(_cat);
        item = Inventory(_item);
    }

    function attack(address _to) public {
        Property memory p1 = cat.getProperty(msg.sender);
        Property memory p2 = cat.getProperty(_to);
        euint64 sum1 = FHE.asEuint64(0);
        euint64 sum2 = FHE.asEuint64(0);
        for(uint8 i = 0; i < 3; i++) {
            sum1 = FHE.add(p1.attrs[i],sum1);
            sum2 = FHE.add(p2.attrs[i],sum2);
        }
        ebool win = FHE.gt(sum1, sum2);
        euint64 score = FHE.select(win, FHE.sub(sum1,sum2),FHE.asEuint64(0));
        bytes32[] memory cts = new bytes32[](4);
        cts[0] = FHE.toBytes32(win);
        cts[1] = FHE.toBytes32(score);
        uint256 reqId = FHE.requestDecryption(cts, this.attackResult.selector);
        attacks[reqId] = AttackRequest({
            sender: msg.sender,
            to: _to,
            decrypt: false
        });
    }

    function attackResult(uint256 requestId, bytes memory cleartexts, bytes memory decryptionProof) public {
        require(!attacks[requestId].decrypt, "Invalid requestId");
        FHE.checkSignatures(requestId, cleartexts, decryptionProof);
        AttackRequest memory attackReq = attacks[requestId];
        (bool win,uint64 score) = abi.decode(cleartexts, (bool,uint64));
        if(win) {
            userScore[attackReq.sender].score = userScore[attackReq.sender].score + score;
            userScore[attackReq.sender].win = userScore[attackReq.sender].win + 1;
        } else {
            userScore[attackReq.to].score = userScore[attackReq.to].score + score;
            userScore[attackReq.to].win = userScore[attackReq.to].win + 1;
        }
        userScore[attackReq.sender].total = userScore[attackReq.sender].total + 1;
        userScore[attackReq.to].total = userScore[attackReq.to].total + 1;
    }
}