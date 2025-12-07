// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {FHE, euint64, externalEuint32} from "@fhevm/solidity/lib/FHE.sol";
import {ZamaEthereumConfig} from "@fhevm/solidity/config/ZamaConfig.sol";

contract EvolvGame is ZamaEthereumConfig {
    uint8 gameState;

    constructor() {}

    function setGameState(uint8 _sta) public {
        gameState = _sta;
    }

    function getGameStae() public view returns (uint8) {
        return gameState;
    }
}
