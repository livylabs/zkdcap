// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/OurRiscZeroGroth16Verifier.sol";

/**
 * @title VerifyWithOurVerifier
 * @dev Script to verify our Groth16 proof using our deployed verifier
 */
contract VerifyWithOurVerifier is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== VERIFYING WITH OUR RISC ZERO GROTH16 VERIFIER ===");
        console.log("Account:", deployer);
        console.log("Balance:", deployer.balance);
        
        // Our deployed verifier address
        address verifierAddress = 0x2133D0F5a37cACf6640f523078266F51624Dd9B3;
        
        OurRiscZeroGroth16Verifier verifier = OurRiscZeroGroth16Verifier(verifierAddress);
        
        console.log("Verifier Contract:", verifierAddress);
        console.log("Image ID:", vm.toString(verifier.IMAGE_ID()));
        console.log("Expected Selector:", vm.toString(verifier.EXPECTED_SELECTOR()));
        
        // Read the hex data from files
        console.log("Reading proof data...");
        
        // Read Groth16 compressed seal data
        string memory sealHex = vm.readFile("data/seal_compressed_hexgroth.txt");
        console.log("Groth16 seal data length:", bytes(sealHex).length);
        
        // Read Groth16 compressed journal data  
        string memory journalHex = vm.readFile("data/journal_compressed_hexgroth.txt");
        console.log("Groth16 journal data length:", bytes(journalHex).length);
        
        // Convert hex strings to bytes
        bytes memory sealBytes = vm.parseBytes(sealHex);
        bytes memory journalBytes = vm.parseBytes(journalHex);
        
        console.log("Seal bytes length:", sealBytes.length);
        console.log("Journal bytes length:", journalBytes.length);
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("Executing on-chain verification...");
        
        // Calculate journal digest (hash of the journal)
        bytes32 journalDigest = keccak256(journalBytes);
        console.log("Journal digest:", vm.toString(journalDigest));
        
        // Execute the verification using our custom verifier
        try verifier.verify(sealBytes, verifier.IMAGE_ID(), journalDigest) {
            console.log("=== VERIFICATION RESULT ===");
            console.log("PROOF VERIFIED ON-CHAIN WITH OUR VERIFIER!");
            console.log("Your Groth16 zkVM proof is cryptographically valid!");
            console.log("Proof size:", sealBytes.length, "bytes");
            console.log("Journal size:", journalBytes.length, "bytes");
        } catch Error(string memory reason) {
            console.log("=== VERIFICATION FAILED ===");
            console.log("Error:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("=== VERIFICATION FAILED ===");
            console.log("Verification failed with low-level error");
            console.log("Error data length:", lowLevelData.length);
            if (lowLevelData.length > 0) {
                console.log("Error data (first 32 bytes):", vm.toString(lowLevelData));
            }
        }
        
        vm.stopBroadcast();
    }
}
