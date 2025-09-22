// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/QuoteVerifier.sol";

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
        
        // Deployed contract address
        address verifierAddress = 0xC11722a1c9bEa2e53e3BbdD4EaeF89c9e035c255;
        QuoteVerifier verifier = QuoteVerifier(verifierAddress);
        
        console.log("Contract:", verifierAddress);
        console.log("Image ID:", vm.toString(verifier.getImageId()));
        console.log("RISC Zero Verifier:", verifier.getRiscZeroVerifier());
        
        // Read the hex data from files
        console.log("Reading proof data...");
        
        // Read compressed seal data
        string memory sealHex = vm.readFile("data/seal_compressed_hex.txt");
        console.log("Compressed seal data length:", bytes(sealHex).length);
        
        // Read compressed journal data  
        string memory journalHex = vm.readFile("data/journal_compressed_hex.txt");
        console.log("Compressed journal data length:", bytes(journalHex).length);
        
        // Convert hex strings to bytes
        bytes memory sealBytes = vm.parseBytes(sealHex);
        bytes memory journalBytes = vm.parseBytes(journalHex);
        
        console.log("Seal bytes length:", sealBytes.length);
        console.log("Journal bytes length:", journalBytes.length);
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("Executing on-chain verification...");
        
        // Execute the verification
        bool success = verifier.verifyQuote(sealBytes, journalBytes);
        
        vm.stopBroadcast();
        
        console.log("=== VERIFICATION RESULT ===");
        console.log("Success:", success);
        
        if (success) {
            console.log("PROOF VERIFIED ON-CHAIN!");
            console.log("Your zkVM proof is cryptographically valid!");
        } else {
            console.log("Verification failed");
        }
    }
}
