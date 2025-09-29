// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IRiscZeroVerifier} from "risc0-ethereum/contracts/src/IRiscZeroVerifier.sol";

/// @title TDX Quote Proof Verifier
/// @notice Verifies RISC0 proofs of TDX quote verification on Base Sepolia
/// @dev This contract verifies that a TDX quote has been properly validated in a RISC0 zkVM
contract TdxProofVerifier {
    /// @notice RISC0 verifier contract
    IRiscZeroVerifier public immutable verifier;
    
    /// @notice Image ID for the TDX quote verification program
    bytes32 public constant TDX_VERIFIER_IMAGE_ID = 0xe5056aa7a8064abeb648b31d5efa8697a79d416b937cb917d1428cec91a56c67;
    
    /// @notice Event emitted when a TDX quote is verified
    event TdxQuoteVerified(
        bytes32 indexed imageId,
        bytes32 indexed journalHash,
        address indexed submitter,
        uint256 timestamp
    );
    
    /// @notice Struct representing verified TDX quote data
    struct VerifiedTdxQuote {
        bytes32 journalHash;
        uint256 verificationTime;
        address submitter;
        bool isValid;
    }
    
    /// @notice Mapping of journal hashes to verification status
    mapping(bytes32 => VerifiedTdxQuote) public verifiedQuotes;
    
    constructor(address _verifier) {
        verifier = IRiscZeroVerifier(_verifier);
    }
    
    /// @notice Verify a TDX quote proof
    /// @param journal The journal output from the RISC0 proof (contains verification results)
    /// @param seal The seal from the RISC0 proof
    function verifyTdxQuote(
        bytes calldata journal,
        bytes calldata seal
    ) external {
        // Verify the RISC0 proof  
        verifier.verify(seal, TDX_VERIFIER_IMAGE_ID, sha256(journal));
        
        // Calculate journal hash for tracking
        bytes32 journalHash = keccak256(journal);
        
        // Store verification result
        verifiedQuotes[journalHash] = VerifiedTdxQuote({
            journalHash: journalHash,
            verificationTime: block.timestamp,
            submitter: msg.sender,
            isValid: true
        });
        
        // Emit verification event
        emit TdxQuoteVerified(
            TDX_VERIFIER_IMAGE_ID,
            journalHash,
            msg.sender,
            block.timestamp
        );
    }
    
    /// @notice Check if a TDX quote has been verified
    /// @param journalHash The hash of the journal to check
    /// @return Whether the quote has been verified
    function isQuoteVerified(bytes32 journalHash) external view returns (bool) {
        return verifiedQuotes[journalHash].isValid;
    }
    
    /// @notice Get verification details for a TDX quote
    /// @param journalHash The hash of the journal
    /// @return The verification details
    function getVerificationDetails(bytes32 journalHash) 
        external 
        view 
        returns (VerifiedTdxQuote memory) 
    {
        return verifiedQuotes[journalHash];
    }
    
    /// @notice Parse TDX verification output from journal
    /// @param journal The journal bytes
    /// @return version TDX verification version
    /// @return quoteVersion Quote version
    /// @return teeType TEE type (should be 0x81 for TDX)
    /// @return status Verification status (4 = valid)
    function parseTdxOutput(bytes calldata journal) 
        external 
        pure 
        returns (
            uint8 version,
            uint8 quoteVersion, 
            uint8 teeType,
            uint8 status
        ) 
    {
        require(journal.length >= 20, "Journal too short for TDX data");
        
        // Based on your journal structure, parse TDX fields
        // Adjust these offsets based on your actual journal format
        
        // Skip initial metadata and extract TDX verification result
        // Your journal appears to have the TDX data starting around offset 16
        version = uint8(journal[16]);      // TDX verification version
        quoteVersion = uint8(journal[17]); // Quote version  
        teeType = uint8(journal[18]);      // TEE type (0x81 for TDX)
        status = uint8(journal[19]);       // Verification status (4 = valid)
    }
}
