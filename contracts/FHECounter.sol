// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {FHE, euint32, externalEuint32} from "@fhevm/solidity/lib/FHE.sol";
import {SepoliaConfig} from "@fhevm/solidity/config/ZamaConfig.sol";

/// @title A simple FHE counter contract
/// @author fhevm-hardhat-template
/// @notice A very basic example contract showing how to work with encrypted data using FHEVM.
contract FHECounter is SepoliaConfig {
    euint32 private _count;
    euint32 private _rand;

    euint32 private _div;

    euint32[5] private testArr;

    constructor() {
        //FHE.setDecryptionOracle(0xa02Cda4Ca3a71D7C46997716F4283aa851C28812);

        _count = FHE.asEuint32(0);
        FHE.allowThis(_count);
        FHE.allow(_count, msg.sender);

        _div = FHE.asEuint32(32);
        FHE.allowThis(_div);
        FHE.allow(_div, msg.sender);
    }

    /// @notice Returns the current count
    /// @return The current encrypted count
    function getCount() external view returns (euint32) {
        return _count;
    }

    function getDiv() external view returns (euint32) {
        return _div;
    }

    /// @notice Increments the counter by a specified encrypted value.
    /// @param inputEuint32 the encrypted input value
    /// @param inputProof the input proof
    /// @dev This example omits overflow/underflow checks for simplicity and readability.
    /// In a production contract, proper range checks should be implemented.
    function increment(externalEuint32 inputEuint32, bytes calldata inputProof) external {
        euint32 encryptedEuint32 = FHE.fromExternal(inputEuint32, inputProof);

        _count = FHE.add(_count, encryptedEuint32);

        
        _rand = FHE.randEuint32(100);
        FHE.allowThis(_rand);

        FHE.allowThis(_count);
        FHE.allow(_count, msg.sender);
    }

    /// @notice Decrements the counter by a specified encrypted value.
    /// @param inputEuint32 the encrypted input value
    /// @param inputProof the input proof
    /// @dev This example omits overflow/underflow checks for simplicity and readability.
    /// In a production contract, proper range checks should be implemented.
    function decrement(externalEuint32 inputEuint32, bytes calldata inputProof) external {
        euint32 encryptedEuint32 = FHE.fromExternal(inputEuint32, inputProof);

        _count = FHE.sub(_count, encryptedEuint32);

        FHE.allowThis(_count);
        FHE.allow(_count, msg.sender);
    }

    function divTest() external {
        _div = FHE.div(_div,4);
        FHE.allowThis(_div);
        FHE.allow(_div, msg.sender);
    }

    function initParameters(externalEuint32[5] memory _input, bytes calldata inputProof) public {
        for(uint8 i = 0; i < 5; i++) {
            testArr[i] = FHE.fromExternal(_input[i], inputProof);//FHE.asEuint32(_input[i], inputProof);
            FHE.allowThis(testArr[i]);
            FHE.allow(testArr[i], msg.sender);
        }
    }

    function getParameters() public view returns(euint32[5] memory) {
        return testArr;
    }

}
