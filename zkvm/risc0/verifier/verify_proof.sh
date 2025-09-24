#!/bin/bash

echo "=== VERIFYING GROTH16 PROOF ON SEPOLIA ==="
echo "Contract: 0x2a098988600d87650Fb061FfAff08B97149Fa84D"
echo "Image ID: 0xc700937f6407fbb924f499ade8d9b40769b25f2af00e6d82aa019deaa504273a"
echo ""

# Check if proof files exist
if [ ! -f "../groth16_seal_hex.txt" ]; then
    echo "❌ Error: groth16_seal_hex.txt not found"
    exit 1
fi

if [ ! -f "../groth16_journal_hex.txt" ]; then
    echo "❌ Error: groth16_journal_hex.txt not found"
    exit 1
fi

echo "✅ Proof files found:"
echo "   - groth16_seal_hex.txt: $(wc -c < ../groth16_seal_hex.txt) bytes"
echo "   - groth16_journal_hex.txt: $(wc -c < ../groth16_journal_hex.txt) bytes"
echo ""

# Run the verification script
echo "Running verification script..."
forge script script/VerifyGroth16Proof.s.sol --rpc-url sepolia --broadcast --verify
