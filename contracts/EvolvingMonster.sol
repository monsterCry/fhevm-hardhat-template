// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {FHE, euint128, euint64, externalEuint32, ebool} from "@fhevm/solidity/lib/FHE.sol";
import {ZamaEthereumConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
import {ABDKMath64x64} from "abdk-libraries-solidity/ABDKMath64x64.sol";
import {ERC721URIStorage, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

struct Property {
    euint64[3] attrs;
    uint64 energy;
    string name;
    bool inited;
    address owner;
    uint256 id;
}

contract EvolvingMonster is ZamaEthereumConfig, ERC721URIStorage, Ownable {
    mapping(address player => uint256 id) private userMonster;

    mapping(uint256 id => Property prop) private monsters;

    uint256 private _nextTokenId;

    int128 private numPrec = ABDKMath64x64.fromInt(10000);

    address private minter;
    address private market;
    address private fight;

    event MonsterMinted(
        address indexed from,
        euint64 attack,
        euint64 magic,
        euint64 defanse,
        uint64 energy,
        string name
    );

    Property private emptyProp;

    event MutationComplete(address to);

    event CrossoverComplete(address from, address to);

    constructor() ERC721("EvolvingMonster", "EM") Ownable(msg.sender) {
        _nextTokenId = 1;
        emptyProp = Property({
            attrs: [FHE.asEuint64(0), FHE.asEuint64(0), FHE.asEuint64(0)],
            energy: 0,
            name: "-",
            inited: false,
            owner: address(0),
            id: 0
        });
    }

    function setup(address _minter, address _market, address _fight) public onlyOwner {
        market = _market;
        fight = _fight;
        minter = _minter;
    }

    function mintMonsterEgg(string memory _name, address _toAddr) public onlyOwner {
        if (msg.sender != minter) {
            return;
        }
        uint256 _to = userMonster[_toAddr];
        Property memory uprop = monsters[_to];
        if (uprop.inited) {
            return;
        }
        uint256 tokenId = _nextTokenId++;
        _to = tokenId;
        userMonster[_toAddr] = _to;
        for (uint256 i = 0; i < 3; i++) {
            euint64 tmp = FHE.randEuint64();

            monsters[_to].attrs[i] = FHE.rem(tmp, 10000);

            FHE.allowThis(monsters[_to].attrs[i]);

            FHE.allow(monsters[_to].attrs[i], _toAddr);

            FHE.allow(monsters[_to].attrs[i], market);

            FHE.allow(monsters[_to].attrs[i], fight);
        }

        monsters[_to].energy = 1000;
        monsters[_to].name = _name;
        monsters[_to].inited = true;
        monsters[_to].owner = _toAddr;
        monsters[_to].id = _to;

        _mint(_toAddr, tokenId);
        string memory url = "https://ar.4everland.io/tjGh_R8oAU-lDJhnjobeO7rMYytA55J1Hq7DgY4T_TY";
        string memory uri = string(
            abi.encodePacked(
                '{"name":"',
                _name,
                '"',
                ',"image":"',
                url,
                '"',
                ',"attributes":[{"energy":',
                Strings.toString(monsters[_to].energy),
                ',"attack":"',
                toHexString(euint64.unwrap(monsters[_to].attrs[0])),
                '","magic":"',
                toHexString(euint64.unwrap(monsters[_to].attrs[1])),
                '","defence":"',
                toHexString(euint64.unwrap(monsters[_to].attrs[2])),
                '"}]}'
            )
        );
        _setTokenURI(tokenId, uri);
        emit MonsterMinted(
            _toAddr,
            monsters[_to].attrs[0],
            monsters[_to].attrs[1],
            monsters[_to].attrs[2],
            monsters[_to].energy,
            monsters[_to].name
        );
    }

    function toHexString(bytes32 data) public pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(66); // 0x + 64个字符

        str[0] = "0";
        str[1] = "x";

        for (uint256 i = 0; i < 32; i++) {
            str[2 + i * 2] = alphabet[uint8(data[i] >> 4)];
            str[3 + i * 2] = alphabet[uint8(data[i] & 0x0f)];
        }

        return string(str);
    }

    function getProperty(address _tar) public view returns (Property memory) {
        if (userMonster[_tar] == 0) {
            return emptyProp;
        }
        return monsters[userMonster[_tar]];
    }

    function random(euint64 _seed) public view returns (uint64) {
        return uint64(uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender, _seed))));
    }

    function binaryCrossover(euint64 parent1Gene, euint64 parent2Gene, uint64 eta) internal returns (euint64, euint64) {
        euint64 seed = FHE.randEuint64();
        int128 beta;
        int128 num_prec = ABDKMath64x64.fromInt(10000);
        int128 u = ABDKMath64x64.fromUInt(uint128((uint64(random(seed)) % 10000)));
        int128 ui = ABDKMath64x64.div(u, num_prec);
        int128 num_tow = ABDKMath64x64.fromInt(2);
        int128 num_one = ABDKMath64x64.fromInt(1);
        int128 num_one_plus_eta = ABDKMath64x64.fromInt(int128(int64(eta) + 1));

        if (u <= 5000) {
            beta = pow(ABDKMath64x64.mul(num_tow, ui), ABDKMath64x64.inv(num_one_plus_eta));
        } else {
            int128 tmpInv = ABDKMath64x64.inv(ABDKMath64x64.mul(num_tow, ABDKMath64x64.sub(num_one, ui)));
            beta = pow(tmpInv, ABDKMath64x64.inv(num_one_plus_eta));
        }
        beta = ABDKMath64x64.mul(beta, num_prec);
        beta = ABDKMath64x64.toInt(beta);

        euint64 eonePlusBeta = FHE.asEuint64(uint64(uint128(beta + 10000)));
        euint64 eoneSubBeta = FHE.asEuint64(uint64(uint128(10000 - beta)));

        euint64 sum1 = FHE.add(FHE.mul(eonePlusBeta, parent1Gene), FHE.mul(eoneSubBeta, parent2Gene));
        euint64 sum2 = FHE.add(FHE.mul(eoneSubBeta, parent1Gene), FHE.mul(eonePlusBeta, parent2Gene));

        euint64 child1 = FHE.div(sum1, 2 * 10000);
        euint64 child2 = FHE.div(sum2, 2 * 10000);
        return (child1, child2);
    }

    function polynomialMutation(
        euint64 gene,
        uint64 lowerBound,
        uint64 upperBound,
        uint64 eta
    ) internal returns (euint64) {
        euint64 seed = FHE.randEuint64();
        int128 rand = ABDKMath64x64.fromUInt(uint128((uint64(random(seed)) % 10000)));
        int128 u = ABDKMath64x64.div(rand, ABDKMath64x64.fromInt(10000));
        int128 deta;
        int128 numTow = ABDKMath64x64.fromInt(2);
        int128 numOne = ABDKMath64x64.fromInt(1);
        int128 numOnePlusEta = ABDKMath64x64.fromInt(int128(int64(eta) + 1));
        int128 inv = ABDKMath64x64.inv(numOnePlusEta);

        if (rand < 5000) {
            int128 powVal = pow(ABDKMath64x64.mul(numTow, u), inv);
            deta = ABDKMath64x64.sub(powVal, numOne);
        } else {
            int128 powVal = pow(ABDKMath64x64.mul(numTow, ABDKMath64x64.sub(numOne, u)), inv);
            deta = ABDKMath64x64.sub(numOne, powVal);
        }
        int128 mutation = ABDKMath64x64.mul(deta, ABDKMath64x64.fromUInt(upperBound - lowerBound));
        euint64 result;
        if (mutation > 0) {
            result = FHE.add(gene, FHE.asEuint64(uint64(ABDKMath64x64.toInt(mutation))));
        } else {
            result = FHE.sub(gene, FHE.asEuint64(uint64(-ABDKMath64x64.toInt(mutation))));
        }
        euint64 eup = FHE.asEuint64(upperBound);
        euint64 edown = FHE.asEuint64(lowerBound);
        ebool above = FHE.gt(result, eup);
        result = FHE.select(above, eup, result);
        above = FHE.lt(result, edown);
        result = FHE.select(above, edown, result);
        return result;
    }

    function pow(int128 x, int128 y) public pure returns (int128) {
        int128 logX = ABDKMath64x64.ln(x);
        int128 exponent = ABDKMath64x64.mul(y, logX);
        return ABDKMath64x64.exp(exponent);
    }

    function makeMutation(address _toAddr) public onlyOwner {
        uint256 _to = userMonster[_toAddr];
        Property memory p1 = monsters[_to];
        for (uint8 i = 0; i < 3; i++) {
            monsters[_to].attrs[i] = polynomialMutation(p1.attrs[i], 500, 10000, 20);

            FHE.allowThis(monsters[_to].attrs[i]);
            FHE.allow(monsters[_to].attrs[i], _toAddr);
            FHE.allow(monsters[_to].attrs[i], market);
            FHE.allow(monsters[_to].attrs[i], fight);
        }
        emit MutationComplete(_toAddr);
    }

    function makeCrossover(address _srcAddr, address _toAddr) public returns (Property[2] memory res) {
        require(msg.sender == market || msg.sender == minter, "Invalid Operator");
        uint256 _to = userMonster[_toAddr];
        uint256 _src = userMonster[_srcAddr];
        Property memory p1 = monsters[_src];
        Property memory p2 = monsters[_to];
        for (uint128 i = 0; i < 3; i++) {
            (euint64 attr1, euint64 attr2) = binaryCrossover(p1.attrs[i], p2.attrs[i], 20);
            res[0].attrs[i] = attr1;
            res[1].attrs[i] = attr2;
        }
        emit CrossoverComplete(_srcAddr, _toAddr);
    }

    function updateAttribute(address _toAddr, Property memory prop) public {
        require(msg.sender == market || msg.sender == minter, "Invalid Operator");
        uint256 _to = userMonster[_toAddr];
        for (uint8 i = 0; i < 3; i++) {
            monsters[_to].attrs[i] = prop.attrs[i];

            FHE.allowThis(monsters[_to].attrs[i]);
            FHE.allow(monsters[_to].attrs[i], _toAddr);
            FHE.allow(monsters[_to].attrs[i], market);
            FHE.allow(monsters[_to].attrs[i], fight);
        }
    }

    function recoverEnergy(address _toAddr) public onlyOwner {
        uint256 _to = userMonster[_toAddr];
        monsters[_to].energy = 1000;
    }

    function decreseEnergy(address _toAddr, uint64 _val) public {
        require(msg.sender == fight, "Energy decrese must in fightroom");
        uint256 _to = userMonster[_toAddr];
        monsters[_to].energy -= _val;
    }

    function listMonsters(uint256 _start, uint256 _limit) public view returns (Property[] memory) {
        uint256 end = _limit * (_start + 1);
        uint256 pageSize = _limit;
        if (end >= _nextTokenId) {
            end = _nextTokenId;
        }
        if (_limit > _nextTokenId - 1) {
            pageSize = _nextTokenId - 1;
        }
        Property[] memory retMonsters = new Property[](pageSize);
        uint256 idx = 0;
        for (uint256 i = _start * _limit + 1; i < end; i++) {
            retMonsters[idx] = monsters[i];
            idx = idx + 1;
        }
        return (retMonsters);
    }

    function listRecentMinted(uint256 _limit) public view returns (Property[] memory) {
        uint256 end = _nextTokenId;
        uint256 start = _nextTokenId;
        if (_limit > _nextTokenId) {
            start = 1;
        } else {
            start = _nextTokenId - _limit;
        }
        if (end - start < _limit) {
            _limit = end - start;
        }
        Property[] memory retMonsters = new Property[](_limit);
        uint256 idx = 0;
        for (uint256 i = start; i < end; i++) {
            retMonsters[idx] = monsters[i];
            idx = idx + 1;
        }
        return retMonsters;
    }
}
