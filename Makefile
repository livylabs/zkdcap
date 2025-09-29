# Load environment variables
include .env
export

.PHONY: build deploy verify submit-proof clean

# Build contracts
build:
	forge build

# Deploy to Base Sepolia with real RISC Zero verifier
deploy:
	@echo "🚀 Deploying TDX Proof Verifier with real RISC Zero router to Base Sepolia..."
	forge script script/Deploy.s.sol --rpc-url base_sepolia --broadcast --verify

# Deploy without verification (faster)
deploy-fast:
	@echo "⚡ Fast deploying to Base Sepolia..."
	forge script script/Deploy.s.sol --rpc-url base_sepolia --broadcast

# Submit TDX proof (requires VERIFIER_ADDRESS in .env)
submit-proof:
	@echo "📝 Submitting TDX proof..."
	forge script script/SubmitProof.s.sol --rpc-url base_sepolia --broadcast

# Submit proof via JavaScript
submit-proof-js:
	@echo "📝 Submitting TDX proof via JavaScript..."
	node submit_proof.js

# Verify contract after deployment
verify-contract:
	@echo "✅ Verifying contract..."
	forge verify-contract $(VERIFIER_ADDRESS) src/TdxProofVerifier.sol:TdxProofVerifier --chain base-sepolia

# Test contracts
test:
	forge test -vvv

# Clean build artifacts
clean:
	forge clean

# Setup project
setup:
	./setup.sh

# Check deployment status
status:
	@echo "📊 Deployment Status:"
	@echo "Private Key: $(shell echo $(PRIVATE_KEY) | sed 's/./*/g')"
	@echo "Verifier Address: $(VERIFIER_ADDRESS)"
	@echo "Image ID: 0xe5056aa7a8064abeb648b31d5efa8697a79d416b937cb917d1428cec91a56c67"

help:
	@echo "Available commands:"
	@echo "  make setup         - Initial project setup"
	@echo "  make build         - Build contracts"
	@echo "  make deploy        - Deploy to Base Sepolia with real RISC Zero router"
	@echo "  make deploy-fast   - Deploy without verification"
	@echo "  make submit-proof  - Submit your TDX proof (Solidity)"
	@echo "  make submit-proof-js - Submit your TDX proof (JavaScript)"
	@echo "  make test          - Run tests"
	@echo "  make clean         - Clean build artifacts"
	@echo "  make status        - Show deployment status"
