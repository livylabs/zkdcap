#!/bin/bash

echo "🚀 Verifying zkVM proof on Sepolia..."

# Check if PRIVATE_KEY is set
if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ Error: PRIVATE_KEY environment variable is not set"
    echo "Please set it with: export PRIVATE_KEY=your_private_key_here"
    exit 1
fi

# Run the verification script with higher gas limit
forge script script/VerifyProof.s.sol --rpc-url sepolia --broadcast --gas-limit 100000

echo "✅ Verification script completed!"
echo "📋 Check the transaction on Etherscan:"
echo "   https://sepolia.etherscan.io/address/0x4fa3ddCB722a7aA95f6409125dC60cC9CA5A4D16"
