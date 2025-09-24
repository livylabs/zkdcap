#!/bin/bash

# Script to extract Groth16 proof from binary receipt and verify on-chain
# This script runs the complete process from binary receipt to on-chain verification

set -e  # Exit on any error

echo "=== GROTH16 PROOF EXTRACTION AND VERIFICATION ==="
echo "This script will:"
echo "1. Extract proof data from groth16_receipt.bin"
echo "2. Verify the proof on-chain using RISC Zero's standard verifier"
echo ""

# Check if the binary receipt exists
if [ ! -f "groth16_receipt.bin" ]; then
    echo "❌ Error: groth16_receipt.bin not found!"
    echo "Please run generate_true_groth16_proof.rs first to generate the receipt."
    exit 1
fi

echo "✅ Found groth16_receipt.bin"

# Step 1: Extract proof data from binary receipt
echo ""
echo "=== STEP 1: EXTRACTING PROOF DATA FROM BINARY RECEIPT ==="
cargo run --bin extract_from_bin

if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to extract proof data from binary receipt"
    exit 1
fi

echo "✅ Proof data extracted successfully"

# Check if extraction files were created
if [ ! -f "extracted_seal_hex.txt" ] || [ ! -f "extracted_journal_hex.txt" ] || [ ! -f "extracted_journal_digest.txt" ]; then
    echo "❌ Error: Extraction files not created properly"
    exit 1
fi

echo "✅ Extraction files created:"
echo "   - extracted_seal_hex.txt"
echo "   - extracted_journal_hex.txt" 
echo "   - extracted_journal_digest.txt"

# Step 2: Verify the proof on-chain
echo ""
echo "=== STEP 2: VERIFYING PROOF ON-CHAIN ==="
echo "Using RISC Zero's standard Groth16 verifier on Sepolia..."

# Change to verifier directory
cd verifier

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found in verifier directory"
    echo "Please create .env file with your PRIVATE_KEY"
    exit 1
fi

# Run the verification script
forge script script/VerifyGroth16FromBin.s.sol --rpc-url sepolia --broadcast --verify

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 SUCCESS! Groth16 proof verification completed!"
    echo "The proof from your binary receipt has been verified on-chain."
else
    echo ""
    echo "❌ Verification failed. Check the output above for details."
    echo "Common issues:"
    echo "- Incorrect journal digest calculation"
    echo "- Mismatched image ID"
    echo "- Invalid seal format"
    echo "- Network issues"
fi

# Return to original directory
cd ..

echo ""
echo "=== PROCESS COMPLETE ==="
echo "Files created:"
echo "   - extracted_seal_hex.txt: Groth16 proof seal"
echo "   - extracted_journal_hex.txt: Journal data"
echo "   - extracted_journal_digest.txt: Journal digest for verification"
echo ""
echo "To manually verify again, run:"
echo "   cd verifier && forge script script/VerifyGroth16FromBin.s.sol --rpc-url sepolia"
