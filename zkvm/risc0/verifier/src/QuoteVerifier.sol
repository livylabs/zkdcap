// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/console.sol";

/**
 * @title IRiscZeroVerifier
 * @dev Interface for RISC Zero verifier contract
 */
interface IRiscZeroVerifier {
    function verify(bytes32 imageId, bytes calldata seal, bytes calldata journal) external view returns (bool);
}

/**
 * @title QuoteVerifier
 * @dev Verifies zkVM proofs for DCAP quote verification
 */
contract QuoteVerifier {
    // RISC Zero Image ID for the DCAP quote verifier
    bytes32 public constant IMAGE_ID = 0xc700937f6407fbb924f499ade8d9b40769b25f2af00e6d82aa019deaa504273a;
    
    // RISC Zero verifier contract address on Sepolia
    address public constant RISC_ZERO_VERIFIER = 0x925d8331ddc0a1F0d96E68CF073DFE1d92b69187;
    
    event QuoteVerified(address indexed verifier, bytes32 indexed quoteHash, bool success);
    
    /**
     * @dev Verify a DCAP quote using REAL zkVM proof verification
     * @param seal The zkVM proof seal
     * @param journal The journal containing the verification result
     * @return success True if verification succeeds
     */
    function verifyQuote(bytes calldata seal, bytes calldata journal) external returns (bool success) {
        // Basic validation
        require(seal.length > 0, "Empty seal");
        require(journal.length > 0, "Empty journal");
        
        // REAL verification using RISC Zero verifier
        IRiscZeroVerifier verifier = IRiscZeroVerifier(RISC_ZERO_VERIFIER);
        success = verifier.verify(IMAGE_ID, seal, journal);
        
        bytes32 quoteHash = keccak256(journal);
        emit QuoteVerified(msg.sender, quoteHash, success);
        
        console.log("REAL verification result:", success);
        console.logBytes32(quoteHash);
        
        return success;
    }
    
    /**
     * @dev Get the image ID for this verifier
     * @return The RISC Zero image ID
     */
    function getImageId() external pure returns (bytes32) {
        return IMAGE_ID;
    }
    
    /**
     * @dev Get the RISC Zero verifier address
     * @return The RISC Zero verifier contract address
     */
    function getRiscZeroVerifier() external pure returns (address) {
        return RISC_ZERO_VERIFIER;
    }
}