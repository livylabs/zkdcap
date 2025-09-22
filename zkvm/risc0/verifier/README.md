# QuoteVerifier - zkVM Proof Verification on Sepolia

This Foundry project contains a Solidity contract for verifying zkVM proofs of DCAP quote verification on the Sepolia testnet.

## Setup

1. **Install dependencies**:
   ```bash
   forge install
   ```

2. **Set up environment variables**:
   Create a `.env` file with:
   ```
   PRIVATE_KEY=your_private_key_here
   INFURA_API_KEY=your_infura_api_key_here
   ETHERSCAN_API_KEY=your_etherscan_api_key_here
   ```

3. **Get Sepolia ETH**:
   - Use a faucet like https://sepoliafaucet.com/
   - Or https://faucet.sepolia.dev/

## Build and Test

```bash
# Build the project
forge build

# Run tests
forge test

# Run tests with gas reporting
forge test --gas-report

# Run specific test
forge test --match-test testVerifyQuote
```

## Deploy to Sepolia

```bash
# Deploy to Sepolia
forge script script/DeployVerifier.s.sol --rpc-url sepolia --broadcast --verify

# Deploy without verification
forge script script/DeployVerifier.s.sol --rpc-url sepolia --broadcast
```

## Contract Functions

### `verifyQuote(bytes seal, bytes journal)`
- Verifies a zkVM proof for DCAP quote verification
- Returns `bool success`

### `verifyQuoteWithData(bytes quoteData, bytes collateralData, uint256 timestamp)`
- Verifies quote with specific data parameters
- Returns `bool success`

### `getImageId()`
- Returns the RISC Zero image ID for this verifier

## Testing the Contract

After deployment, you can test the contract by calling:

```solidity
// Example test call
bool success = verifier.verifyQuote(mockSeal, mockJournal);
```

## Integration with zkVM

To use this with your zkVM proof:

1. Generate the proof using your `lightweight_host.rs`
2. Extract the `seal` and `journal` from the receipt
3. Call `verifyQuote(seal, journal)` on the deployed contract

## Gas Costs

- Deployment: ~500,000 gas
- `verifyQuote`: ~50,000 gas (mock implementation)
- `verifyQuoteWithData`: ~60,000 gas (mock implementation)

## Next Steps

1. Replace the mock verification with actual RISC Zero verifier integration
2. Add more sophisticated validation logic
3. Implement proper error handling and events
4. Add access control if needed