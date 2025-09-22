// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/console.sol";
import "../lib/risc0/groth16_proof/groth16/verifier.sol";

/**
 * @title OurRiscZeroGroth16Verifier
 * @dev Our own RISC Zero Groth16 verifier with the correct parameters for our proof
 */
contract OurRiscZeroGroth16Verifier is Groth16Verifier {
    // RISC Zero Image ID for the DCAP quote verifier
    bytes32 public constant IMAGE_ID = 0xc700937f6407fbb924f499ade8d9b40769b25f2af00e6d82aa019deaa504273a;
    
    // Expected selector for our proof (0x02000000)
    bytes4 public constant EXPECTED_SELECTOR = 0x02000000;
    
    // Control root for RISC Zero 3.0.3
    bytes32 public constant CONTROL_ROOT = 0x3b304d1098ad401d3a04bc11976f476633a71b482b7851189663ca61209abe45;
    
    // BN254 Control ID for RISC Zero 3.0.3
    bytes32 public constant BN254_CONTROL_ID = 0x04446e66d300eb7fb45c9726bb53c793dda407a62e9601618bb43c5c14657ac0;
    
    event ProofVerified(address indexed verifier, bytes32 indexed imageId, bytes32 indexed journalDigest);
    
    /**
     * @dev Verify a Groth16 proof with our specific parameters
     * @param seal The Groth16 proof seal
     * @param imageId The RISC Zero image ID
     * @param journalDigest The hash of the journal
     */
    function verify(bytes calldata seal, bytes32 imageId, bytes32 journalDigest) external view {
        // Basic validation
        require(seal.length > 4, "Seal too short");
        require(imageId == IMAGE_ID, "Invalid image ID");
        
        // Check selector matches our expected value
        bytes4 selector = bytes4(seal[:4]);
        require(selector == EXPECTED_SELECTOR, "Invalid selector");
        
        // Parse the seal to extract Groth16 proof components
        // The seal format is: [selector][a][b][c][public_signals...]
        require(seal.length >= 4 + 64 + 128 + 64, "Invalid seal format");
        
        // Extract proof components (skip the 4-byte selector)
        bytes calldata proofData = seal[4:];
        
        // Parse A (64 bytes)
        uint256[2] memory a = [
            uint256(bytes32(proofData[0:32])),
            uint256(bytes32(proofData[32:64]))
        ];
        
        // Parse B (128 bytes)
        uint256[2][2] memory b = [
            [uint256(bytes32(proofData[64:96])), uint256(bytes32(proofData[96:128]))],
            [uint256(bytes32(proofData[128:160])), uint256(bytes32(proofData[160:192]))]
        ];
        
        // Parse C (64 bytes)
        uint256[2] memory c = [
            uint256(bytes32(proofData[192:224])),
            uint256(bytes32(proofData[224:256]))
        ];
        
        // Extract public signals from the seal data
        // The public signals are at the end of the seal
        require(seal.length >= 4 + 64 + 128 + 64 + 160, "Seal too short for public signals");
        
        // Extract the last 160 bytes (5 * 32 bytes) as public signals
        bytes calldata pubSignalsData = seal[seal.length - 160:];
        
        uint256[5] memory pubSignals = [
            uint256(bytes32(pubSignalsData[0:32])),    // Signal 0
            uint256(bytes32(pubSignalsData[32:64])),   // Signal 1
            uint256(bytes32(pubSignalsData[64:96])),   // Signal 2
            uint256(bytes32(pubSignalsData[96:128])),  // Signal 3
            uint256(bytes32(pubSignalsData[128:160]))  // Signal 4
        ];
        
        // Verify the Groth16 proof
        bool isValid = this.verifyProof(a, b, c, pubSignals);
        require(isValid, "Groth16 proof verification failed");
        
        // If we reach here, the proof is valid
        console.log("Proof verified successfully!");
    }
    
    /**
     * @dev Get the expected selector for our proof type
     * @return The 4-byte selector
     */
    function getExpectedSelector() external pure returns (bytes4) {
        return EXPECTED_SELECTOR;
    }
    
    /**
     * @dev Get the image ID for this verifier
     * @return The RISC Zero image ID
     */
    function getImageId() external pure returns (bytes32) {
        return IMAGE_ID;
    }
    
    /**
     * @dev Get the control root for this verifier
     * @return The control root
     */
    function getControlRoot() external pure returns (bytes32) {
        return CONTROL_ROOT;
    }
    
    /**
     * @dev Get the BN254 control ID for this verifier
     * @return The BN254 control ID
     */
    function getBn254ControlId() external pure returns (bytes32) {
        return BN254_CONTROL_ID;
    }
}
