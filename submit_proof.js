const { ethers } = require("ethers");
const fs = require("fs");

async function main() {
  console.log("🚀 Submitting real TDX proof to RISC Zero verifier on Base Sepolia");
  console.log("");
  
  // Load the proof data
  const journal = fs.readFileSync("tdx_proof_journal.bin");
  const sealHex = fs.readFileSync("tdx_proof_seal.hex", "utf8").trim();
  
  console.log("📄 Journal size:", journal.length, "bytes");
  console.log("🔐 Seal hex length:", sealHex.length, "characters");
  
  // Convert hex string to bytes
  const seal = "0x" + sealHex;
  const sealBytes = ethers.getBytes(seal);
  console.log("🔐 Seal size:", sealBytes.length, "bytes");
  
  // Extract selector (first 4 bytes)
  const selector = ethers.hexlify(sealBytes.slice(0, 4));
  console.log("🎯 Seal selector:", selector);
  
  // Identify verifier version
  const verifierVersions = {
    "0x73c457ba": "RiscZeroGroth16Verifier v3.0.0",
    "0xbb001d44": "RiscZeroGroth16Verifier v2.2.0", 
    "0x242f9d5b": "RiscZeroSetVerifier v0.9.0",
    "0x0f63ffd5": "RiscZeroSetVerifier v0.7.0"
  };
  
  const verifierVersion = verifierVersions[selector];
  if (verifierVersion) {
    console.log("✅ Using:", verifierVersion);
  } else {
    console.log("⚠️  Unknown selector - may not be routable");
  }
  
  // Setup provider and wallet
  const provider = new ethers.JsonRpcProvider("https://sepolia.base.org");
  const privateKey = process.env.PRIVATE_KEY || "0xb645cabab307a768adf0139751efaa45d515137c7b60d26f9792f25e1b145c29";
  const wallet = new ethers.Wallet(privateKey, provider);
  
  // Connect to your deployed contract
  const contractAddress = process.env.VERIFIER_ADDRESS || "0xCba5443423FB70c2722853e77BE232d0c8c7B0B1";
  console.log("📋 Contract address:", contractAddress);
  
  // Contract ABI (minimal)
  const abi = [
    "function verifyTdxQuote(bytes calldata journal, bytes calldata seal) external",
    "function isQuoteVerified(bytes32 journalHash) external view returns (bool)",
    "function getVerificationDetails(bytes32 journalHash) external view returns (tuple(bytes32 journalHash, uint256 verificationTime, address submitter, bool isValid))",
    "function parseTdxOutput(bytes calldata journal) external pure returns (uint8 version, uint8 quoteVersion, uint8 teeType, uint8 status)",
    "function TDX_VERIFIER_IMAGE_ID() external view returns (bytes32)",
    "event TdxQuoteVerified(bytes32 indexed imageId, bytes32 indexed journalHash, address indexed submitter, uint256 timestamp)"
  ];
  
  const verifier = new ethers.Contract(contractAddress, abi, wallet);
  
  // Get contract info
  const imageId = await verifier.TDX_VERIFIER_IMAGE_ID();
  
  console.log("🏗️  Image ID:", imageId);
  console.log("");
  
  console.log("🔄 Submitting TDX proof verification...");
  
  try {
    // Estimate gas first
    const gasEstimate = await verifier.verifyTdxQuote.estimateGas(journal, seal);
    console.log("⛽ Estimated gas:", gasEstimate.toString());
    
    const tx = await verifier.verifyTdxQuote(journal, seal, {
      gasLimit: gasEstimate * 120n / 100n // Add 20% buffer
    });
    
    console.log("📤 Transaction submitted:", tx.hash);
    console.log("⏳ Waiting for confirmation...");
    
    const receipt = await tx.wait();
    console.log("✅ Transaction confirmed in block:", receipt.blockNumber);
    console.log("⛽ Gas used:", receipt.gasUsed.toString());
    
    // Check verification status
    const journalHash = ethers.keccak256(journal);
    const isVerified = await verifier.isQuoteVerified(journalHash);
    console.log("🎯 Quote verified:", isVerified);
    
    if (isVerified) {
      console.log("🎉 SUCCESS! TDX attestation verified on-chain!");
      
      const details = await verifier.getVerificationDetails(journalHash);
      console.log("📊 Verification details:");
      console.log("  - Journal hash:", details.journalHash);
      console.log("  - Verification time:", new Date(Number(details.verificationTime) * 1000).toISOString());
      console.log("  - Submitter:", details.submitter);
      console.log("  - Valid:", details.isValid);
      
      // Parse TDX output
      try {
        const tdxOutput = await verifier.parseTdxOutput(journal);
        console.log("📋 TDX attestation data:");
        console.log("  - Version:", tdxOutput[0]);
        console.log("  - Quote Version:", tdxOutput[1]);
        console.log("  - TEE Type:", tdxOutput[2], tdxOutput[2] === 0x81 ? "(TDX)" : "(Unknown)");
        console.log("  - Status:", tdxOutput[3], tdxOutput[3] === 4 ? "(Valid)" : "(Invalid)");
        
        if (tdxOutput[2] === 0x81 && tdxOutput[3] === 4) {
          console.log("🎯 TDX attestation data is valid!");
        }
      } catch (parseError) {
        console.log("⚠️  Could not parse TDX output:", parseError.message);
      }
    }
    
    // Look for events
    const filter = verifier.filters.TdxQuoteVerified();
    const events = await verifier.queryFilter(filter, receipt.blockNumber, receipt.blockNumber);
    
    if (events.length > 0) {
      console.log("📢 Events emitted:");
      events.forEach((event, i) => {
        console.log(`  Event ${i + 1}:`);
        console.log(`    - Image ID: ${event.args.imageId}`);
        console.log(`    - Journal Hash: ${event.args.journalHash}`);
        console.log(`    - Submitter: ${event.args.submitter}`);
        console.log(`    - Timestamp: ${event.args.timestamp}`);
      });
    }
    
  } catch (error) {
    console.error("❌ Verification failed:", error.message);
    
    // Try to decode the error
    if (error.data) {
      console.log("🔍 Error data:", error.data);
      
      // Common error signatures
      const errorSignatures = {
        "0x8baa579f": "SelectorMismatch - seal selector doesn't match verifier",
        "0x09bde339": "VerificationFailed - cryptographic proof verification failed"
      };
      
      const errorSig = error.data.slice(0, 10);
      const errorDesc = errorSignatures[errorSig];
      if (errorDesc) {
        console.log("🎯 Error type:", errorDesc);
      }
    }
    
    console.log("");
    console.log("🔧 Troubleshooting tips:");
    console.log("1. Verify your proof was generated with the correct RISC Zero version");
    console.log("2. Check that the image ID matches your guest program");
    console.log("3. Ensure the journal file is the correct binary output");
    console.log("4. Confirm the verifier contract is properly deployed and activated");
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("💥 Script failed:", error);
    process.exit(1);
  });
