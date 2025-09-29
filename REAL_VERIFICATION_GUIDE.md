# Real TDX Attestation Verification Guide

This guide shows you how to verify TDX attestations using the real RISC Zero verifier on Base Sepolia (no mocks).

## 🎯 What This Actually Verifies

Your setup proves:
1. **TDX Hardware Attestation**: Intel TDX hardware generated a valid quote
2. **RISC Zero Proof**: The TDX verification was executed in a RISC Zero zkVM
3. **On-Chain Verification**: The proof is cryptographically verified on Base Sepolia

## 📋 Prerequisites

1. **Environment Setup**:
   ```bash
   cp .env.example .env
   # Add your PRIVATE_KEY and RPC_URL
   ```

2. **Required Files**:
   - `tdx_proof_journal.bin` - Your TDX verification result
   - `tdx_proof_seal.hex` - Your RISC Zero proof seal

## 🚀 Step-by-Step Verification

### 1. Deploy with Real RISC Zero Router

```bash
make deploy
```

This deploys your `TdxProofVerifier` using the official RISC Zero router on Base Sepolia:
- **Router Address**: `0x0b144e07a0826182b6b59788c34b32bfa86fb711`
- **Supports Multiple Verifiers**: Groth16 v3.0.0, v2.2.0, SetVerifier v0.9.0, etc.
- **Automatic Routing**: Routes based on your seal's selector (first 4 bytes)

### 2. Submit Your Real Proof

**Option A: Solidity Script**
```bash
make submit-proof
```

**Option B: JavaScript**
```bash
make submit-proof-js
```

## 🔍 Understanding Your Proof Data

### Seal Structure
Your `tdx_proof_seal.hex` contains:
```
[4 bytes selector][proof data]
```

**Supported Selectors on Base Sepolia**:
- `0x73c457ba` - RiscZeroGroth16Verifier v3.0.0 (latest)
- `0xbb001d44` - RiscZeroGroth16Verifier v2.2.0
- `0x242f9d5b` - RiscZeroSetVerifier v0.9.0
- `0x0f63ffd5` - RiscZeroSetVerifier v0.7.0

### Journal Structure
Your `tdx_proof_journal.bin` contains the TDX verification result with:
- TDX quote verification status
- TEE type (should be `0x81` for TDX)
- Verification status (should be `4` for valid)
- Advisory IDs and other attestation data

## 🛠️ Troubleshooting Common Issues

### "IsActivated" Error
This typically means:
1. **Wrong Verifier Version**: Your seal selector doesn't match an active verifier
2. **Verifier Not Deployed**: The specific verifier version isn't available on Base Sepolia
3. **Router Issue**: The router can't route to the correct verifier

**Solution**: Check your seal selector and ensure it matches a supported verifier.

### "SelectorMismatch" Error
- Your proof was generated with a different RISC Zero version
- Regenerate your proof with a supported version

### "VerificationFailed" Error
- The cryptographic proof is invalid
- Journal digest doesn't match the proof
- Image ID mismatch

## 📊 Verification Success

When successful, you'll see:
```
🎉 SUCCESS! TDX quote verification passed!
✅ COMPLETE SUCCESS! TDX proof verification working end-to-end!
Your TDX attestation has been successfully verified on Base Sepolia!
```

The contract stores:
- **Journal Hash**: `keccak256(journal)`
- **Verification Time**: Block timestamp
- **Submitter**: Your address
- **Validity**: `true`

## 🔗 Contract Addresses

**Base Sepolia**:
- **RISC Zero Router**: `0x0b144e07a0826182b6b59788c34b32bfa86fb711`
- **Your TdxProofVerifier**: Set `VERIFIER_ADDRESS` in `.env` after deployment

## 🧪 Testing vs Production

**This is Real Verification**:
- ✅ Uses official RISC Zero contracts
- ✅ Cryptographically verifies your proof
- ✅ Actually validates TDX attestation data
- ✅ Stores verification on Base Sepolia blockchain

**Not a Mock**:
- ❌ No shortcuts or bypasses
- ❌ No fake verification
- ❌ Full cryptographic validation required

## 📈 Next Steps

1. **Mainnet Deployment**: Use Base mainnet addresses from `deployment.toml`
2. **Integration**: Build your dApp on top of verified attestations
3. **Monitoring**: Watch for `TdxQuoteVerified` events
4. **Scaling**: Consider batch verification for multiple attestations

## 🔧 Advanced Usage

### Custom Image ID
Update `TDX_VERIFIER_IMAGE_ID` in your contract to match your guest program:
```solidity
bytes32 public constant TDX_VERIFIER_IMAGE_ID = 0x[your_image_id];
```

### Parsing TDX Data
The contract includes `parseTdxOutput()` to extract:
- TDX version
- Quote version  
- TEE type
- Verification status

### Event Monitoring
Listen for verification events:
```solidity
event TdxQuoteVerified(
    bytes32 indexed imageId,
    bytes32 indexed journalHash, 
    address indexed submitter,
    uint256 timestamp
);
```

## 🆘 Support

If verification fails:
1. Check your proof generation process
2. Verify file integrity (`tdx_proof_journal.bin`, `tdx_proof_seal.hex`)
3. Ensure correct RISC Zero version compatibility
4. Review Base Sepolia verifier deployment status

Your TDX attestation verification is now running on real RISC Zero infrastructure! 🎉
