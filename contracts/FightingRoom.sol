// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {FHE, euint64, ebool} from "@fhevm/solidity/lib/FHE.sol";
import {ZamaEthereumConfig} from "@fhevm/solidity/config/ZamaConfig.sol";

import {Property, EvolvingMonster} from "./EvolvingMonster.sol";
import {Inventory, ItemInfo} from "./Inventory.sol";
import "hardhat/console.sol";

struct FightInfo {
    uint64 score;
    uint64 win;
    uint64 total;
}

struct AttackRequest {
    address sender;
    address to;
    bool win;
    bool decrypt;
    ebool ewin;
    euint64 escore;
    uint256 reqId;
    uint256 lauchTime;
}

contract FightingRoom is ZamaEthereumConfig {
    EvolvingMonster private cat;
    Inventory private item;

    mapping(address => FightInfo) private userScore;

    mapping(address => uint256) private userAttackCount;

    mapping(uint256 => AttackRequest) private attacks;

    mapping(uint256 => uint256) userAttacks;

    mapping(address => uint256) points;

    uint256 attackIdx;

    uint256 reqId;

    event BattleComplete(address src, address dest);

    constructor(address _cat, address _item) {
        cat = EvolvingMonster(_cat);
        item = Inventory(_item);
        attackIdx = 0;
        reqId = 1;
    }

    function attack(uint256 _tokenId) public {
        address _to = cat.ownerOf(_tokenId);
        require(_to != msg.sender, "You can't Attack yourself");

        Property memory p1 = cat.getProperty(msg.sender);
        require(p1.energy > 100, "Your Energy is poor!");
        Property memory p2 = cat.getProperty(_to);
        euint64 sum1 = FHE.asEuint64(0);
        euint64 sum2 = FHE.asEuint64(0);
        for (uint8 i = 0; i < 3; i++) {
            sum1 = FHE.add(p1.attrs[i], sum1);
            sum2 = FHE.add(p2.attrs[i], sum2);
        }
        ebool win = FHE.gt(sum1, sum2);
        euint64 score = FHE.select(win, FHE.sub(sum1, sum2), FHE.asEuint64(0));

        attacks[reqId] = AttackRequest({
            sender: msg.sender,
            to: _to,
            win: false,
            decrypt: false,
            ewin: win,
            escore: score,
            reqId: reqId,
            lauchTime: block.timestamp
        });

        FHE.makePubliclyDecryptable(win);
        FHE.makePubliclyDecryptable(score);

        userAttacks[attackIdx] = reqId;
        attackIdx++;
        userAttackCount[msg.sender]++;
        userAttackCount[_to]++;

        console.log(reqId);
        cat.decreseEnergy(_to, 100);

        reqId = reqId + 1;
    }

    function attackResult(
        uint256 requestId,
        bool win,
        uint64 score,
        bytes memory publicDecryptionProof
    ) public returns (bool) {
        AttackRequest memory attackReq = attacks[requestId];
        emit BattleComplete(attackReq.to, attackReq.sender);

        bytes32[] memory ciphertextEfooEbar = new bytes32[](2);
        ciphertextEfooEbar[0] = FHE.toBytes32(attackReq.ewin);
        ciphertextEfooEbar[1] = FHE.toBytes32(attackReq.escore);

        bytes memory abiClearFooClearBar = abi.encode(win, score);
        FHE.checkSignatures(ciphertextEfooEbar, abiClearFooClearBar, publicDecryptionProof);

        attacks[requestId].decrypt = true;
        if (win) {
            userScore[attackReq.sender].score = userScore[attackReq.sender].score + score;
            userScore[attackReq.sender].win = userScore[attackReq.sender].win + 1;
            points[attackReq.sender] += 5;
            attacks[requestId].win = true;
        } else {
            userScore[attackReq.to].score = userScore[attackReq.to].score + score;
            userScore[attackReq.to].win = userScore[attackReq.to].win + 1;
            attacks[requestId].win = false;
            if (points[attackReq.sender] > 10000) {
                points[attackReq.sender] -= 5;
            } else {
                points[attackReq.sender] = 0;
            }
        }
        userScore[attackReq.sender].total = userScore[attackReq.sender].total + 1;
        userScore[attackReq.to].total = userScore[attackReq.to].total + 1;
        return true;
    }

    function getFightScore(address _target) public view returns (FightInfo memory) {
        return userScore[_target];
    }

    function loadAttacks(address _player) public view returns (AttackRequest[] memory) {
        AttackRequest[] memory rets = new AttackRequest[](userAttackCount[_player]);
        uint256 idx = 0;
        for (uint256 i = 0; i < attackIdx; i++) {
            if (attacks[userAttacks[i]].sender == _player || attacks[userAttacks[i]].to == _player) {
                rets[idx] = attacks[userAttacks[i]];
                idx++;
            }
        }
        return rets;
    }

    function extendPoint(address _to, uint256 _point) public {
        points[_to] += _point;
    }

    function getPointCount(address _to) public view returns (uint256) {
        return points[_to];
    }
}
