// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "forge-std/console.sol";

// RISC Zero Groth16 Verifier interface (correct signature)
interface IRiscZeroGroth16Verifier {
    function verify(
        bytes calldata seal,
        bytes32 imageId,
        bytes32 journalDigest
    ) external view;
}

contract VerifyGroth16Proof is Script {
    // RISC Zero Groth16 Verifier on Sepolia
    address constant RISC_ZERO_GROTH16_VERIFIER = 0x2a098988600d87650Fb061FfAff08B97149Fa84D;
    
    // Your DCAP Quote Verifier Image ID (from your Rust code)
    bytes32 constant DCAP_QUOTE_VERIFIER_ID = 0xc700937f6407fbb924f499ade8d9b40769b25f2af00e6d82aa019deaa504273a;
    
    function run() external view {
        console.log("=== VERIFYING GROTH16 PROOF ON SEPOLIA ===");
        console.log("Verifier Contract:", RISC_ZERO_GROTH16_VERIFIER);
        console.log("Image ID:", vm.toString(DCAP_QUOTE_VERIFIER_ID));
        
        // Read the proof data from files
        string memory sealHex = vm.readFile("./groth16_seal_hex.txt");
        string memory journalHex = vm.readFile("./groth16_journal_hex.txt");
        
        console.log("Seal hex length:", bytes(sealHex).length);
        console.log("Journal hex length:", bytes(journalHex).length);
        
        // Convert hex strings to bytes
        bytes memory seal = vm.parseBytes(sealHex);
        bytes memory journal = vm.parseBytes(journalHex);
        
        console.log("Seal bytes length:", seal.length);
        console.log("Journal bytes length:", journal.length);
        
        // For RISC Zero, we need to use the journal data directly, not its hash
        // The journal contains the public inputs/outputs from the zkVM execution
        // We need to extract the journal digest from the journal data
        
        // The journal should contain the claim data including imageId and journalDigest
        // Let's try to verify with the journal data as-is first
        
        // Call the verifier contract
        IRiscZeroGroth16Verifier verifier = IRiscZeroGroth16Verifier(RISC_ZERO_GROTH16_VERIFIER);
        
        // Try different approaches to get the journal digest
        bytes32 journalDigest;
        
        // Approach 1: Use keccak256 of journal data
        journalDigest = keccak256(journal);
        console.log("Journal digest (keccak256):", vm.toString(journalDigest));
        
        try verifier.verify(seal, DCAP_QUOTE_VERIFIER_ID, journalDigest) {
           // console.log("PROOF VERIFICATION SUCCESSFUL!");
            console.log("The Groth16 proof is valid on-chain.");
            return;
        } catch Error(string memory reason) {
            console.log("VERIFICATION ERROR (keccak256):");
            console.log(reason);
        } catch (bytes memory lowLevelData) {
            console.log("LOW-LEVEL ERROR (keccak256):");
            console.logBytes(lowLevelData);
        }
        
        // Approach 2: Try with the journal data as bytes32 (if it's exactly 32 bytes)
        if (journal.length == 32) {
            journalDigest = bytes32(journal);
            console.log("Journal digest (direct):", vm.toString(journalDigest));
            
            try verifier.verify(seal, DCAP_QUOTE_VERIFIER_ID, journalDigest) {
                console.log("PROOF VERIFICATION SUCCESSFUL!");
                console.log("The Groth16 proof is valid on-chain.");
                return;
            } catch Error(string memory reason) {
                console.log("VERIFICATION ERROR (direct):");
                console.log(reason);
            } catch (bytes memory lowLevelData) {
                console.log("LOW-LEVEL ERROR (direct):");
                console.logBytes(lowLevelData);
            }
        }
        
        console.log("All verification attempts failed.");
        console.log("Please check the journal data format and try again.");
    }
}
