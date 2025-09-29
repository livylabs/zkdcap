# TDX Attestation Verification on Base Sepolia

Production-ready Intel TDX attestation verification using RISC Zero zkVM on Base Sepolia.

## 🎯 Overview

Cryptographically verify Intel TDX hardware attestations on-chain:
- **TDX Hardware** → **RISC Zero Proof** → **Base Sepolia Verification**

## 🚀 Quick Start

```bash
# Setup
make setup
cp .env.example .env  # Add your PRIVATE_KEY

# Build
make build

# Deploy
make deploy

# Submit TDX proof
make submit-proof
```

## 📁 Structure

- `src/TdxProofVerifier.sol` - Main verification contract
- `script/Deploy.s.sol` - Deployment script  
- `script/SubmitProof.s.sol` - Proof submission
- `crates/` - TDX verification logic
- `zkvm/risc0/` - RISC Zero guest program
- `submit_proof.js` - JavaScript submission

## 🔧 Commands

- `make deploy` - Deploy contract with verification
- `make submit-proof` - Submit TDX proof (Solidity)
- `make submit-proof-js` - Submit TDX proof (JavaScript)
- `make build` - Build contracts
- `make test` - Run tests

## 🏗️ Architecture

Uses official RISC Zero infrastructure:
- **Router**: `0x0b144E07A0826182B6b59788c34b32Bfa86Fb711`
- **Verifier**: RiscZeroGroth16Verifier v3.0.0
- **Network**: Base Sepolia (Chain ID: 84532)

## ✅ What's Verified

- Intel TDX hardware authenticity
- Cryptographic proof integrity  
- Permanent on-chain storage
- Full audit trail

## 📚 Resources

- [Intel TDX](https://www.intel.com/content/www/us/en/developer/tools/trust-domain-extensions/overview.html)
- [RISC Zero](https://dev.risczero.com/)
- [Base Network](https://docs.base.org/)

Production ready for Base Sepolia and Base Mainnet.
