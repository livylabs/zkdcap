// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {TdxProofVerifier} from "../src/TdxProofVerifier.sol";

contract SubmitRealProofCorrectScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address verifierAddress = vm.envAddress("VERIFIER_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);

        TdxProofVerifier verifier = TdxProofVerifier(verifierAddress);
        
        // Load the journal from the binary file
        bytes memory journal = vm.readFileBinary("tdx_proof_journal.bin");
        console.log("Journal size:", journal.length, "bytes");
        
        // Load the seal from the hex file and convert it properly
        string memory sealHex = vm.readFile("tdx_proof_seal.hex");
        
        // Remove any whitespace and newlines
        bytes memory sealBytes = vm.parseBytes(string.concat("0x", sealHex));
        console.log("Seal size:", sealBytes.length, "bytes");
        
        // Extract the selector from the seal (first 4 bytes)
        bytes4 selector = bytes4(sealBytes);
        console.log("Seal selector:", vm.toString(selector));
        
        // Verify this matches expected selectors for Base Sepolia
        // From deployment.toml: 0x73c457ba is the latest Groth16 verifier
        if (selector == 0x73c457ba) {
            console.log("Using RiscZeroGroth16Verifier v3.0.0");
        } else if (selector == 0xbb001d44) {
            console.log("Using RiscZeroGroth16Verifier v2.2.0");
        } else if (selector == 0x242f9d5b) {
            console.log("Using RiscZeroSetVerifier v0.9.0");
        } else if (selector == 0x0f63ffd5) {
            console.log("Using RiscZeroSetVerifier v0.7.0");
        } else {
            console.log("Unknown selector - may not be routable");
        }
        
        bytes32 imageId = verifier.TDX_VERIFIER_IMAGE_ID();
        bytes32 journalDigest = sha256(journal);
        
        console.log("Image ID:", vm.toString(imageId));
        console.log("Journal digest:", vm.toString(journalDigest));
        console.log("");
        console.log("Submitting TDX proof verification...");
        
        try verifier.verifyTdxQuote(journal, sealBytes) {
            console.log("SUCCESS! TDX quote verification passed!");
            
            bytes32 journalHash = keccak256(journal);
            bool isVerified = verifier.isQuoteVerified(journalHash);
            console.log("Quote verified status:", isVerified);
            
            if (isVerified) {
                console.log("COMPLETE SUCCESS! TDX proof verification working end-to-end!");
                console.log("Your TDX attestation has been successfully verified on Base Sepolia!");
                
                // Get verification details
                (bytes32 storedHash, uint256 verificationTime, address submitter, bool valid) = 
                    verifier.verifiedQuotes(journalHash);
                    
                console.log("Verification details:");
                console.log("- Journal hash:", vm.toString(storedHash));
                console.log("- Verification time:", verificationTime);
                console.log("- Submitter:", submitter);
                console.log("- Valid:", valid);
            }
            
        } catch Error(string memory reason) {
            console.log("Verification failed:", reason);
            console.log("");
            console.log("Common issues:");
            console.log("1. Seal selector mismatch - check your proof was generated with correct version");
            console.log("2. Journal digest mismatch - ensure journal file is correct");
            console.log("3. Image ID mismatch - verify your guest program image ID");
            console.log("4. Verifier not activated - the specific verifier version may not be active");
            
        } catch (bytes memory lowLevelData) {
            console.log("Verification failed with low-level error");
            console.logBytes(lowLevelData);
            
            // Try to decode common error signatures
            if (lowLevelData.length >= 4) {
                bytes4 errorSig = bytes4(lowLevelData);
                if (errorSig == 0x8baa579f) { // SelectorMismatch
                    console.log("Error: SelectorMismatch - seal selector doesn't match verifier");
                } else if (errorSig == 0x09bde339) { // VerificationFailed  
                    console.log("Error: VerificationFailed - cryptographic proof verification failed");
                } else {
                    console.log("Unknown error signature:", vm.toString(errorSig));
                }
            }
        }
        
        // Also test the parsing function
        console.log("");
        console.log("Testing TDX output parsing...");
        try verifier.parseTdxOutput(journal) returns (
            uint8 version, 
            uint8 quoteVersion, 
            uint8 teeType, 
            uint8 status
        ) {
            console.log("Successfully parsed TDX output:");
            console.log("  Version:", version);
            console.log("  Quote Version:", quoteVersion);
            console.log("  TEE Type:", teeType, teeType == 0x81 ? "(TDX)" : "(Unknown)");
            console.log("  Status:", status, status == 4 ? "(Valid)" : "(Invalid)");
            
            if (teeType == 0x81 && status == 4) {
                console.log("TDX attestation data looks valid!");
            } else {
                console.log("TDX attestation data may have issues");
            }
            
        } catch Error(string memory reason) {
            console.log("Failed to parse TDX output:", reason);
        }

        vm.stopBroadcast();
    }
}
