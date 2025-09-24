// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.19;

import {IRiscZeroVerifier} from "./IRiscZeroVerifier.sol";
import {ImageID} from "./ImageID.sol";

/// @title DCAP Quote Application using RISC Zero.
/// @notice This application verifies DCAP quotes using RISC Zero proofs.
/// @dev This contract demonstrates the proper RISC Zero pattern for verifying custom programs.
contract DCAPQuoteApp {
    /// @notice RISC Zero verifier contract address.
    IRiscZeroVerifier public immutable VERIFIER;
    /// @notice Image ID of the only zkVM binary to accept verification from.
    ///         The image ID uniquely represents the logic of our DCAP quote verifier program.
    bytes32 public constant IMAGE_ID = ImageID.DCAP_QUOTE_VERIFIER_ID;
    
    /// @notice Store verified journal digests to prevent replay attacks
    mapping(bytes32 => bool) public verifiedQuotes;
    
    /// @notice Event emitted when a DCAP quote is verified
    event DCAPQuoteVerified(address indexed verifier, bytes32 indexed journalDigest, bytes32 indexed imageId);

    /// @notice Initialize the contract, binding it to a specified RISC Zero verifier.
    constructor(IRiscZeroVerifier _verifier) {
        VERIFIER = _verifier;
    }

    /// @notice Verify a DCAP quote proof using RISC Zero verification.
    /// @param seal The Groth16 proof seal from the zkVM execution
    /// @param journal The journal bytes from the zkVM execution
    function verifyDCAPQuote(bytes calldata seal, bytes calldata journal) public {
        // Calculate journal digest
        bytes32 journalDigest = sha256(journal);
        
        // Check for replay attacks
        require(!verifiedQuotes[journalDigest], "Quote already verified");
        
        // Use the official RISC Zero verifier to verify the proof
        // This is the proper RISC Zero pattern from the template
        VERIFIER.verify(seal, IMAGE_ID, journalDigest);
        
        // Mark this quote as verified
        verifiedQuotes[journalDigest] = true;
        
        // Emit verification event
        emit DCAPQuoteVerified(address(this), journalDigest, IMAGE_ID);
    }
    
    /**
     * @dev Check if a quote has been verified
     * @param journalDigest The journal digest to check
     * @return True if verified, false otherwise
     */
    function isQuoteVerified(bytes32 journalDigest) external view returns (bool) {
        return verifiedQuotes[journalDigest];
    }
    
    /**
     * @dev Get the image ID for this application
     * @return The RISC Zero image ID
     */
    function getImageId() external pure returns (bytes32) {
        return IMAGE_ID;
    }
}
