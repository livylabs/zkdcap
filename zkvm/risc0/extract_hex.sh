#!/bin/bash

echo "Extracting proof data from binary files..."

# Extract the journal (public output) as hex
echo "Journal (public output):"
journal_hex=$(xxd -p -c 0 quote_verification_result.bin)
echo "0x$journal_hex"
echo ""

# Extract the proof (seal) as hex
echo "Proof (seal):"
proof_hex=$(xxd -p -c 0 quote_verification_proof.bin)
echo "0x$proof_hex"
echo ""

# Save to files for easy copying
echo "0x$journal_hex" > journal_hex.txt
echo "0x$proof_hex" > proof_hex.txt

echo "✅ Hex data saved to:"
echo "   - journal_hex.txt (public output)"
echo "   - proof_hex.txt (zkVM proof)"
echo ""

# Create the cast command
contract_address="0x4fa3ddCB722a7aA95f6409125dC60cC9CA5A4D16"
echo "🚀 To verify on-chain, run:"
echo "cast send $contract_address \"verifyQuote(bytes,bytes)\" \\"
echo "    \"0x$proof_hex\" \\"
echo "    \"0x$journal_hex\" \\"
echo "    --private-key \$PRIVATE_KEY \\"
echo "    --rpc-url sepolia"
