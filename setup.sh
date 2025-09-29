#!/bin/bash

echo "🔧 Setting up TDX Proof Verifier for Base Sepolia..."

# Check if .env exists
if [ ! -f .env ]; then
    echo "📝 Creating .env file..."
    cp .env.example .env
    echo "⚠️  Please edit .env with your actual private key and API key!"
    echo "   - Get Base Sepolia ETH from: https://bridge.base.org/deposit"
    echo "   - Get Basescan API key from: https://basescan.org/apis"
else
    echo "✅ .env file already exists"
fi

# Source the .env file
if [ -f .env ]; then
    echo "📖 Loading environment variables..."
    set -a
    source .env
    set +a
fi

echo "🏗️  Building contracts..."
forge build

echo "✅ Setup complete!"
echo ""
echo "🚀 Next steps:"
echo "1. Edit .env with your private key and Basescan API key"
echo "2. Deploy: forge script script/Deploy.s.sol --rpc-url base_sepolia --broadcast --verify"
echo "3. Submit proof: forge script script/SubmitProof.s.sol --rpc-url base_sepolia --broadcast"

