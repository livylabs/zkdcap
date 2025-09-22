// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "forge-std/console.sol";

// Interface for RISC Zero Verifier Router
interface IRiscZeroVerifierRouter {
    function verify(bytes calldata receipt) external view;
}

// Interface for RISC Zero Groth16 Verifier
interface IRiscZeroGroth16Verifier {
    function verify(bytes calldata seal, bytes32 imageId, bytes32 journalDigest) external view;
    function verifyIntegrity(bytes calldata receipt) external view;
}

/**
 * @title VerifyOnChain
 * @dev Script to verify a real zkVM proof on-chain using the deployed QuoteVerifier
 */
contract VerifyOnChain is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== ON-CHAIN VERIFICATION ===");
        console.log("Account:", deployer);
        console.log("Balance:", deployer.balance);
        
        // Deployed RISC Zero Verifier Router on Ethereum Sepolia
        address routerAddress = 0x925d8331ddc0a1F0d96E68CF073DFE1d92b69187;
        IRiscZeroVerifierRouter router = IRiscZeroVerifierRouter(routerAddress);
        
        // Also try the direct Groth16 verifier
        address groth16VerifierAddress = 0x2a098988600d87650Fb061FfAff08B97149Fa84D;
        IRiscZeroGroth16Verifier groth16Verifier = IRiscZeroGroth16Verifier(groth16VerifierAddress);
        
        console.log("Router Contract:", routerAddress);
        console.log("Groth16 Verifier Contract:", groth16VerifierAddress);
        
        // RISC Zero Image ID for the DCAP quote verifier
        bytes32 imageId = 0xc700937f6407fbb924f499ade8d9b40769b25f2af00e6d82aa019deaa504273a;
        console.log("Image ID:", vm.toString(imageId));
        
        // Read the hex data from files
        console.log("Reading proof data...");
        
        // Read Succinct compressed seal data
        string memory sealHex = vm.readFile("data/seal_compressed_hex.txt");
        console.log("Succinct seal data length:", bytes(sealHex).length);
        
        // Read Succinct compressed journal data  
        string memory journalHex = vm.readFile("data/journal_compressed_hex.txt");
        console.log("Succinct journal data length:", bytes(journalHex).length);
        
        // Convert hex strings to bytes
        bytes memory sealBytes = vm.parseBytes(sealHex);
        bytes memory journalBytes = vm.parseBytes(journalHex);
        
        // We'll use the individual Groth16 components for verification
        
        console.log("Seal bytes length:", sealBytes.length);
        console.log("Journal bytes length:", journalBytes.length);
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("Executing on-chain verification...");
        
        // Calculate journal digest (hash of the journal)
        bytes32 journalDigest = keccak256(journalBytes);
        console.log("Journal digest:", vm.toString(journalDigest));
        
        // Try verification using the RISC Zero Verifier Router first
        console.log("Trying verification with RISC Zero Verifier Router...");
        try router.verify(sealBytes) {
            console.log("=== VERIFICATION RESULT ===");
            console.log("PROOF VERIFIED ON-CHAIN WITH ROUTER!");
            console.log("Your Groth16 zkVM proof is cryptographically valid!");
            console.log("Proof size:", sealBytes.length, "bytes");
            console.log("Journal size:", journalBytes.length, "bytes");
        } catch Error(string memory reason) {
            console.log("Router verification failed:", reason);
            
            // Fallback to direct Groth16 verifier
            console.log("Trying direct Groth16 verifier...");
            try groth16Verifier.verify(sealBytes, imageId, journalDigest) {
                console.log("=== VERIFICATION RESULT ===");
                console.log("PROOF VERIFIED ON-CHAIN WITH GROTH16 VERIFIER!");
                console.log("Your Groth16 zkVM proof is cryptographically valid!");
                console.log("Proof size:", sealBytes.length, "bytes");
                console.log("Journal size:", journalBytes.length, "bytes");
            } catch Error(string memory reason2) {
                console.log("=== VERIFICATION FAILED ===");
                console.log("Router error:", reason);
                console.log("Groth16 verifier error:", reason2);
            } catch (bytes memory lowLevelData) {
                console.log("=== VERIFICATION FAILED ===");
                console.log("Verification failed with low-level error");
                console.log("Error data length:", lowLevelData.length);
                if (lowLevelData.length > 0) {
                    console.log("Error data (first 32 bytes):", vm.toString(lowLevelData));
                }
            }
        } catch (bytes memory lowLevelData) {
            console.log("Router failed with low-level error, trying direct verifier...");
            try groth16Verifier.verify(sealBytes, imageId, journalDigest) {
                console.log("=== VERIFICATION RESULT ===");
                console.log("PROOF VERIFIED ON-CHAIN WITH GROTH16 VERIFIER!");
                console.log("Your Groth16 zkVM proof is cryptographically valid!");
                console.log("Proof size:", sealBytes.length, "bytes");
                console.log("Journal size:", journalBytes.length, "bytes");
            } catch Error(string memory reason) {
                console.log("=== VERIFICATION FAILED ===");
                console.log("Groth16 verifier error:", reason);
            } catch (bytes memory lowLevelData2) {
                console.log("=== VERIFICATION FAILED ===");
                console.log("Both verifiers failed with low-level errors");
                console.log("Router error data length:", lowLevelData.length);
                console.log("Groth16 error data length:", lowLevelData2.length);
            }
        }
        
        vm.stopBroadcast();
    }
}
