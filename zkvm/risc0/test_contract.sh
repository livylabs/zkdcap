#!/bin/bash
echo "Testing contract functions..."

# Test getImageId
echo "Image ID:"
cast call 0x4fa3ddCB722a7aA95f6409125dC60cC9CA5A4D16 "getImageId()" --rpc-url sepolia

# Test with mock data first
echo "Testing with mock data..."
cast send 0x4fa3ddCB722a7aA95f6409125dC60cC9CA5A4D16 "verifyQuote(bytes,bytes)" \
"0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef" \
"0xdeadbeefcafebabe1234567890abcdef1234567890abcdef1234567890abcdef" \
--private-key $PRIVATE_KEY \
--rpc-url sepolia

echo "Mock test completed!"