// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {FHE, euint128,euint64, externalEuint32,ebool} from "@fhevm/solidity/lib/FHE.sol";
import {SepoliaConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
import {ABDKMath64x64} from "abdk-libraries-solidity/ABDKMath64x64.sol";
import {ERC721URIStorage, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

struct Property {
    euint64[3] attrs;
    uint64 energy;
    string name;
    bool inited;
}

contract EvolvingMonster is SepoliaConfig, ERC721URIStorage, Ownable {

    mapping(address=>Property) cats;

    uint256 private _nextTokenId;

    int128 numPrec = ABDKMath64x64.fromInt(10000);

    address private minter;
    address private market;
    address private fight;
    
    constructor() ERC721("EvolvingMonster", "EM") Ownable(msg.sender) {
    }

    function setup(address _minter,address _market, address _fight) public onlyOwner {
        market = _market;
        fight = _fight;
        minter = _minter;
    }

    function mintMonsterEgg(string memory _name,address _to) public onlyOwner {
        if(msg.sender != minter) {
            return;
        }
        Property memory uprop = cats[_to];
        if(uprop.inited) {
            return;
        }
        for(uint i = 0; i < 3; i++) {
            cats[_to].attrs[i] = FHE.randEuint64();
            FHE.allowThis(cats[_to].attrs[i]);
            FHE.allow(cats[_to].attrs[i], _to); 
            FHE.allow(cats[_to].attrs[i], market); 
            FHE.allow(cats[_to].attrs[i], fight); 
        }

        cats[_to].energy =  random(FHE.randEuint64()) % 1001;
        cats[_to].name =  _name;
        cats[_to].inited =  true;

        uint256 tokenId = _nextTokenId++;
        _mint(_to, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked(
            "{\"name\":\"",_name,"\",\"image\":\"","url","\",\"attributes:[{\"\"energy\":",cats[_to].energy,"\"attack\":",cats[_to].attrs[0],"\"magic\":",cats[_to].attrs[1],"\"defence\":",cats[_to].attrs[2],"}"
        )));
    }

    function hatchEgg() public {
        Property memory uprop = cats[msg.sender];
        if(!uprop.inited) {
            return;
        }
        for(uint i = 0; i < 3; i++) {
            cats[msg.sender].attrs[i] = FHE.rem(uprop.attrs[i],10000);
            FHE.allowThis(cats[msg.sender].attrs[i]);
            FHE.allow(cats[msg.sender].attrs[i], msg.sender); 

            FHE.allow(cats[msg.sender].attrs[i], market); 
            FHE.allow(cats[msg.sender].attrs[i], fight); 
        }
    }

    function getProperty(address _tar) public view returns (Property memory) {
        return cats[_tar];
    }

    function random(euint64 _seed) view public returns (uint64) {
        return uint64(uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender, _seed))));
    }

    function binaryCrossover(
        euint64 parent1Gene,
        euint64 parent2Gene,
        uint64 eta
    ) internal returns (euint64, euint64) {
        euint64 seed = FHE.randEuint64(); 
        int128 beta;
        int128 num_prec = ABDKMath64x64.fromInt(10000);
        int128 u = ABDKMath64x64.fromUInt(uint128((uint64(random(seed)) % 10000)));
        int128 ui = ABDKMath64x64.div(u,num_prec);
        int128 num_tow = ABDKMath64x64.fromInt(2);
        int128 num_one = ABDKMath64x64.fromInt(1);
        int128 num_one_plus_eta = ABDKMath64x64.fromInt(int128(int64(eta) + 1));

        if (u <= 5000) {
            beta = pow(ABDKMath64x64.mul(num_tow,ui),ABDKMath64x64.inv(num_one_plus_eta));
        } else {
            int128 tmpInv = ABDKMath64x64.inv(ABDKMath64x64.mul(num_tow,ABDKMath64x64.sub(num_one,ui)));
            beta = pow(tmpInv,ABDKMath64x64.inv(num_one_plus_eta));
        }
        beta = ABDKMath64x64.mul(beta,num_prec);
        beta = ABDKMath64x64.toInt(beta);

        euint64 eonePlusBeta = FHE.asEuint64(uint64(uint128(beta + 10000)));
        euint64 eoneSubBeta = FHE.asEuint64(uint64(uint128(10000 - beta)));

        euint64 sum1 = FHE.add(FHE.mul(eonePlusBeta,parent1Gene) ,FHE.mul(eoneSubBeta,parent2Gene));
        euint64 sum2 = FHE.add(FHE.mul(eoneSubBeta,parent1Gene) ,FHE.mul(eonePlusBeta,parent2Gene));
        
        euint64 child1 = FHE.div(sum1,2 * 10000);
        euint64 child2 = FHE.div(sum2,2 * 10000);
        return (child1,child2);
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

        if(rand < 5000) {
            int128 powVal = pow(ABDKMath64x64.mul(numTow,u),inv);
            deta = ABDKMath64x64.sub(powVal,numOne);
        } else {
            int128 powVal = pow(ABDKMath64x64.mul(numTow,ABDKMath64x64.sub(numOne,u)), inv);
            deta = ABDKMath64x64.sub(numOne,powVal);
        }
        int128 mutation = ABDKMath64x64.mul(deta,ABDKMath64x64.fromUInt(upperBound - lowerBound));
        euint64 result;
        if(mutation > 0) {
            result = FHE.add(gene, FHE.asEuint64(uint64(ABDKMath64x64.toInt(mutation))));
        } else {
            result = FHE.sub(gene, FHE.asEuint64(uint64(-ABDKMath64x64.toInt(mutation))));
        }
        euint64 eup = FHE.asEuint64(upperBound);
        euint64 edown = FHE.asEuint64(lowerBound);
        ebool above = FHE.gt(result, eup);
        result = FHE.select(above,eup,result);
        above = FHE.lt(result, edown);
        result = FHE.select(above,edown,result);
        return result;
    }

    function pow(int128 x, int128 y) public pure returns (int128) {
        int128 logX = ABDKMath64x64.ln(x);
        int128 exponent = ABDKMath64x64.mul(y, logX);
        return ABDKMath64x64.exp(exponent);
    }

    function makeMutation(address _to) public onlyOwner {
        Property memory p1 = cats[_to];
        for(uint8 i = 0; i < 3; i++) {
            cats[_to].attrs[i] = polynomialMutation(p1.attrs[i],500,10000,20);
            FHE.allowThis(cats[_to].attrs[i]);
            FHE.allow(cats[_to].attrs[i], _to);

            FHE.allow(cats[_to].attrs[i], market); 
            FHE.allow(cats[_to].attrs[i], fight); 
        }
    }

    function evolveWith(address _with) public onlyOwner {
        Property memory p1 = cats[msg.sender];
        Property memory p2 = cats[_with];
        if(!p1.inited) {
            return;
        }
        if(!p2.inited) {
            return;
        }
        for(uint i = 0; i < 3; i++) {
            (euint64 attr1, euint64 attr2) = binaryCrossover(p1.attrs[i],p2.attrs[i],20);
            cats[msg.sender].attrs[i] = attr1;
            cats[_with].attrs[i] = attr2;

            FHE.allowThis(cats[msg.sender].attrs[i]);
            FHE.allow(cats[msg.sender].attrs[i], msg.sender);
            FHE.allow(cats[msg.sender].attrs[i], market); 
            FHE.allow(cats[msg.sender].attrs[i], fight); 

            FHE.allowThis(cats[_with].attrs[i]);
            FHE.allow(cats[_with].attrs[i], _with); 

            FHE.allow(cats[_with].attrs[i], market); 
            FHE.allow(cats[_with].attrs[i], fight); 
        }
    }

    function makeCrossover(address _src, address _to) public returns(Property[2] memory res)  {
        require(msg.sender == minter,'Invalid Operator');
        Property memory p1 = cats[_src];
        Property memory p2 = cats[_to];
        for(uint i = 0; i < 3; i++) {
            (euint64 attr1, euint64 attr2) = binaryCrossover(p1.attrs[i],p2.attrs[i],20);
            res[0].attrs[i] = attr1;
            res[1].attrs[i] = attr2;
        }

    }

    function updateAttribute(address _to, Property memory prop) public {
        require(msg.sender == minter,'Invalid Operator');
        for(uint8 i = 0; i < 3; i++) {
            cats[_to].attrs[i] = prop.attrs[i];
            FHE.allow(cats[_to].attrs[i], _to); 

            FHE.allow(cats[_to].attrs[i], market); 
            FHE.allow(cats[_to].attrs[i], fight); 
        }
    }

    function recoverEnergy(address _to) public onlyOwner {

    }
    
}
